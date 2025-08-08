function state = RealTimeAnalysis(action, state, data, handles, config, varargin)
%   RealTimeAnalysis function to process and plot trial data for BControl.
%   This function is called repeatedly from a parent script
%   (e.g., Psychometric.m) and is made stateless by passing all required
%   information in and out on every call. It uses a try/catch block to
%   prevent crashes during live experiments.
%
%   Args:
%       action (char): The operation to perform. Can be:
%           'live': Standard update after a block of trials.
%           'redraw': Redraws live plots, typically when a figure becomes visible.
%           'context_switch': Special handling for leftover trials when a context changes.
%           'custom': Plots a single, user-defined range of trials and adds a row to the table.
%           'context': Plots multiple, user-defined ranges for comparison and adds rows to the table.
%           'evaluate': Computes key performance metrics for given trial ranges without plotting.
%
%       state (struct): Contains variables that are modified and passed back.
%           .blockStatsHistory (struct array): Stores analysis results for each block.
%           .block_count (double): Counter for the number of blocks analyzed.
%           .last_analyzed_valid_trial (double): Counter for the last valid trial included in an analysis.
%           .context_blocks (double): array to keep track of the blocks when the context was switched
%           .table_row_editable (double): array same size as the number of rows in table decides which row the user can
%                                         edit. Its a sanity check so that user doesn't select custom or context rows
%           
%       
%       data (struct): Contains the complete, read-only data histories for the session.
%           .hit_history (vector): History of hits (1), misses (0), or NaN.
%           .previous_sides (vector): History of sides presented (e.g., 0 for left, 1 for right).
%           .stim_history (vector): History of stimulus values.
%           .full_rule_history (string): psychometric rule.
%           .full_dist_right, .full_dist_left: Histories of stimulus distributions.
%
%       handles (struct): Contains handles to all necessary GUI components.
%           .main_fig (handle): Handle to the main analysis figure.
%           .axes_h (struct): A struct containing handles to the 6 plot axes.
%           .ui_table (handle): Handle to the results table.
%
%       config (struct): Contains session-wide constants.
%           .trials_per_block (double): Number of valid trials needed for a live update.
%           .true_mu (double): The true boundary of the stimulus categories.
%           .stimuli_range (1x2 vector): The [min, max] of possible stimulus values.
%           .debug (logical): If true, errors will be rethrown; if false, they will be caught and displayed as warnings.
%
%       varargin: Action-specific arguments based on the 'action' string.
%           For 'live', 'redraw', 'context_switch':
%               varargin{1} (struct): A flags struct with logical values.
%                   .psych (logical): Toggles the psychometric plot.
%                   .hit (logical): Toggles the hit rate plot.
%                   .stim (logical): Toggles the stimulus histogram.
%           For 'custom':
%               varargin{1} (struct): The flags struct (as above).
%               varargin{2} (double): The start trial for the custom range.
%               varargin{3} (double): The end trial for the custom range.
%           For 'context':
%               varargin{1} (struct): The flags struct (as above).
%               varargin{2} (cell): A cell array of trial ranges, e.g., {[s1,e1], [s2,e2]}.
%               varargin{3} (cell): A cell array of context names, e.g., {'Hard A', 'Uniform', 'Hard B'}.
%           For 'evaluate':
%               varargin{1} (cell): A cell array of trial ranges, e.g., {[s1,e1], [s2,e2]}.
%
%   Returns:
%       state (struct): For most actions, this is the updated state struct.
%                       For 'evaluate', this is a struct array with performance metrics:
%                           .start_trial
%                           .end_trial
%                           .distribution_type
%                           .calculated_boundary
%                           .total_hit_percent
%                           .total_violations_percent
%                           .right_correct_percent
%                           .left_correct_percent

% Ensure that the core data vectors are of the same length to prevent indexing errors.
% This can happen if the session is interrupted mid-trial.
    try
        len_hit = numel(data.hit_history);
        len_sides = numel(data.previous_sides);
        len_stim = numel(data.stim_history);
        
        min_len = min([len_hit, len_sides, len_stim]);
        
        if len_hit > min_len || len_sides > min_len || len_stim > min_len
            warning('RealTimeAnalysis:DataMismatch', ...
                'Data history vectors have mismatched lengths. Truncating to the shortest length (%d).', min_len);
            
            data.hit_history = data.hit_history(1:min_len);
            data.previous_sides = data.previous_sides(1:min_len);
            data.stim_history = data.stim_history(1:min_len);
        end
    catch ME
        warning('RealTimeAnalysis:DataIntegrityError', 'Could not perform data integrity check: %s', ME.message);
    end
    % --- End of Data Integrity Check ---


    try
        switch lower(action)
            % =================================================================
            %                   LIVE UPDATE ACTION
            % =================================================================
            case 'live'
                if numel(varargin) < 1, error('Live action requires a flags struct.'); end
                flags = varargin{1};
                
                lastAnalyzed = state.last_analyzed_valid_trial;
                validTrials = sum(~isnan(data.hit_history));

                if (validTrials - lastAnalyzed) >= config.trials_per_block
                    valid_indices = find(~isnan(data.hit_history));
                    buffer_indices = valid_indices(end - config.trials_per_block + 1 : end);
                    
                    dataBuffer.stim = data.stim_history(buffer_indices);
                    dataBuffer.hit  = data.hit_history(buffer_indices);
                    dataBuffer.side = data.previous_sides(buffer_indices);
                    dataBuffer.indices = buffer_indices;
                    
                    state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags);
                end

            % =================================================================
            %                   CONTEXT SWITCH ACTION
            % =================================================================
            case 'context_switch'
                if numel(varargin) < 1, error('context_switch action requires a flags struct.'); end
                flags = varargin{1};

                merge_threshold = round(2 * config.trials_per_block / 3);

                lastAnalyzed = state.last_analyzed_valid_trial;
                validTrials = sum(~isnan(data.hit_history));
                remaining_valid_trials = validTrials - lastAnalyzed;
                state.context_blocks(end + 1) = state.block_count;

                if remaining_valid_trials > 0
                    valid_indices = find(~isnan(data.hit_history));
                    new_valid_indices = valid_indices(lastAnalyzed + 1 : end);

                    if remaining_valid_trials < merge_threshold && state.block_count > 0
                        last_block_indices = state.blockStatsHistory(end).indices;
                        combined_indices = [last_block_indices, new_valid_indices'];

                        dataBuffer.stim = data.stim_history(combined_indices);
                        dataBuffer.hit  = data.hit_history(combined_indices);
                        dataBuffer.side = data.previous_sides(combined_indices);
                        dataBuffer.indices = combined_indices;

                        state = reAnalyzeLastChunk(state, data, handles, config, dataBuffer, flags);
                    
                    elseif remaining_valid_trials >= merge_threshold
                        dataBuffer.stim = data.stim_history(new_valid_indices);
                        dataBuffer.hit  = data.hit_history(new_valid_indices);
                        dataBuffer.side = data.previous_sides(new_valid_indices);
                        dataBuffer.indices = new_valid_indices;
                        
                        state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags);
                    end
                end

            % =================================================================
            %                   REDRAW ACTION
            % =================================================================
            case 'redraw'
                if numel(varargin) < 1, error('Redraw action requires a flags struct.'); end
                flags = varargin{1};
                
                updateLivePlots(state, data, handles, config, flags);
                
            % =================================================================
            %                   CUSTOM PLOT ACTION
            % =================================================================
            case 'custom'
                if numel(varargin) < 3, error('Custom action requires flags, start_trial, and end_trial.'); end
                flags = varargin{1};
                start_idx = varargin{2};
                end_idx = varargin{3};

                if start_idx >= end_idx || start_idx < 1 || end_idx > numel(data.hit_history), warning('Invalid trial range for custom plot.'); return; end
                
                indices = start_idx:end_idx;
                hit_chunk = data.hit_history(indices);
                valid_mask = ~isnan(hit_chunk);
                if sum(valid_mask) < 10, warning('Not enough valid trials in custom range to plot.'); return; end
                
                stim_fit = data.stim_history(indices(valid_mask));
                side_fit = data.previous_sides(indices(valid_mask));
                hit_fit = hit_chunk(valid_mask);
                
                current_rule = data.full_rule_history;
                
                % Add results to table, but don't select for live plotting
                [~, newRow] = processBlock(data, config, struct('stim', stim_fit, 'hit', hit_fit, 'side', side_fit, 'indices', indices));
                newRow{1} = false; % Ensure it's not selected
                updateTable(handles, newRow);
                state.table_row_editable(end+1) = false;

                if flags.psych, plotCustomPsychometric(handles.axes_h.custom_psych, stim_fit, side_fit, hit_fit, config, current_rule); end
                if flags.hit, plotCustomHitRates(handles.axes_h.custom_hitrate, hit_fit, side_fit, [start_idx, end_idx], state.blockStatsHistory); end
                if flags.stim, plotCustomStimulusHistogram(handles.axes_h.custom_stim, stim_fit, hit_fit, [start_idx, end_idx], state.blockStatsHistory, config); end
            
            % =================================================================
            %                   CONTEXT PLOT ACTION
            % =================================================================
            case 'context'
                if numel(varargin) < 2, error('Context action requires flags and a cell array of contexts.'); end
                flags = varargin{1};
                contexts = varargin{2};
                contexts_names = varargin{3};

                if ~iscell(contexts) || isempty(contexts), error('Contexts must be a non-empty cell array of [start, end] pairs.'); end
                
                num_contexts = numel(contexts);
                context_colors = createTemporalColormap(num_contexts);
                
                psych_data = cell(1, num_contexts);
                hit_rate_data = zeros(num_contexts, 3);
                hit_rate_std = zeros(num_contexts, 3);
                stim_hist_data = cell(1, num_contexts);

                for i = 1:num_contexts
                    start_idx = contexts{i}(1);
                    end_idx = contexts{i}(2);

                    if start_idx >= end_idx || start_idx < 1 || end_idx > numel(data.hit_history), continue; end
                    
                    indices = start_idx:end_idx;
                    hit_chunk = data.hit_history(indices);
                    valid_mask = ~isnan(hit_chunk);
                    if sum(valid_mask) < 10, continue; end
                    
                    stim_fit = data.stim_history(indices(valid_mask));
                    side_fit = data.previous_sides(indices(valid_mask));
                    hit_fit = hit_chunk(valid_mask);
                    
                    current_rule = data.full_rule_history;
                    
                    % Add results to table, but don't select for live plotting
                    [~, newRow] = processBlock(data, config, struct('stim', stim_fit, 'hit', hit_fit, 'side', side_fit, 'indices', indices));
                    newRow{1} = false; % Ensure it's not selected
                    updateTable(handles, newRow);
                    state.table_row_editable(end+1) = false;

                    physical_response = zeros(size(hit_fit));
                    physical_response(hit_fit == 1) = side_fit(hit_fit == 1);
                    physical_response(hit_fit == 0) = 1 - side_fit(hit_fit == 0);
                    
                    response_for_fitting = physical_response;
                    if contains(string(current_rule), 'Left', 'IgnoreCase', true), response_for_fitting = 1 - response_for_fitting; end
                    
                    options.MinTrials = 10;
                    [y_pred, fitParams, ~, ~] = realtimepsychometricFit(stim_fit, response_for_fitting, config.stimuli_range, options);
                    psych_data{i} = struct('y_pred', y_pred, 'fitParams', fitParams, 'stim_fit', stim_fit, 'physical_response', physical_response, 'rule', current_rule);
                    
                    hit_rate_data(i, 1) = 100 * sum(hit_fit == 1) / numel(hit_fit);
                    hit_rate_data(i, 2) = 100 * sum(hit_fit(side_fit==0)==1) / sum(side_fit==0);
                    hit_rate_data(i, 3) = 100 * sum(hit_fit(side_fit==1)==1) / sum(side_fit==1);

                    left_edges = linspace(min(config.stimuli_range), config.true_mu, 6);
                    right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
                    bin_edges = unique([left_edges, right_edges]);
                    stim_hist_data{i}.correct = histcounts(stim_fit(hit_fit == 1), bin_edges);
                    stim_hist_data{i}.incorrect = histcounts(stim_fit(hit_fit == 0), bin_edges);
                    
                    relevant_blocks = [];
                    for j = 1:numel(state.blockStatsHistory)
                        block_indices = state.blockStatsHistory(j).indices;
                        if min(block_indices) >= start_idx && max(block_indices) <= end_idx
                            relevant_blocks = [relevant_blocks, state.blockStatsHistory(j)];
                        end
                    end
                    
                    if ~isempty(relevant_blocks)
                        hit_rate_std(i, 1) = std(arrayfun(@(blk) blk.hitRates.overall, relevant_blocks), 'omitnan');
                        hit_rate_std(i, 2) = std(arrayfun(@(blk) blk.hitRates.left, relevant_blocks), 'omitnan');
                        hit_rate_std(i, 3) = std(arrayfun(@(blk) blk.hitRates.right, relevant_blocks), 'omitnan');
                        correct_cells = arrayfun(@(s) s.stimCounts.correct(:)', relevant_blocks, 'UniformOutput', false);
                        counts_matrix_corr = cell2mat(correct_cells);
                        incorrect_cells = arrayfun(@(s) s.stimCounts.incorrect(:)', relevant_blocks, 'UniformOutput', false);
                        counts_matrix_incorr = cell2mat(incorrect_cells);
                        stim_hist_data{i}.mean_corr = mean(counts_matrix_corr, 1);
                        stim_hist_data{i}.std_corr = std(counts_matrix_corr, 0, 1);
                        stim_hist_data{i}.mean_incorr = mean(counts_matrix_incorr, 1);
                        stim_hist_data{i}.std_incorr = std(counts_matrix_incorr, 0, 1);
                    else
                        hit_rate_std(i, :) = 0;
                    end
                end
                
                if flags.psych, plotContextPsychometric(handles.axes_h.custom_psych, psych_data, config, context_colors,contexts_names); end
                if flags.hit, plotContextHitRates(handles.axes_h.custom_hitrate, hit_rate_data, hit_rate_std, context_colors,contexts_names); end
                if flags.stim, plotContextStimulusHistogram(handles.axes_h.custom_stim, stim_hist_data, config, context_colors,contexts_names); end

            % =================================================================
            %                   EVALUATE ACTION
            % =================================================================
            case 'evaluate'
                if numel(varargin) < 1, error('Evaluate action requires a cell array of contexts.'); end
                contexts = varargin{1};
                if ~iscell(contexts) || isempty(contexts), error('Contexts must be a non-empty cell array of [start, end] pairs.'); end
                
                num_contexts = numel(contexts);
                results = struct('start_trial', [], 'end_trial', [], 'distribution_type', [], 'calculated_boundary', [], 'total_hit_percent', [], 'total_violations_percent', [], 'right_correct_percent', [], 'left_correct_percent', []);
                results = repmat(results, 1, num_contexts);

                for i = 1:num_contexts
                    start_idx = contexts{i}(1);
                    end_idx = contexts{i}(2);

                    if start_idx >= end_idx || start_idx < 1 || end_idx > numel(data.hit_history), continue; end
                    
                    indices = start_idx:end_idx;
                    hit_chunk = data.hit_history(indices);
                    side_chunk = data.previous_sides(indices);
                    stim_chunk = data.stim_history(indices);
                    
                    valid_mask = ~isnan(hit_chunk);
                    if sum(valid_mask) < 10, continue; end
                    
                    stim_fit = stim_chunk(valid_mask);
                    side_fit = side_chunk(valid_mask);
                    hit_fit = hit_chunk(valid_mask);
                    
                    current_rule = data.full_rule_history;

                    physical_response = zeros(size(hit_fit));
                    physical_response(hit_fit == 1) = side_fit(hit_fit == 1);
                    physical_response(hit_fit == 0) = 1 - side_fit(hit_fit == 0);
                    
                    response_for_fitting = physical_response;
                    if contains(string(current_rule), 'Left', 'IgnoreCase', true), response_for_fitting = 1 - response_for_fitting; end
                    
                    options.MinTrials = 10;
                    [~, fitParams, ~, ~] = realtimepsychometricFit(stim_fit, response_for_fitting, config.stimuli_range, options);
                    
                    results(i).start_trial = start_idx;
                    results(i).end_trial = end_idx;
                    results(i).distribution_type = getDistributionType(data, indices, current_rule);
                    results(i).calculated_boundary = fitParams(1);
                    results(i).total_hit_percent = 100 * mean(hit_fit);
                    results(i).total_violations_percent = 100 * mean(isnan(data.hit_history(indices)));
                    
                    right_trials = (side_fit == 1);
                    left_trials = (side_fit == 0);
                    results(i).right_correct_percent = 100 * mean(hit_fit(right_trials));
                    results(i).left_correct_percent = 100 * mean(hit_fit(left_trials));
                end
                state = results; % Override the return value for this action
                return; % Exit early

            otherwise
                error('Unknown action: "%s". Use "live", "custom", or "context".', action);
        end
    catch ME
        % Create a more detailed error message including the line number.
        if ~isempty(ME.stack)
            
            % safe_filename = strrep(ME.stack(1).file, '\', '\\');
            % errorLocation = sprintf('File: %s, Function: %s, Line: %d', ...
            %     safe_filename, ME.stack(1).name, ME.stack(1).line);
            
            errorLocation = ['File: ' ME.stack(1).file ...
                     ', Function: ' ME.stack(1).name ...
                     ', Line: ' num2str(ME.stack(1).line)];
        else
            errorLocation = 'Location not available in error stack.';
        end
        
        % fullErrorMessage = sprintf('An error occurred in RealTimeAnalysis:\n  Error: %s\n  %s', ...
        %     ME.message, errorLocation);
        
        fullErrorMessage = ['An error occurred in RealTimeAnalysis:' newline ...
                   ' Error: ' ME.message newline ...
                   ' ' errorLocation];

        fullErrorMsg = strrep(fullErrorMessage, '\', '\\');
        warning('RealTimeAnalysis:Error', fullErrorMsg);
        
        if config.debug, rethrow(ME); end % In experiment mode, the function will gracefully return the original state.
    end

    % =================================================================
    %                   NESTED HELPER FUNCTIONS
    % =================================================================
    
    %% LIVE ANALYSIS HELPERS
    function state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags)
        state.block_count = state.block_count + 1;
        [newBlockStat, newRow] = processBlock(data, config, dataBuffer);
        state.blockStatsHistory = [state.blockStatsHistory, newBlockStat];       
        updateTable(handles, newRow);
        state.table_row_editable(end+1) = true;

        state.last_analyzed_valid_trial = sum(~isnan(data.hit_history));

        if strcmp(get(handles.main_fig, 'Visible'), 'on')
            updateLivePlots(state, data, handles, config, flags);
        end
        
        
    end

    function state = reAnalyzeLastChunk(state, data, handles, config, dataBuffer, flags)
        [newBlockStat, newRow] = processBlock(data, config, dataBuffer);
        state.blockStatsHistory(end) = newBlockStat;
        replaceLastTableRow(handles, newRow);
        
        state.last_analyzed_valid_trial = sum(~isnan(data.hit_history));

        if strcmp(get(handles.main_fig, 'Visible'), 'on')
            updateLivePlots(state, data, handles, config, flags);
        end
        
        
    end

    function [blockStat, tableRow] = processBlock(data, config, dataBuffer)
        physical_response = zeros(size(dataBuffer.hit));
        physical_response(dataBuffer.hit == 1) = dataBuffer.side(dataBuffer.hit == 1);
        physical_response(dataBuffer.hit == 0) = 1 - dataBuffer.side(dataBuffer.hit == 0);
        
        current_rule = data.full_rule_history;

        response_for_fitting = physical_response;
        if contains(string(current_rule), 'Left', 'IgnoreCase', true)
            response_for_fitting = 1 - physical_response;
        end
        
        options.MinTrials = 20;
        [~, fitParams, methodUsed, fitStatus] = realtimepsychometricFit(dataBuffer.stim, response_for_fitting, config.stimuli_range, options);
        
        hr.overall = 100 * sum(dataBuffer.hit == 1) / numel(dataBuffer.hit);
        left_mask = (dataBuffer.side == 0);
        if any(left_mask), hr.left = 100 * sum(dataBuffer.hit(left_mask)==1) / sum(left_mask); else, hr.left = NaN; end
        right_mask = (dataBuffer.side == 1);
        if any(right_mask), hr.right = 100 * sum(dataBuffer.hit(right_mask)==1) / sum(right_mask); else, hr.right = NaN; end
        
        blockStat.indices = dataBuffer.indices;
        blockStat.hitRates = hr;
        
        left_edges = linspace(min(config.stimuli_range), config.true_mu, 6);
        right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
        bin_edges = unique([left_edges, right_edges]);
        stim_correct = dataBuffer.stim(dataBuffer.hit == 1);
        stim_incorrect = dataBuffer.stim(dataBuffer.hit == 0);
        blockStat.stimCounts.correct = histcounts(stim_correct, bin_edges);
        blockStat.stimCounts.incorrect = histcounts(stim_incorrect, bin_edges);
        
        start_trial = min(dataBuffer.indices); end_trial = max(dataBuffer.indices);
        dist_right = strjoin(string(unique(data.full_dist_right(dataBuffer.indices))), ', ');
        dist_left = strjoin(string(unique(data.full_dist_left(dataBuffer.indices))), ', ');
        
        select_status = ismember(methodUsed, {'ridge', 'robust'});
        if select_status
            tableRow = {select_status, current_rule, dist_left, dist_right, start_trial, end_trial, fitParams(2), config.true_mu, fitParams(1), fitParams(3), fitParams(4), string(methodUsed) + " (" + fitStatus + ")", hr.overall, hr.left, hr.right};
        else
            tableRow = {select_status, current_rule, dist_left, dist_right, start_trial, end_trial, NaN, config.true_mu, NaN, NaN, NaN, string(methodUsed) + " (" + fitStatus + ")", hr.overall, hr.left, hr.right};
        end
    end

    function updateTable(handles, newRow)
        currentData = get(handles.ui_table, 'Data');
        set(handles.ui_table, 'Data', [currentData; newRow]);
    end
    
    function replaceLastTableRow(handles, newRow)
        currentData = get(handles.ui_table, 'Data');
        if ~isempty(currentData)
            newRow{1} = true; % Select the new row
            currentData(end,:) = newRow;
            set(handles.ui_table, 'Data', currentData);
        end
    end

    function updateLivePlots(state, data, handles, config, flags)
        if flags.psych, updatePsychometricPlot(handles.axes_h.live_psych, handles.ui_table, config); end
        if flags.hit, updateHitRatePlot(handles.axes_h.live_hitrate,state.context_blocks, handles.ui_table); end
        if flags.stim, updateStimulusHistogram(handles.axes_h.live_stim, state, data, config,handles.ui_table); end
    end

    function updatePsychometricPlot(ax, ui_table_handle, config)
        allData = get(ui_table_handle, 'Data');
        if isempty(allData)
            cla(ax, 'reset');
            return;
        end
        
        logical_indices = allData.Select == 1;   
        selectedData = allData(logical_indices, :);

        cla(ax, 'reset'); hold(ax, 'on');
        
        xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
        
        if ~isempty(selectedData)
            num_to_plot = height(selectedData);
            colors = createTemporalColormap(num_to_plot);
            
            psychometricFun = @(params, x) params(3) + (1 - params(3) - params(4)) ./ (1 + exp(-(x - params(1)) / params(2)));
            xGrid = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';

            for i = 1:num_to_plot
                row = selectedData(i, :);
                
                fitParams = [row.CalBoundary, row.Slope, row.LapseA, row.LapseB];
                if any(isnan(fitParams)), continue; end
                
                y_curve = psychometricFun(fitParams, xGrid);
                
                alpha = 0.4; width = 1.5;

                if i == num_to_plot, alpha = 0.9; width = 2.5; end
                
                plot(ax, xGrid, y_curve, 'Color', [colors(i,:), alpha], 'LineWidth', width, 'DisplayName', sprintf('Block (T %d)', row.Start_trial));
                xline(ax, row.CalBoundary, '-', 'Color', [colors(i,:), alpha], 'LineWidth', width-0.5, 'HandleVisibility', 'off');
            end
            legend(ax, 'show', 'Location', 'southeast');
        end
        grid(ax, 'on'); hold(ax, 'off');
        ylabel(ax, 'P(Choice)'); title(ax, 'Live Psychometric Curves');
    end

    function updateHitRatePlot(ax, context_blocks, ui_table_handle)
        allData = get(ui_table_handle, 'Data');
        if isempty(allData)
            cla(ax, 'reset');
            return;
        end
        
        logical_mask = allData.Select == 1;
        selectedData = allData(logical_mask, :);

        cla(ax, 'reset');
        if isempty(selectedData)
            title(ax, 'Live Hit Rate per Block (Nothing Selected)');
            xlim(ax, [0.5, 10.5]); ylim(ax, [0 100]); grid(ax, 'on');
            return;
        end

        hr_overall = selectedData.("Overall Hit %");
        hr_left = selectedData.("Left Hit %");
        hr_right = selectedData.("Right Hit %");

        hold(ax, 'on');
        x_axis = 1:height(selectedData);
        plot(ax, x_axis, hr_overall, '-ok', 'LineWidth', 2, 'DisplayName', 'Overall');
        plot(ax, x_axis, hr_left, '--ob', 'LineWidth', 1.5, 'DisplayName', 'Left');
        plot(ax, x_axis, hr_right, '--or', 'LineWidth', 1.5, 'DisplayName', 'Right');
        % plotting context change
        if length(context_blocks) > 1
            for k = 2:length(context_blocks)
                xline(ax, context_blocks(k), '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
            end
        end
        hold(ax, 'off'); legend(ax, 'show', 'Location', 'southeast');
        xlim(ax, [0.5, max(10, height(selectedData) + 0.5)]); ylim(ax, [0 100]);
        xlabel(ax, 'Selected Block Number'); ylabel(ax, 'Hit %');
        title(ax, 'Live Hit Rate for Selected Blocks');
        grid(ax, 'on');
    end

    function updateStimulusHistogram(ax, state, data, config, ui_table_handle)
        
        allData = get(ui_table_handle, 'Data');
        if isempty(allData) || state.block_count == 0
            cla(ax, 'reset');
            return;
        end
        
        logical_mask = allData.Select == 1;
        selected_indices = find(logical_mask); % Get row numbers of selected blocks


        cla(ax, 'reset');
        if isempty(selected_indices)
            title(ax, 'Live Choice Distribution (Nothing Selected)');
            return;
        end

        n_selected_blocks = numel(selected_indices);
        red_map = interp1([0 1], [1 0.7 0.7; 0.9 0.2 0.1], linspace(0, 1, n_selected_blocks));
        green_map = interp1([0 1], [0.7 1 0.7; 0 0.65 0], linspace(0, 1, n_selected_blocks));

        left_edges = linspace(min(config.stimuli_range), config.true_mu, 6);
        right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
        bin_edges = unique([left_edges, right_edges]);
        bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

        yyaxis(ax, 'left');
        hold(ax, 'on');
        yyaxis(ax, 'right');
        hold(ax, 'on');

        max_count = 0;

        for i = 1:n_selected_blocks
            block_idx = selected_indices(i); % Use the index of the selected row
            block_stat = state.blockStatsHistory(block_idx);

        multiplier = 1;
            if i == n_selected_blocks, multiplier = 2; end
            
            yyaxis(ax, 'left');
            plot(ax, bin_centers, block_stat.stimCounts.incorrect, '-', 'Color', red_map(i,:), 'LineWidth', multiplier * 1.5);
            plot(ax, bin_centers, block_stat.stimCounts.correct, '-', 'Color', green_map(i,:), 'LineWidth', multiplier * 1.5);
            max_count = max([max_count, block_stat.stimCounts.correct, block_stat.stimCounts.incorrect]);
            
            yyaxis(ax, 'right');
            block_indices_raw = block_stat.indices;
            valid_mask = ~isnan(data.hit_history(block_indices_raw));
            stim_valid = data.stim_history(block_indices_raw(valid_mask));
            hit_valid = data.hit_history(block_indices_raw(valid_mask));
            stim_correct = stim_valid(hit_valid == 1);
            stim_incorrect = stim_valid(hit_valid == 0);
            
            jitter_base = (i - 1) * 0.2;
            jitter_incorrect = jitter_base + 0.08 * rand(size(stim_incorrect));
            jitter_correct = jitter_base + 0.08 * rand(size(stim_correct));
            scatter(ax, stim_incorrect, jitter_incorrect, multiplier * 25, red_map(i,:), 'filled', 'MarkerFaceAlpha', multiplier * 0.4);
            scatter(ax, stim_correct, jitter_correct, multiplier * 25, green_map(i,:), 'filled', 'MarkerFaceAlpha', multiplier * 0.4);
        end
        
        yyaxis(ax, 'left');
        ylabel(ax, 'Trial Count (Binned)');
        ax.YColor = 'k';
        ylim(ax, [0, max(1, max_count * 1.1)]);
        
        yyaxis(ax, 'right');
        ylim(ax, [0, n_selected_blocks * 0.2 + 0.1]);
        ax.YTick = [];
        ax.YColor = 'none';
        
        hold(ax, 'off');
        xline(ax, config.true_mu, '--k', 'Boundary', 'LineWidth', 2);
        xlabel(ax, 'Stimulus Value');
        title(ax, 'Live Choice Distribution for Selected Blocks');
        yyaxis(ax, 'left');
    end
    
    %% CUSTOM PLOTTING HELPERS
    function plotCustomPsychometric(ax, stim_fit, side_fit, hit_fit, config, rule)
        physical_response = zeros(size(hit_fit));
        physical_response(hit_fit == 1) = side_fit(hit_fit == 1);
        physical_response(hit_fit == 0) = 1 - side_fit(hit_fit == 0);
        
        response_for_fitting = physical_response;
        y_label = 'P(Right)';
        
        if contains(string(rule), 'Left', 'IgnoreCase', true)
            response_for_fitting = 1 - physical_response;
            y_label = 'P(Left)';
        end
        
        options.MinTrials = 10;
        [y_pred, fitParams, ~, ~] = realtimepsychometricFit(stim_fit, response_for_fitting, config.stimuli_range, options);
        
        cla(ax, 'reset'); hold(ax, 'on');
        xGrid = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';
        plot(ax, xGrid, y_pred, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted Curve');
        xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'DisplayName', 'True Boundary');
        xline(ax, fitParams(1), '--b', 'LineWidth', 1.5, 'DisplayName', 'Calculated');
        yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5],'HandleVisibility', 'off');
        grid(ax, 'on'); hold(ax, 'off');
        legend(ax); title(ax, sprintf('Custom Fit (Mu=%.2f)', fitParams(1)));
        xlabel(ax, 'Stimulus'); ylabel(ax, y_label);
    end

    function plotCustomHitRates(ax, hit_fit, side_fit, custom_range, blockStats)
        cla(ax, 'reset'); hold(ax, 'on');

        hr_custom.overall = 100 * sum(hit_fit == 1) / numel(hit_fit);
        hr_custom.left = 100 * sum(hit_fit(side_fit==0)==1) / sum(side_fit==0);
        hr_custom.right = 100 * sum(hit_fit(side_fit==1)==1) / sum(side_fit==1);

        relevant_blocks = [];
        for i = 1:numel(blockStats)
            block_indices = blockStats(i).indices;
            if min(block_indices) >= custom_range(1) && max(block_indices) <= custom_range(2)
                relevant_blocks = [relevant_blocks, blockStats(i)];
            end
        end
        
        if ~isempty(relevant_blocks)
            overall_values = arrayfun(@(blk) blk.hitRates.overall, relevant_blocks);
            left_values = arrayfun(@(blk) blk.hitRates.left, relevant_blocks);
            right_values = arrayfun(@(blk) blk.hitRates.right, relevant_blocks);

            % Now calculate the standard deviation on the resulting vectors
            std_dev.overall = std(overall_values, 'omitnan');
            std_dev.left = std(left_values, 'omitnan');
            std_dev.right = std(right_values, 'omitnan');
        else
            std_dev.overall = 0; std_dev.left = 0; std_dev.right = 0;
        end
        
        cats = categorical({'Overall', 'Left', 'Right'});
        errorbar(ax, cats, [hr_custom.overall, hr_custom.left, hr_custom.right], ...
            [std_dev.overall, std_dev.left, std_dev.right], ...
            'o', 'MarkerSize', 8, 'CapSize', 15, 'LineWidth', 1.5);
        
        ylabel(ax, 'Hit %'); title(ax, 'Hit Rates (w/ Block STD)'); 
        ylim(ax, [0 105]); grid(ax, 'on');
    end

    function plotCustomStimulusHistogram(ax, stim_fit, hit_fit, custom_range, blockStats, config)
        cla(ax, 'reset'); hold(ax, 'on');

        left_edges = linspace(min(config.stimuli_range), config.true_mu, 6);
        right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
        bin_edges = unique([left_edges, right_edges]);
        bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

        counts_custom.correct = histcounts(stim_fit(hit_fit == 1), bin_edges);
        counts_custom.incorrect = histcounts(stim_fit(hit_fit == 0), bin_edges);

        relevant_blocks = [];
        for i = 1:numel(blockStats)
            block_indices = blockStats(i).indices;
            if min(block_indices) >= custom_range(1) && max(block_indices) <= custom_range(2)
                relevant_blocks = [relevant_blocks, blockStats(i)];
            end
        end
        
        if ~isempty(relevant_blocks)
            correct_cells = arrayfun(@(blk) blk.stimCounts.correct, relevant_blocks,'UniformOutput',false);
            incorrect_cells = arrayfun(@(blk) blk.stimCounts.incorrect, relevant_blocks,'UniformOutput',false);
            
            counts_matrix_corr = cell2mat(correct_cells);
            counts_matrix_incorr = cell2mat(incorrect_cells);

            mean_corr = mean(counts_matrix_corr, 1);
            std_corr = std(counts_matrix_corr, 0, 1);
            mean_incorr = mean(counts_matrix_incorr, 1);
            std_incorr = std(counts_matrix_incorr, 0, 1);
            
            if sum(std_corr) > eps
                fill(ax, [bin_centers, fliplr(bin_centers)], [mean_corr - std_corr, fliplr(mean_corr + std_corr)], ...
                    [0 0.65 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Correct (Block STD)');
            end
            
            % --- Plot the fill area for INCORRECT trials, only if there is variance ---
            if sum(std_incorr) > eps
                fill(ax, [bin_centers, fliplr(bin_centers)], [mean_incorr - std_incorr, fliplr(mean_incorr + std_incorr)], ...
                    [0.9 0.2 0.1], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Incorrect (Block STD)');
            end
        end
        
        plot(ax, bin_centers, counts_custom.correct, '-o', 'Color', [0 0.65 0], 'LineWidth', 2, 'DisplayName', 'Correct (Custom)');
        plot(ax, bin_centers, counts_custom.incorrect, '-o', 'Color', [0.9 0.2 0.1], 'LineWidth', 2, 'DisplayName', 'Incorrect (Custom)');
        
        xline(ax, config.true_mu, '--k', 'Boundary', 'LineWidth', 2,'HandleVisibility', 'off');
        hold(ax, 'off'); legend(ax, 'Location', 'northwest');
        title(ax, 'Choice Distribution (w/ Block STD)');
        xlabel(ax, 'Stimulus Value'); ylabel(ax, 'Trial Count');
    end
    
    %% CONTEXT PLOTTING HELPERS
    function plotContextPsychometric(ax, psych_data, config, colors,context_names)
        cla(ax, 'reset'); hold(ax, 'on');
        xGrid = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';
        
        xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'DisplayName', 'True Boundary');
        yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
        
        contains_left_rule = false;
        contains_right_rule = false;
    
        for i = 1:numel(psych_data)
            if isempty(psych_data{i}), continue; end
            
            if contains(string(psych_data{i}.rule), 'Left', 'IgnoreCase', true)                
                contains_left_rule = true;
            else
                contains_right_rule = true;
            end
            
            plot(ax, xGrid, psych_data{i}.y_pred, '-', 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', context_names{i});
            xline(ax, psych_data{i}.fitParams(1), '--', 'Color', colors(i,:), 'LineWidth', 1.5, 'HandleVisibility', 'off');
        end
        
        if contains_left_rule && ~contains_right_rule, ylabel(ax, 'P(Left)');
        elseif ~contains_left_rule && contains_right_rule, ylabel(ax, 'P(Right)');
        else, ylabel(ax, 'P(Choice)'); end
        
        grid(ax, 'on'); hold(ax, 'off');
        legend(ax, 'show', 'Location', 'southeast');
        title(ax, 'Contextual Psychometric Fits');
        xlabel(ax, 'Stimulus');
    end

    function plotContextHitRates(ax, hit_rate_data, hit_rate_std, colors,context_names)
        cla(ax, 'reset'); hold(ax, 'on');
        
        if isempty(hit_rate_data), return; end
        
        num_contexts = size(hit_rate_data, 1);
        num_groups = size(hit_rate_data, 2); % Should be 3 for Overall, Left, Right

        b = bar(ax, hit_rate_data', 'grouped');
        
        % Set colors for each context
        for i = 1:num_contexts
            b(i).FaceColor = colors(i,:);
        end

        % Calculate the x-positions for error bars
        % For grouped bars, we need to calculate the offset for each group
        group_width = min(0.8, num_contexts/(num_contexts + 1.5));

        for i = 1:num_contexts
            % Calculate x-coordinates for this context across all groups
            x_offset = (-(num_contexts-1)/2 + (i-1)) * group_width/num_contexts;
            x_coords = (1:num_groups) + x_offset;

            % Plot error bars for this context
            errorbar(ax, x_coords, hit_rate_data(i,:), hit_rate_std(i,:), ...
                'k', 'linestyle', 'none', 'CapSize', 4, 'LineWidth', 1);
        end

        ax.XTick = 1:num_groups;
        ax.XTickLabel = {'Overall', 'Left', 'Right'};
        ylabel(ax, 'Hit %');
        title(ax, 'Contextual Hit Rates (w/ Block STD)');
        ylim(ax, [0 105]);
        grid(ax, 'on');
        
        % legend_labels = arrayfun(@(x) sprintf('Context %d', x), 1:num_contexts, 'UniformOutput', false);
        % legend_labels = context_names
        % legend(ax, legend_labels, 'Location', 'northeastoutside');
        hold(ax, 'off');
    end

    function plotContextStimulusHistogram(ax, stim_hist_data, config, colors,context_names)
        cla(ax, 'reset'); hold(ax, 'on');

        left_edges = linspace(min(config.stimuli_range), config.true_mu, 6);
        right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
        bin_edges = unique([left_edges, right_edges]);
        bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;
        
        for i = 1:numel(stim_hist_data)
            if isempty(stim_hist_data{i}), continue; end
            
            if isfield(stim_hist_data{i}, 'mean_corr')
                if sum(stim_hist_data{i}.std_corr) > eps
                    fill(ax, [bin_centers, fliplr(bin_centers)], [stim_hist_data{i}.mean_corr - stim_hist_data{i}.std_corr, fliplr(stim_hist_data{i}.mean_corr + stim_hist_data{i}.std_corr)], ...
                        colors(i,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
                end
                if sum(stim_hist_data{i}.std_incorr) > eps
                    fill(ax, [bin_centers, fliplr(bin_centers)], [stim_hist_data{i}.mean_incorr - stim_hist_data{i}.std_incorr, fliplr(stim_hist_data{i}.mean_incorr + stim_hist_data{i}.std_incorr)], ...
                        colors(i,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
                end
            end
            
            plot(ax, bin_centers, stim_hist_data{i}.correct, '-o', 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', sprintf('Correct C%d', i));
            plot(ax, bin_centers, stim_hist_data{i}.incorrect, ':x', 'Color', colors(i,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Incorrect C%d', i));
        end
        
        xline(ax, config.true_mu, '--k', 'Boundary', 'LineWidth', 2);
        hold(ax, 'off');
        % legend(ax, 'show', 'Location', 'northwest');
        title(ax, 'Contextual Choice Distributions');
        xlabel(ax, 'Stimulus Value');
        ylabel(ax, 'Trial Count');
    end

    %% GENERAL UTILITY FUNCTIONS
    function dist_type = getDistributionType(data, indices, rule)
        % Determines the distribution type based on the rule and the
        % distributions for left and right sides within the given indices.
        
        dist_left_cell = unique(data.full_dist_left(indices));
        dist_right_cell = unique(data.full_dist_right(indices));
        
        dist_left = dist_left_cell{1};
        dist_right = dist_right_cell{1};

        hard_dists = {'exponential', 'half-normal', 'sinusoidal'};
        
        if strcmp(dist_left, dist_right)
            dist_type = dist_left;
            return;
        end
        
        is_left_hard = ismember(dist_left, hard_dists);
        is_right_hard = ismember(dist_right, hard_dists);
        
        if contains(string(rule), 'Right', 'IgnoreCase', true) % High stimulus values correspond to Right
            if is_right_hard && ~is_left_hard
                dist_type = 'hard high';
            elseif ~is_right_hard && is_left_hard
                dist_type = 'hard low';
            else
                dist_type = 'mixed';
            end
        else % High stimulus values correspond to Left
            if is_left_hard && ~is_right_hard
                dist_type = 'hard high';
            elseif ~is_left_hard && is_right_hard
                dist_type = 'hard low';
            else
                dist_type = 'mixed';
            end
        end
    end

    function [y_pred, fitParams, methodUsed, fitStatus] = realtimepsychometricFit(stim, resp, rangeStim, options)
        % realtimepsychometricFit Robust real-time psychometric fitting and plotting.
        %
        % This function fits a 4-parameter logistic psychometric function. It includes
        % internal checks for data quality and fitting stability.
        %
        % Inputs:
        %   stim        - vector of stimulus values.
        %   response    - binary response vector (0 or 1).
        %   rangeStim   - 1x2 or 1x3 vector for the stimulus grid [min, max].
        %   options     - (Optional) struct with fields:
        %                 .MinTrials    - Min trials to attempt fit (default: 15).
        
        %                 .LapseUB      - Upper bound for lapse rates (default: 0.1).
        %                 .StdTol       - Tolerance for stimulus std dev (default: 1e-6).
        %                 .SlopeTol     - Tolerance for slope parameter (default: 1e-5).
        %
        % Outputs:
        %   y_pred      - Predicted y-values on a grid across rangeStim.
        %   fitParams   - [mu, sigma, lapseL, lapseR] fitted parameters.
        %   methodUsed  - String indicating the final fitting method used.
        %   fitStatus   - String providing information on the fit quality/outcome.

        %% 1. Argument Handling & Pre-computation Guard Clauses
        if nargin < 4, options = struct(); end
        if ~isfield(options, 'MinTrials'), options.MinTrials = 15; end
        if ~isfield(options, 'LapseUB'), options.LapseUB = 0.1; end
        if ~isfield(options, 'StdTol'), options.StdTol = 1e-6; end
        if ~isfield(options, 'SlopeTol'), options.SlopeTol = 1e-5; end
        fitParams = [nan,nan,nan,nan]; y_pred = []; fitStatus = 'Success'; % Assume success initially
        
        % Ensure both inputs are vectors and have the same number of elements

        if ~isvector(stim) || ~isvector(resp)
            methodUsed = 'Fit Canceled';
            fitStatus = 'Inputs `stim` and `resp` must be vectors.';
            return;
        end
        if numel(stim) ~= numel(resp)
            methodUsed = 'Fit Canceled';
            fitStatus = 'Inputs `stim` and `resp` must have the same number of elements.';
            return;
        end

        % Enforce column vector orientation for consistency with fitting functions.
        % The (:) operator robustly reshapes any vector into a column vector.
        stim = stim(:);
        resp = resp(:);
        
        % GUARD: Check for minimum number of trials
        if numel(stim) < options.MinTrials, methodUsed = 'Fit Canceled'; fitStatus = sprintf('Insufficient trials (n=%d, min=%d)', numel(stim), options.MinTrials); return; end
        % GUARD: Check for stimulus variance
        if std(stim) < options.StdTol, methodUsed = 'Fit Canceled'; fitStatus = 'Insufficient stimulus variance'; return; end
        
        %% 2. Initial Fit (Ridge)
        stim_std = (stim - mean(stim)) / std(stim); methodUsed = 'ridge';
        try
            % --- Ridge logistic fit for mu and sigma ---
            [B, FitInfo] = lassoglm(stim_std, resp, 'binomial', 'Alpha', 1e-6, 'Lambda', 0.1);
            b0 = FitInfo.Intercept; b1 = B(1);
             % GUARD: Check for near-zero or excessively large slope from ridge fit
            if abs(b1) < options.SlopeTol, throw(MException('MyFit:ZeroSlope', 'Initial ridge fit found no slope.')); end
            if abs(b1) > 10 % Check for quasi-perfect separation
                throw(MException('MyFit:SteepSlope', 'Initial ridge fit is too steep.'));
            end
            mu = -b0 / b1 * std(stim) + mean(stim); sigma = std(stim) / b1;
            % Residual lapse estimate for initialization
            predTrain = 1 ./ (1 + exp(-(b0 + b1 * stim_std)));
            lapseEstimate = mean(abs(predTrain - resp));
            lapseL = min(max(lapseEstimate * 1.2, 0), options.LapseUB); lapseR = lapseL;
        catch ME
             % --- Robust fallback if ridge fit fails for any reason ---
            methodUsed = 'robust'; fitStatus = sprintf('Switched to robust fit. Reason: %s', ME.message);
            try
                brob = robustfit(stim, resp, 'logit');
                % GUARD: Check for near-zero slope from robust fit
                if abs(brob(2)) < options.SlopeTol, methodUsed = 'Fit Failed'; fitStatus = 'Could not find a slope.'; return; end
                mu = -brob(1) / brob(2); sigma = 1 / brob(2);
                lapseL = 0.02; lapseR = 0.02; % Use fixed lapse guesses for robust fallback
            catch, methodUsed = 'Fit Failed'; fitStatus = 'Robustfit also failed.'; return;
            end
        end
        %% 3. Final Nonlinear Fit (lsqcurvefit)
        psychometricFun = @(params, x) params(3) + (1 - params(3) - params(4)) ./ (1 + exp(-(x - params(1)) / params(2)));
        % Use a slightly wider range for bounds to avoid railing issues
        stim_min = min(rangeStim); stim_max = max(rangeStim); range_width = stim_max - stim_min;
        init = [mu, sigma, lapseL, lapseR];
        lb = [stim_min - 0.1*range_width, 0.1, 0, 0];
        ub = [stim_max + 0.1*range_width, 15, options.LapseUB, options.LapseUB];
        % Constrain initial guess to be within bounds
        init(1) = max(min(init(1), ub(1)), lb(1)); init(2) = max(min(init(2), ub(2)), lb(2));
        optimOpts = optimset('Display', 'off');
        fitParams = lsqcurvefit(psychometricFun, init, stim, resp, lb, ub, optimOpts);
        
        %% 4. Post-Fit Sanity Checks & Prediction
        % CHECK: Did the fit "rail" against the stimulus range bounds?
        bound_tolerance = 0.01 * range_width;
        % CHECK: Did the lapse rates hit their upper bound?
        if (fitParams(1) <= lb(1) + bound_tolerance) || (fitParams(1) >= ub(1) - bound_tolerance), fitStatus = 'Warning: Threshold at edge of range.'; end
        if (fitParams(3) >= options.LapseUB*0.99) || (fitParams(4) >= options.LapseUB*0.99), fitStatus = 'Warning: Lapse rate at upper bound.'; end
        xGrid = linspace(stim_min, stim_max, 300)';
        y_pred = psychometricFun(fitParams, xGrid);
    end

    function cmap = createTemporalColormap(n_colors)
        if n_colors == 0, cmap = []; return; end
        if n_colors == 1, cmap = [0.8 0 0]; return; end % A single dark red
        % Create a high-contrast colormap for a few items
        if n_colors <= 5
             cmap = [0.8 0.1 0.1;  % Red
                     0.1 0.5 0.8;  % Blue
                     0.1 0.7 0.2;  % Green
                     0.7 0.2 0.7;  % Purple
                     0.9 0.6 0.0]; % Orange
             cmap = cmap(1:n_colors, :);
        else % Fallback for more colors
            h = linspace(0.6, 0, n_colors)';
            s = linspace(0.8, 1, n_colors)';
            v = linspace(0.7, 1, n_colors)';
            cmap = hsv2rgb([h, s, v]);
        end
    end

end
