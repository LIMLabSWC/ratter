function state = RealTimeAnalysis(action, state, data, handles, config, varargin)
%   RealTimeAnalysis  Stateless real-time analysis and plotting for BControl.
%
%   All state is passed in and out on every call. The outer try/catch ensures
%   any uncaught error returns the original state unmodified, preventing
%   BControl crashes during live experiments.
%
%   Actions: 'live', 'redraw', 'context_switch', 'custom', 'context', 'evaluate'
%
%   New in this version:
%     - Mode-aware processing (Full / Discrete / Fixed Stimuli / No Sound)
%     - Psychometric and stimulus histogram only shown when mode is eligible
%     - Hit rate always shown for all modes
%     - Discrete mode uses actual unique stimulus values as bin centers
%     - Pending-switch support (config.stimulus_mode reflects committed mode)
%     - Fixed blockStatsHistory ↔ table-row alignment bug
%     - Fixed replaceLastEditableTableRow naming bug
%     - Comprehensive ishandle guards on all plot axes accesses
%     - NaN stimulus and invalid side value guards in processBlock

% ------------------------------------------------------------------
%  DATA INTEGRITY PRE-CHECK
%  Run before the main switch so all paths benefit from clean data.
% ------------------------------------------------------------------
try
    % Guard: required fields must exist
    required_fields = {'hit_history', 'previous_sides', 'stim_history'};
    for f = 1:numel(required_fields)
        if ~isfield(data, required_fields{f}) || isempty(data.(required_fields{f}))
            warning('RealTimeAnalysis:MissingField', 'data.%s is missing or empty. Returning.', required_fields{f});
            return;
        end
    end

    len_hit   = numel(data.hit_history);
    len_sides = numel(data.previous_sides);
    len_stim  = numel(data.stim_history);
    min_len   = min([len_hit, len_sides, len_stim]);

    if len_hit > min_len || len_sides > min_len || len_stim > min_len
        warning('RealTimeAnalysis:DataMismatch', ...
            'History vectors have mismatched lengths (%d/%d/%d). Truncating to %d.', ...
            len_hit, len_sides, len_stim, min_len);
        data.hit_history    = data.hit_history(1:min_len);
        data.previous_sides = data.previous_sides(1:min_len);
        data.stim_history   = data.stim_history(1:min_len);
    end
catch ME
    warning('RealTimeAnalysis:IntegrityCheck', 'Data integrity check failed: %s', ME.message);
end

% ------------------------------------------------------------------
%  MAIN SWITCH
% ------------------------------------------------------------------
try
    switch lower(action)

        % ==============================================================
        %                        LIVE UPDATE
        % ==============================================================
        case 'live'
            if numel(varargin) < 1, error('live action requires a flags struct.'); end
            flags = varargin{1};

            lastAnalyzed = state.last_analyzed_valid_trial;
            % Combined validity: hit must be non-NaN AND side must be 0 or 1
            valid_mask   = ~isnan(data.hit_history) & ismember(data.previous_sides, [0 1]);
            validTrials  = sum(valid_mask);

            if (validTrials - lastAnalyzed) >= config.trials_per_block
                valid_indices  = find(valid_mask);
                buffer_indices = valid_indices(end - config.trials_per_block + 1 : end);

                dataBuffer = buildDataBuffer(data, buffer_indices);
                state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags);
            end

            % ==============================================================
            %                      CONTEXT SWITCH
            % ==============================================================
        case 'context_switch'
            if numel(varargin) < 1, error('context_switch action requires a flags struct.'); end
            flags = varargin{1};

            merge_threshold = round(2 * config.trials_per_block / 3);
            valid_mask      = ~isnan(data.hit_history) & ismember(data.previous_sides, [0 1]);
            lastAnalyzed    = state.last_analyzed_valid_trial;
            validTrials     = sum(valid_mask);
            remaining_valid = validTrials - lastAnalyzed;

            state.context_blocks(end + 1) = state.block_count;

            if remaining_valid > 0
                valid_indices    = find(valid_mask);
                new_valid_indices = valid_indices(lastAnalyzed + 1 : end);

                if remaining_valid < merge_threshold && state.block_count > 0
                    % Merge small remainder into the last block
                    last_block_indices = state.blockStatsHistory(end).indices;
                    combined_indices   = [last_block_indices, new_valid_indices'];
                    dataBuffer = buildDataBuffer(data, combined_indices);
                    state = reAnalyzeLastChunk(state, data, handles, config, dataBuffer, flags);

                elseif remaining_valid >= merge_threshold
                    % Enough for its own block
                    dataBuffer = buildDataBuffer(data, new_valid_indices);
                    state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags);
                end
            end

            % ==============================================================
            %                         REDRAW
            % ==============================================================
        case 'redraw'
            if numel(varargin) < 1, error('redraw action requires a flags struct.'); end
            flags = varargin{1};
            updateLivePlots(state, data, handles, config, flags);

            % ==============================================================
            %                      CUSTOM RANGE PLOT
            % ==============================================================
        case 'custom'
            if numel(varargin) < 3, error('custom action requires flags, start_trial, end_trial.'); end
            flags     = varargin{1};
            start_idx = varargin{2};
            end_idx   = varargin{3};

            % Validate range
            n_total = numel(data.hit_history);
            if start_idx < 1 || end_idx > n_total || start_idx >= end_idx
                warning('RealTimeAnalysis:Custom', 'Invalid trial range [%d %d] (total trials: %d).', start_idx, end_idx, n_total);
                return;
            end

            indices   = start_idx:end_idx;
            hit_chunk = data.hit_history(indices);
            valid_mask = ~isnan(hit_chunk) & ismember(data.previous_sides(indices), [0 1]);
            if sum(valid_mask) < 10
                warning('RealTimeAnalysis:Custom', 'Fewer than 10 valid trials in custom range — skipping.');
                return;
            end

            stim_fit = data.stim_history(indices(valid_mask));
            side_fit = data.previous_sides(indices(valid_mask));
            hit_fit  = hit_chunk(valid_mask);
            valid_sub_indices = indices(valid_mask);  % track actual trial numbers
            % Remove any NaN stimulus values (keep valid_sub_indices in sync)
            stim_nan = isnan(stim_fit);
            stim_fit = stim_fit(~stim_nan);
            side_fit = side_fit(~stim_nan);
            hit_fit  = hit_fit(~stim_nan);
            valid_sub_indices = valid_sub_indices(~stim_nan);

            current_rule   = data.full_rule_history;
            psych_eligible = isPsychEligible(config.stimulus_mode, config.n_discrete);

            % Pass valid_sub_indices so processBlock lengths are consistent.
            % Override Start/End trial columns to reflect the user's chosen range.
            [newBlockStat, newRow] = processBlock(data, config, ...
                struct('stim', stim_fit, 'hit', hit_fit, 'side', side_fit, 'indices', valid_sub_indices));
            newRow{1} = false;
            newRow{6} = start_idx;  % Start_trial: user's chosen range start
            newRow{7} = end_idx;    % End_trial:   user's chosen range end
            updateTable(handles, newRow);
            state.table_row_editable(end+1) = false;

            if flags.psych
                if psych_eligible
                    plotCustomPsychometricFromCurve(handles.axes_h.custom_psych, newBlockStat, config, current_rule);
                else
                    setAxisUnavailableMessage(handles.axes_h.custom_psych, config.stimulus_mode);
                end
            end
            if flags.hit
                plotCustomHitRates(handles.axes_h.custom_hitrate, hit_fit, side_fit, [start_idx, end_idx], state.blockStatsHistory);
            end
            if flags.stim
                if psych_eligible
                    plotCustomStimulusHistogram(handles.axes_h.custom_stim, stim_fit, hit_fit, [start_idx, end_idx], state.blockStatsHistory, config);
                else
                    setAxisUnavailableMessage(handles.axes_h.custom_stim, config.stimulus_mode);
                end
            end

            % ==============================================================
            %                    CONTEXT COMPARISON PLOT
            % ==============================================================
        case 'context'
            if numel(varargin) < 2, error('context action requires flags and contexts cell array.'); end
            flags          = varargin{1};
            contexts       = varargin{2};
            contexts_names = varargin{3};

            if ~iscell(contexts) || isempty(contexts)
                error('contexts must be a non-empty cell array of [start,end] pairs.');
            end

            num_contexts   = numel(contexts);
            context_colors = createTemporalColormap(num_contexts);
            psych_eligible = isPsychEligible(config.stimulus_mode, config.n_discrete);

            psych_data     = cell(1, num_contexts);
            hit_rate_data  = zeros(num_contexts, 3);
            hit_rate_std   = zeros(num_contexts, 3);
            stim_hist_data = cell(1, num_contexts);

            for i = 1:num_contexts
                start_idx = contexts{i}(1);
                end_idx   = contexts{i}(2);
                n_total   = numel(data.hit_history);

                if start_idx < 1 || end_idx > n_total || start_idx >= end_idx, continue; end

                indices    = start_idx:end_idx;
                hit_chunk  = data.hit_history(indices);
                valid_mask = ~isnan(hit_chunk) & ismember(data.previous_sides(indices), [0 1]);
                if sum(valid_mask) < 10, continue; end

                stim_fit = data.stim_history(indices(valid_mask));
                side_fit = data.previous_sides(indices(valid_mask));
                hit_fit  = hit_chunk(valid_mask);
                valid_sub_indices = indices(valid_mask);
                % Strip NaN stimuli (keep valid_sub_indices in sync)
                stim_nan = isnan(stim_fit);
                stim_fit = stim_fit(~stim_nan);
                side_fit = side_fit(~stim_nan);
                hit_fit  = hit_fit(~stim_nan);
                valid_sub_indices = valid_sub_indices(~stim_nan);

                current_rule = data.full_rule_history;

                % Pass valid_sub_indices; override start/end trial in row.
                [newBlockStat, newRow] = processBlock(data, config, ...
                    struct('stim', stim_fit, 'hit', hit_fit, 'side', side_fit, 'indices', valid_sub_indices));
                newRow{1} = false;
                newRow{6} = start_idx;  % Start_trial: context range start
                newRow{7} = end_idx;    % End_trial:   context range end
                updateTable(handles, newRow);
                state.table_row_editable(end+1) = false;

                % Hit rates (always)
                hit_rate_data(i,1) = 100 * sum(hit_fit==1) / numel(hit_fit);
                left_m = (side_fit==0); right_m = (side_fit==1);
                if any(left_m),  hit_rate_data(i,2) = 100 * sum(hit_fit(left_m)==1)  / sum(left_m);  else, hit_rate_data(i,2) = NaN; end
                if any(right_m), hit_rate_data(i,3) = 100 * sum(hit_fit(right_m)==1) / sum(right_m); else, hit_rate_data(i,3) = NaN; end

                if psych_eligible
                    psych_data{i} = struct('y_pred', newBlockStat.fitCurve.y_pred, ...
                        'fitParams', newBlockStat.fitParams, 'rule', current_rule);

                    bin_edges = buildBinEdges(config, stim_fit);
                    if ~isempty(bin_edges)
                        stim_hist_data{i}.correct   = histcounts(stim_fit(hit_fit==1), bin_edges);
                        stim_hist_data{i}.incorrect = histcounts(stim_fit(hit_fit==0), bin_edges);
                        stim_hist_data{i}.bin_edges = bin_edges;
                    end
                end

                % Std from constituent live blocks
                relevant_blocks = [];
                for j = 1:numel(state.blockStatsHistory)
                    bi = state.blockStatsHistory(j).indices;
                    if ~isempty(bi) && min(bi) >= start_idx && max(bi) <= end_idx
                        relevant_blocks = [relevant_blocks, state.blockStatsHistory(j)]; %#ok<AGROW>
                    end
                end
                if ~isempty(relevant_blocks)
                    hit_rate_std(i,1) = std(arrayfun(@(b) b.hitRates.overall, relevant_blocks), 'omitnan');
                    hit_rate_std(i,2) = std(arrayfun(@(b) b.hitRates.left,    relevant_blocks), 'omitnan');
                    hit_rate_std(i,3) = std(arrayfun(@(b) b.hitRates.right,   relevant_blocks), 'omitnan');
                    if psych_eligible && ~isempty(stim_hist_data{i})
                        corr_cells  = arrayfun(@(b) b.stimCounts.correct(:)',   relevant_blocks, 'UniformOutput', false);
                        incorr_cells = arrayfun(@(b) b.stimCounts.incorrect(:)', relevant_blocks, 'UniformOutput', false);
                        % Only aggregate if all vectors have the same length
                        if numel(unique(cellfun(@numel, corr_cells))) == 1
                            stim_hist_data{i}.mean_corr  = mean(cell2mat(corr_cells),  1);
                            stim_hist_data{i}.std_corr   = std(cell2mat(corr_cells),  0, 1);
                            stim_hist_data{i}.mean_incorr = mean(cell2mat(incorr_cells), 1);
                            stim_hist_data{i}.std_incorr  = std(cell2mat(incorr_cells), 0, 1);
                        end
                    end
                else
                    hit_rate_std(i,:) = 0;
                end
            end

            if flags.psych
                if psych_eligible
                    plotContextPsychometric(handles.axes_h.custom_psych, psych_data, config, context_colors, contexts_names);
                else
                    setAxisUnavailableMessage(handles.axes_h.custom_psych, config.stimulus_mode);
                end
            end
            if flags.hit
                plotContextHitRates(handles.axes_h.custom_hitrate, hit_rate_data, hit_rate_std, context_colors, contexts_names);
            end
            if flags.stim
                if psych_eligible
                    plotContextStimulusHistogram(handles.axes_h.custom_stim, stim_hist_data, config, context_colors, contexts_names);
                else
                    setAxisUnavailableMessage(handles.axes_h.custom_stim, config.stimulus_mode);
                end
            end

            % ==============================================================
            %                         EVALUATE
            % ==============================================================
        case 'evaluate'
            % varargin{1}=flags, varargin{2}=context_trials, varargin{3}=context_modes
            if numel(varargin) < 2, error('evaluate action requires flags and context_trials.'); end
            contexts      = varargin{2};
            context_modes = {};
            if numel(varargin) >= 3, context_modes = varargin{3}; end

            if ~iscell(contexts) || isempty(contexts)
                error('contexts must be a non-empty cell array of [start,end] pairs.');
            end

            num_contexts = numel(contexts);
            results = struct('start_trial', [], 'end_trial', [], 'valid_trials', [], ...
                'stimulus_mode', [], 'distribution_type', [], 'calculated_boundary', [], ...
                'total_hit_percent', [], 'total_violations_percent', [], ...
                'right_correct_percent', [], 'left_correct_percent', []);
            results = repmat(results, 1, num_contexts);

            for i = 1:num_contexts
                start_idx = contexts{i}(1);
                end_idx   = contexts{i}(2);
                n_total   = numel(data.hit_history);

                % Determine mode for this specific context
                if numel(context_modes) >= i
                    ctx_mode = context_modes{i};
                else
                    ctx_mode = config.stimulus_mode;
                end
                % Infer n_discrete from mode label (conservative: assume eligible)
                ctx_n_disc = config.n_discrete;
                ctx_eligible = isPsychEligible(ctx_mode, ctx_n_disc);

                results(i).stimulus_mode = ctx_mode;

                if start_idx < 1 || end_idx > n_total || start_idx >= end_idx, continue; end

                indices    = start_idx:end_idx;
                hit_chunk  = data.hit_history(indices);
                side_chunk = data.previous_sides(indices);
                stim_chunk = data.stim_history(indices);

                valid_mask = ~isnan(hit_chunk) & ismember(side_chunk, [0 1]) & ~isnan(stim_chunk);
                if sum(valid_mask) < 10, continue; end

                stim_fit = stim_chunk(valid_mask);
                side_fit = side_chunk(valid_mask);
                hit_fit  = hit_chunk(valid_mask);

                current_rule = data.full_rule_history;

                results(i).start_trial              = start_idx;
                results(i).end_trial                = end_idx;
                results(i).valid_trials             = sum(valid_mask);
                results(i).total_violations_percent = 100 * mean(isnan(data.hit_history(indices)));
                results(i).total_hit_percent        = 100 * mean(hit_fit);

                % Side-specific hit rates with division-by-zero guard
                right_trials = (side_fit == 1);
                left_trials  = (side_fit == 0);
                if any(right_trials)
                    results(i).right_correct_percent = 100 * mean(hit_fit(right_trials));
                else
                    results(i).right_correct_percent = NaN;
                end
                if any(left_trials)
                    results(i).left_correct_percent = 100 * mean(hit_fit(left_trials));
                else
                    results(i).left_correct_percent = NaN;
                end

                % Distribution type and psychometric fit (mode-gated)
                if isfield(data, 'full_dist_right') && isfield(data, 'full_dist_left')
                    results(i).distribution_type = getDistributionType(data, indices, current_rule);
                else
                    results(i).distribution_type = ctx_mode;
                end

                if ctx_eligible
                    physical_response = zeros(size(hit_fit));
                    physical_response(hit_fit==1) = side_fit(hit_fit==1);
                    physical_response(hit_fit==0) = 1 - side_fit(hit_fit==0);
                    resp_fit = physical_response;
                    if contains(string(current_rule), 'Left', 'IgnoreCase', true)
                        resp_fit = 1 - resp_fit;
                    end
                    opts.MinTrials = 10;
                    [~, fitParams, ~, ~] = realtimepsychometricFit(stim_fit, resp_fit, config.stimuli_range, opts);
                    results(i).calculated_boundary = fitParams(1);
                else
                    results(i).calculated_boundary = NaN;
                end
            end

            state = results; % Override return value for evaluate action
            return;

        otherwise
            error('Unknown action: "%s".', action);
    end

catch ME
    % Build a clean error message without sprintf (avoids backslash issues)
    if ~isempty(ME.stack)
        loc = ['File: ' ME.stack(1).file ', Function: ' ME.stack(1).name ', Line: ' num2str(ME.stack(1).line)];
    else
        loc = 'Location unknown.';
    end
    msg = ['RealTimeAnalysis error: ' ME.message ' | ' loc];
    warning('RealTimeAnalysis:Error', '%s', msg);
    if isfield(config, 'debug') && config.debug, rethrow(ME); end
    % Return original state unmodified — BControl continues safely
end

% ==========================================================================
%  NESTED HELPER FUNCTIONS
% ==========================================================================

% ---------- DATA BUFFER BUILDER ----------

    function db = buildDataBuffer(data, indices)
        % Packages a set of trial indices into a dataBuffer struct.
        db.stim    = data.stim_history(indices);
        db.hit     = data.hit_history(indices);
        db.side    = data.previous_sides(indices);
        db.indices = indices;
    end

% ---------- LIVE ANALYSIS PIPELINE ----------

    function state = analyzeLiveChunk(state, data, handles, config, dataBuffer, flags)
        state.block_count = state.block_count + 1;
        [newBlockStat, newRow] = processBlock(data, config, dataBuffer);
        state.blockStatsHistory = [state.blockStatsHistory, newBlockStat];
        valid_mask = ~isnan(data.hit_history) & ismember(data.previous_sides, [0 1]);
        state.last_analyzed_valid_trial = sum(valid_mask);
        updateTable(handles, newRow);
        state.table_row_editable(end+1) = true;

        if ishandle(handles.main_fig) && strcmp(get(handles.main_fig, 'Visible'), 'on')
            updateLivePlots(state, data, handles, config, flags);
        end
    end

    function state = reAnalyzeLastChunk(state, data, handles, config, dataBuffer, flags)
        [newBlockStat, newRow] = processBlock(data, config, dataBuffer);
        state.blockStatsHistory(end) = newBlockStat;
        valid_mask = ~isnan(data.hit_history) & ismember(data.previous_sides, [0 1]);
        state.last_analyzed_valid_trial = sum(valid_mask);
        replaceLastEditableTableRow(handles, newRow, state.table_row_editable); % fixed name

        if ishandle(handles.main_fig) && strcmp(get(handles.main_fig, 'Visible'), 'on')
            updateLivePlots(state, data, handles, config, flags);
        end
    end

% ---------- CORE BLOCK PROCESSING ----------

    function [blockStat, tableRow] = processBlock(data, config, dataBuffer)
        % Mode-aware block computation.
        % Returns a blockStat struct and a table row cell array.
        % Always computes hit rates; psychometric fit and stim histogram are gated.

        % Guard: strip NaN stimulus values
        stim_nan_mask = isnan(dataBuffer.stim);
        if any(stim_nan_mask)
            dataBuffer.stim    = dataBuffer.stim(~stim_nan_mask);
            dataBuffer.hit     = dataBuffer.hit(~stim_nan_mask);
            dataBuffer.side    = dataBuffer.side(~stim_nan_mask);
            dataBuffer.indices = dataBuffer.indices(~stim_nan_mask);
        end
        % Guard: strip trials where side is not exactly 0 or 1
        valid_side = ismember(dataBuffer.side, [0 1]);
        if ~all(valid_side)
            dataBuffer.stim    = dataBuffer.stim(valid_side);
            dataBuffer.hit     = dataBuffer.hit(valid_side);
            dataBuffer.side    = dataBuffer.side(valid_side);
            dataBuffer.indices = dataBuffer.indices(valid_side);
        end
        % Guard: return empty if nothing remains
        if isempty(dataBuffer.hit)
            blockStat = makeEmptyBlockStat(config.stimulus_mode);
            tableRow  = makeEmptyTableRow(config);
            return;
        end

        stimulus_mode  = config.stimulus_mode;
        psych_eligible = isPsychEligible(stimulus_mode, config.n_discrete);
        current_rule   = data.full_rule_history;

        % --- Hit rates (always computed) ---
        hr.overall  = 100 * sum(dataBuffer.hit == 1) / numel(dataBuffer.hit);
        left_mask   = (dataBuffer.side == 0);
        right_mask  = (dataBuffer.side == 1);
        if any(left_mask),  hr.left  = 100 * sum(dataBuffer.hit(left_mask)==1)  / sum(left_mask);  else, hr.left  = NaN; end
        if any(right_mask), hr.right = 100 * sum(dataBuffer.hit(right_mask)==1) / sum(right_mask); else, hr.right = NaN; end

        blockStat.indices       = dataBuffer.indices;
        blockStat.hitRates      = hr;
        blockStat.stimulus_mode = stimulus_mode;

        % --- Stimulus counts and bin edges (eligible modes only) ---
        if psych_eligible
            bin_edges = buildBinEdges(config, dataBuffer.stim);
            if ~isempty(bin_edges)
                blockStat.stimCounts.correct   = histcounts(dataBuffer.stim(dataBuffer.hit==1), bin_edges);
                blockStat.stimCounts.incorrect  = histcounts(dataBuffer.stim(dataBuffer.hit==0), bin_edges);
                blockStat.stimCounts.bin_edges  = bin_edges;
            else
                blockStat.stimCounts = struct('correct', [], 'incorrect', [], 'bin_edges', []);
            end
        else
            blockStat.stimCounts = struct('correct', [], 'incorrect', [], 'bin_edges', []);
        end

        % --- Psychometric fit (eligible modes only) ---
        if psych_eligible
            physical_response = zeros(size(dataBuffer.hit));
            physical_response(dataBuffer.hit==1) = dataBuffer.side(dataBuffer.hit==1);
            physical_response(dataBuffer.hit==0) = 1 - dataBuffer.side(dataBuffer.hit==0);
            resp_fit = physical_response;
            if contains(string(current_rule), 'Left', 'IgnoreCase', true)
                resp_fit = 1 - physical_response;
            end
            opts.MinTrials = 20;

            % --- Warm start from the previous LIVE block, if one exists ---
            if ~isempty(state.blockStatsHistory) && isfield(state.blockStatsHistory(end), 'fitParams')
                prevParams = state.blockStatsHistory(end).fitParams;
                if numel(prevParams) == 4 && all(isfinite(prevParams))
                    opts.WarmStart = prevParams;
                end
            end

            [y_pred, fitParams, methodUsed, fitStatus] = realtimepsychometricFit( ...
                dataBuffer.stim, resp_fit, config.stimuli_range, opts);
            select_status = ismember(methodUsed, {'ridge', 'robust'});
            blockStat.fitCurve.xGrid  = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';
            blockStat.fitCurve.y_pred = y_pred;
        else
            fitParams     = [NaN, NaN, NaN, NaN];
            methodUsed    = 'N/A';
            fitStatus     = 'Not applicable for this mode';
            select_status = false;
            blockStat.fitCurve = struct('xGrid', [], 'y_pred', []);
        end

        blockStat.fitParams = fitParams; % feeds next block's warm start

        % --- Distribution strings ---
        % GUARD: In mixed-mode sessions, No Sound trials leave distribution history
        % entries at their BControl init value (typically numeric 0, not a string).
        % unique() on a cell with mixed types (strings + numerics) crashes in MATLAB.
        % Filter to char/string entries only; fall back to mode name if none survive.
        start_trial = min(dataBuffer.indices);
        end_trial   = max(dataBuffer.indices);
        try
            if isfield(data, 'full_dist_right') && isfield(data, 'full_dist_left') && ...
                    numel(data.full_dist_right) >= end_trial
                right_raw = data.full_dist_right(dataBuffer.indices);
                left_raw  = data.full_dist_left(dataBuffer.indices);
                is_str    = @(x) ischar(x) || isstring(x);
                right_str = right_raw(cellfun(is_str, right_raw));
                left_str  = left_raw(cellfun(is_str, left_raw));
                if ~isempty(right_str)
                    dist_right = strjoin(string(unique(right_str)), ', ');
                else
                    dist_right = string(stimulus_mode);
                end
                if ~isempty(left_str)
                    dist_left = strjoin(string(unique(left_str)), ', ');
                else
                    dist_left = string(stimulus_mode);
                end
            else
                dist_right = string(stimulus_mode);
                dist_left  = string(stimulus_mode);
            end
        catch
            dist_right = string(stimulus_mode);
            dist_left  = string(stimulus_mode);
        end

        % --- Build table row ---
        fit_label = string(methodUsed) + " (" + fitStatus + ")";
        if select_status
            tableRow = {select_status, string(stimulus_mode), current_rule, dist_left, dist_right, ...
                start_trial, end_trial, fitParams(2), config.true_mu, fitParams(1), fitParams(3), fitParams(4), ...
                fit_label, hr.overall, hr.left, hr.right};
        else
            tableRow = {select_status, string(stimulus_mode), current_rule, dist_left, dist_right, ...
                start_trial, end_trial, NaN, config.true_mu, NaN, NaN, NaN, ...
                fit_label, hr.overall, hr.left, hr.right};
        end
    end

% ---------- TABLE HELPERS ----------

    function updateTable(handles, newRow)
        try
            currentData = get(handles.ui_table, 'Data');

            % Backward compat: table saved before Stimulus_Mode column was added
            % has 15 columns; newRow has 16. Detect and patch before concatenation.
            if ~isempty(currentData) && isa(currentData, 'table') && ...
                    ~ismember('Stimulus_Mode', currentData.Properties.VariableNames)
                currentData.Stimulus_Mode = repmat("", height(currentData), 1);
                set(handles.ui_table, 'Data', currentData);
            end

            % Guard: if column count still mismatches, skip row with clear warning.
            expected_cols = numel(newRow);
            if ~isempty(currentData) && isa(currentData, 'table')
                actual_cols = width(currentData);
                if expected_cols ~= actual_cols
                    warning('RealTimeAnalysis:TableMismatch', ...
                        'newRow has %d elements but table has %d columns. Row skipped.', ...
                        expected_cols, actual_cols);
                    return;
                end
            end

            set(handles.ui_table, 'Data', [currentData; newRow]);
        catch ME
            warning('RealTimeAnalysis:TableUpdate', 'updateTable failed: %s', ME.message);
        end
    end

    function replaceLastEditableTableRow(handles, newRow, table_row_editable)
        % Replaces the last live (editable) block row in the table.
        % BUG FIX: was previously misnamed as replaceLastTableRow, making it unreachable.
        try
            currentData = get(handles.ui_table, 'Data');
            if isempty(currentData), return; end

            % Backward compat: same Stimulus_Mode column patch as updateTable.
            if isa(currentData, 'table') && ...
                    ~ismember('Stimulus_Mode', currentData.Properties.VariableNames)
                currentData.Stimulus_Mode = repmat("", height(currentData), 1);
                set(handles.ui_table, 'Data', currentData);
            end

            % Guard: sync length with table
            t_editable = table_row_editable(:);
            if numel(t_editable) > height(currentData)
                t_editable = t_editable(1:height(currentData));
            elseif numel(t_editable) < height(currentData)
                t_editable = [t_editable; false(height(currentData) - numel(t_editable), 1)];
            end

            last_editable = find(t_editable, 1, 'last');
            if ~isempty(last_editable)
                newRow{1} = true;
                currentData(last_editable, :) = newRow;
                set(handles.ui_table, 'Data', currentData);
            else
                updateTable(handles, newRow);
            end
        catch ME
            warning('RealTimeAnalysis:ReplaceRow', 'replaceLastEditableTableRow failed: %s', ME.message);
        end
    end

% ---------- LIVE PLOT COORDINATOR ----------

    function updateLivePlots(state, data, handles, config, flags)
        % Gates each sub-plot by mode eligibility before calling the plot function.
        psych_eligible = isPsychEligible(config.stimulus_mode, config.n_discrete);

        if flags.psych
            ax = handles.axes_h.live_psych;
            if ishandle(ax) && isvalid(ax)
                if psych_eligible
                    updatePsychometricPlot(ax, handles.ui_table, config);
                else
                    setAxisUnavailableMessage(ax, config.stimulus_mode);
                end
            end
        end

        if flags.hit
            ax = handles.axes_h.live_hitrate;
            if ishandle(ax) && isvalid(ax)
                updateHitRatePlot(ax, state.context_blocks, handles.ui_table);
            end
        end

        if flags.stim
            ax = handles.axes_h.live_stim;
            if ishandle(ax) && isvalid(ax)
                if psych_eligible
                    updateStimulusHistogram(ax, state, data, config, handles.ui_table);
                else
                    setAxisUnavailableMessage(ax, config.stimulus_mode);
                end
            end
        end
    end

% ---------- LIVE PSYCHOMETRIC PLOT ----------

    function updatePsychometricPlot(ax, ui_table_handle, config)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            allData = get(ui_table_handle, 'Data');
            if isempty(allData) || ~ismember('Select', allData.Properties.VariableNames)
                cla(ax, 'reset'); return;
            end

            selectedData = allData(allData.Select == 1, :);
            cla(ax, 'reset'); hold(ax, 'on');
            xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
            yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');

            if ~isempty(selectedData)
                num_to_plot = height(selectedData);
                colors = createTemporalColormap(num_to_plot);
                psychFun = @(p,x) p(3) + (1-p(3)-p(4)) ./ (1 + exp(-(x-p(1))./p(2)));
                xGrid = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';

                for i = 1:num_to_plot
                    row = selectedData(i, :);
                    % Guard: column may not exist in old sessions
                    if ~ismember('CalBoundary', row.Properties.VariableNames), continue; end
                    fp = [row.CalBoundary, row.Slope, row.LapseA, row.LapseB];
                    if any(isnan(fp)), continue; end
                    y_curve = psychFun(fp, xGrid);
                    alpha = 0.4; lw = 1.5;
                    if i == num_to_plot, alpha = 0.9; lw = 2.5; end
                    plot(ax, xGrid, y_curve, 'Color', [colors(i,:), alpha], 'LineWidth', lw, ...
                        'DisplayName', sprintf('Block T%d', row.Start_trial));
                    xline(ax, row.CalBoundary, '-', 'Color', [colors(i,:), alpha], 'LineWidth', lw-0.5, 'HandleVisibility', 'off');
                end
                legend(ax, 'show', 'Location', 'southeast');
            end
            grid(ax, 'on'); hold(ax, 'off');
            ylabel(ax, 'P(Choice)'); title(ax, 'Live Psychometric');
        catch ME
            warning('RealTimeAnalysis:PsychPlot', '%s', ME.message);
        end
    end

% ---------- LIVE HIT RATE PLOT ----------

    function updateHitRatePlot(ax, context_blocks, ui_table_handle)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            allData = get(ui_table_handle, 'Data');
            if isempty(allData) || ~ismember('Select', allData.Properties.VariableNames)
                cla(ax, 'reset'); return;
            end

            selectedData = allData(allData.Select == 1, :);
            cla(ax, 'reset');

            if isempty(selectedData)
                title(ax, 'Live Hit Rate (nothing selected)');
                xlim(ax, [0.5 10.5]); ylim(ax, [0 100]); grid(ax, 'on'); return;
            end

            % Guard: columns may be missing in old sessions
            required_cols = {'Overall Hit %', 'Left Hit %', 'Right Hit %'};
            for rc = required_cols
                if ~ismember(rc{1}, selectedData.Properties.VariableNames), return; end
            end

            hr_overall = selectedData.("Overall Hit %");
            hr_left    = selectedData.("Left Hit %");
            hr_right   = selectedData.("Right Hit %");

            hold(ax, 'on');
            x_ax = 1:height(selectedData);
            plot(ax, x_ax, hr_overall, '-ok',  'LineWidth', 2,   'DisplayName', 'Overall');
            plot(ax, x_ax, hr_left,    '--ob', 'LineWidth', 1.5, 'DisplayName', 'Left');
            plot(ax, x_ax, hr_right,   '--or', 'LineWidth', 1.5, 'DisplayName', 'Right');

            if numel(context_blocks) > 1
                for k = 2:numel(context_blocks)
                    xline(ax, context_blocks(k), '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
            end
            hold(ax, 'off');
            legend(ax, 'show', 'Location', 'southeast');
            xlim(ax, [0.5, max(10, height(selectedData)+0.5)]);
            ylim(ax, [0 100]);
            xlabel(ax, 'Selected Block'); ylabel(ax, 'Hit %');
            title(ax, 'Live Hit Rate'); grid(ax, 'on');
        catch ME
            warning('RealTimeAnalysis:HitRatePlot', '%s', ME.message);
        end
    end

% ---------- LIVE STIMULUS HISTOGRAM ----------

    function updateStimulusHistogram(ax, state, data, config, ui_table_handle)
        % BUG FIX: Uses table_row_editable to correctly map selected table rows
        % to blockStatsHistory indices, so custom/context rows don't cause
        % out-of-bounds indexing.
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            allData = get(ui_table_handle, 'Data');
            if isempty(allData) || state.block_count == 0 || ...
                    ~ismember('Select', allData.Properties.VariableNames)
                cla(ax, 'reset'); return;
            end

            selected_indices = find(allData.Select == 1);

            % Map: editable rows only correspond to blockStatsHistory entries
            t_editable = state.table_row_editable(:);
            if numel(t_editable) < height(allData)
                t_editable = [t_editable; false(height(allData) - numel(t_editable), 1)];
            end
            all_editable_rows = find(t_editable);

            % Keep only selected rows that are live (editable) blocks
            selected_editable = intersect(selected_indices, all_editable_rows);
            if isempty(selected_editable)
                cla(ax, 'reset');
                title(ax, 'Live Stim Dist. (no live blocks selected)'); return;
            end

            % Map each editable table row to its blockStatsHistory index
            block_hist_idxs = arrayfun(@(r) find(all_editable_rows == r), selected_editable);
            % Filter to valid range
            block_hist_idxs = block_hist_idxs(block_hist_idxs <= numel(state.blockStatsHistory));
            % Filter to blocks that have stimCounts (eligible mode)
            has_counts = arrayfun(@(i) ~isempty(state.blockStatsHistory(i).stimCounts.correct), block_hist_idxs);
            block_hist_idxs = block_hist_idxs(has_counts);

            if isempty(block_hist_idxs)
                setAxisUnavailableMessage(ax, config.stimulus_mode); return;
            end

            n_blocks = numel(block_hist_idxs);
            red_map   = interp1([0 1], [1 0.7 0.7; 0.9 0.2 0.1], linspace(0,1,n_blocks));
            green_map = interp1([0 1], [0.7 1 0.7; 0 0.65 0],    linspace(0,1,n_blocks));

            cla(ax, 'reset');
            yyaxis(ax, 'left');  hold(ax, 'on');
            yyaxis(ax, 'right'); hold(ax, 'on');
            max_count = 0;

            for p = 1:n_blocks
                bstat = state.blockStatsHistory(block_hist_idxs(p));
                if isempty(bstat.stimCounts.correct), continue; end

                % Use stored bin edges if available; fall back to buildBinEdges
                if isfield(bstat.stimCounts, 'bin_edges') && ~isempty(bstat.stimCounts.bin_edges)
                    bin_edges = bstat.stimCounts.bin_edges;
                else
                    bin_edges = buildBinEdges(config, data.stim_history(bstat.indices));
                end
                if isempty(bin_edges), continue; end
                bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

                mult = 1; if p == n_blocks, mult = 2; end

                yyaxis(ax, 'left');
                plot(ax, bin_centers, bstat.stimCounts.incorrect, '-', 'Color', red_map(p,:),   'LineWidth', mult*1.5);
                plot(ax, bin_centers, bstat.stimCounts.correct,   '-', 'Color', green_map(p,:), 'LineWidth', mult*1.5);
                max_count = max([max_count, bstat.stimCounts.correct, bstat.stimCounts.incorrect]);

                yyaxis(ax, 'right');
                blk_idx_raw  = bstat.indices;
                valid_m      = ~isnan(data.hit_history(blk_idx_raw));
                stim_v       = data.stim_history(blk_idx_raw(valid_m));
                hit_v        = data.hit_history(blk_idx_raw(valid_m));
                jitter_base  = (p-1) * 0.2;
                scatter(ax, stim_v(hit_v==0), jitter_base + 0.08*rand(sum(hit_v==0),1), mult*25, red_map(p,:),   'filled', 'MarkerFaceAlpha', mult*0.4);
                scatter(ax, stim_v(hit_v==1), jitter_base + 0.08*rand(sum(hit_v==1),1), mult*25, green_map(p,:), 'filled', 'MarkerFaceAlpha', mult*0.4);
            end

            yyaxis(ax, 'left');
            ylabel(ax, 'Trial Count (Binned)'); ax.YColor = 'k';
            ylim(ax, [0, max(1, max_count * 1.1)]);
            yyaxis(ax, 'right');
            ylim(ax, [0, n_blocks * 0.2 + 0.1]); ax.YTick = []; ax.YColor = 'none';
            hold(ax, 'off');
            xline(ax, config.true_mu, '--k', 'LineWidth', 2);
            xlabel(ax, 'Stimulus'); title(ax, 'Live Choice Distribution');
            yyaxis(ax, 'left');
        catch ME
            warning('RealTimeAnalysis:StimulusHist', '%s', ME.message);
        end
    end

% ---------- CUSTOM PLOT HELPERS ----------

    function plotCustomPsychometricFromCurve(ax, blockStat, config, rule)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            if isempty(blockStat.fitCurve.y_pred), return; end
            y_label = 'P(Right)';
            if contains(string(rule), 'Left', 'IgnoreCase', true), y_label = 'P(Left)'; end
            cla(ax, 'reset'); hold(ax, 'on');
            plot(ax, blockStat.fitCurve.xGrid, blockStat.fitCurve.y_pred, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted');
            xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'DisplayName', 'True');
            xline(ax, blockStat.fitParams(1), '--b', 'LineWidth', 1.5, ...
                'DisplayName', sprintf('Fit mu=%.2f', blockStat.fitParams(1)));
            yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
            grid(ax, 'on'); hold(ax, 'off'); legend(ax);
            xlabel(ax, 'Stimulus'); ylabel(ax, y_label); title(ax, 'Custom Psychometric');
        catch ME
            warning('RealTimeAnalysis:CustomPsych', '%s', ME.message);
        end
    end

    function plotCustomHitRates(ax, hit_fit, side_fit, custom_range, blockStats)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            cla(ax, 'reset'); hold(ax, 'on');
            hr.overall = 100 * sum(hit_fit==1) / numel(hit_fit);
            left_m = (side_fit==0); right_m = (side_fit==1);
            if any(left_m),  hr.left  = 100*sum(hit_fit(left_m)==1)/sum(left_m);   else, hr.left  = NaN; end
            if any(right_m), hr.right = 100*sum(hit_fit(right_m)==1)/sum(right_m); else, hr.right = NaN; end

            relevant_blocks = findRelevantBlocks(blockStats, custom_range(1), custom_range(2));
            if ~isempty(relevant_blocks)
                sd.overall = std(arrayfun(@(b) b.hitRates.overall, relevant_blocks), 'omitnan');
                sd.left    = std(arrayfun(@(b) b.hitRates.left,    relevant_blocks), 'omitnan');
                sd.right   = std(arrayfun(@(b) b.hitRates.right,   relevant_blocks), 'omitnan');
            else
                sd.overall = 0; sd.left = 0; sd.right = 0;
            end

            cats = categorical({'Overall','Left','Right'});
            errorbar(ax, cats, [hr.overall, hr.left, hr.right], [sd.overall, sd.left, sd.right], ...
                'o', 'MarkerSize', 8, 'CapSize', 15, 'LineWidth', 1.5);
            ylabel(ax, 'Hit %'); title(ax, 'Custom Hit Rates');
            ylim(ax, [0 105]); grid(ax, 'on'); hold(ax, 'off');
        catch ME
            warning('RealTimeAnalysis:CustomHitRate', '%s', ME.message);
        end
    end

    function plotCustomStimulusHistogram(ax, stim_fit, hit_fit, custom_range, blockStats, config)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            bin_edges = buildBinEdges(config, stim_fit);
            if isempty(bin_edges), setAxisUnavailableMessage(ax, 'insufficient stim variance'); return; end
            bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

            cla(ax, 'reset'); hold(ax, 'on');
            counts.correct   = histcounts(stim_fit(hit_fit==1), bin_edges);
            counts.incorrect  = histcounts(stim_fit(hit_fit==0), bin_edges);

            relevant_blocks = findRelevantBlocks(blockStats, custom_range(1), custom_range(2));
            if ~isempty(relevant_blocks)
                % Only aggregate blocks whose bins match current bin count
                n_bins = numel(bin_centers);
                valid_rb = relevant_blocks(arrayfun(@(b) numel(b.stimCounts.correct)==n_bins, relevant_blocks));
                if ~isempty(valid_rb)
                    mc = mean(cell2mat(arrayfun(@(b) b.stimCounts.correct(:)',   valid_rb, 'UniformOutput',false)), 1);
                    sc = std( cell2mat(arrayfun(@(b) b.stimCounts.correct(:)',   valid_rb, 'UniformOutput',false)), 0, 1);
                    mi = mean(cell2mat(arrayfun(@(b) b.stimCounts.incorrect(:)', valid_rb, 'UniformOutput',false)), 1);
                    si = std( cell2mat(arrayfun(@(b) b.stimCounts.incorrect(:)', valid_rb, 'UniformOutput',false)), 0, 1);
                    if sum(sc) > eps
                        fill(ax, [bin_centers, fliplr(bin_centers)], [mc-sc, fliplr(mc+sc)], [0 0.65 0], 'FaceAlpha',0.2,'EdgeColor','none');
                    end
                    if sum(si) > eps
                        fill(ax, [bin_centers, fliplr(bin_centers)], [mi-si, fliplr(mi+si)], [0.9 0.2 0.1], 'FaceAlpha',0.2,'EdgeColor','none');
                    end
                end
            end

            plot(ax, bin_centers, counts.correct,   '-o', 'Color', [0 0.65 0],   'LineWidth', 2, 'DisplayName', 'Correct');
            plot(ax, bin_centers, counts.incorrect,  '-o', 'Color', [0.9 0.2 0.1],'LineWidth', 2, 'DisplayName', 'Incorrect');
            xline(ax, config.true_mu, '--k', 'LineWidth', 2, 'HandleVisibility', 'off');
            hold(ax, 'off'); legend(ax, 'Location', 'northwest');
            title(ax, 'Custom Choice Distribution');
            xlabel(ax, 'Stimulus'); ylabel(ax, 'Count');
        catch ME
            warning('RealTimeAnalysis:CustomStimulusHist', '%s', ME.message);
        end
    end

% ---------- CONTEXT PLOT HELPERS ----------

    function plotContextPsychometric(ax, psych_data, config, colors, context_names)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            cla(ax, 'reset'); hold(ax, 'on');
            xGrid = linspace(config.stimuli_range(1), config.stimuli_range(2), 300)';
            xline(ax, config.true_mu, '--k', 'LineWidth', 1.5, 'DisplayName', 'True Boundary');
            yline(ax, 0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
            has_left = false; has_right = false;

            for i = 1:numel(psych_data)
                if isempty(psych_data{i}), continue; end
                if contains(string(psych_data{i}.rule), 'Left', 'IgnoreCase', true), has_left = true;
                else, has_right = true; end
                plot(ax, xGrid, psych_data{i}.y_pred, '-', 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', context_names{i});
                xline(ax, psych_data{i}.fitParams(1), '--', 'Color', colors(i,:), 'LineWidth', 1.5, 'HandleVisibility', 'off');
            end

            if has_left && ~has_right,       ylabel(ax, 'P(Left)');
            elseif ~has_left && has_right,   ylabel(ax, 'P(Right)');
            else,                             ylabel(ax, 'P(Choice)'); end

            grid(ax, 'on'); hold(ax, 'off');
            legend(ax, 'show', 'Location', 'southeast');
            title(ax, 'Contextual Psychometric');
            xlabel(ax, 'Stimulus');
        catch ME
            warning('RealTimeAnalysis:ContextPsych', '%s', ME.message);
        end
    end

    function plotContextHitRates(ax, hit_rate_data, hit_rate_std, colors, context_names)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            cla(ax, 'reset'); hold(ax, 'on');
            if isempty(hit_rate_data), return; end
            num_contexts = size(hit_rate_data, 1);
            num_groups   = size(hit_rate_data, 2);

            b = bar(ax, hit_rate_data', 'grouped');
            for i = 1:min(num_contexts, numel(b))
                b(i).FaceColor = colors(i,:);
            end

            group_width = min(0.8, num_contexts / (num_contexts + 1.5));
            for i = 1:num_contexts
                x_offset = (-(num_contexts-1)/2 + (i-1)) * group_width/num_contexts;
                x_coords = (1:num_groups) + x_offset;
                errorbar(ax, x_coords, hit_rate_data(i,:), hit_rate_std(i,:), ...
                    'k', 'linestyle', 'none', 'CapSize', 4, 'LineWidth', 1);
            end

            ax.XTick = 1:num_groups;
            ax.XTickLabel = {'Overall','Left','Right'};
            ylabel(ax, 'Hit %'); title(ax, 'Contextual Hit Rates');
            ylim(ax, [0 105]); grid(ax, 'on'); hold(ax, 'off');
        catch ME
            warning('RealTimeAnalysis:ContextHitRate', '%s', ME.message);
        end
    end

    function plotContextStimulusHistogram(ax, stim_hist_data, config, colors, context_names)
        if ~ishandle(ax) || ~isvalid(ax), return; end
        try
            cla(ax, 'reset'); hold(ax, 'on');

            for i = 1:numel(stim_hist_data)
                if isempty(stim_hist_data{i}), continue; end
                sd = stim_hist_data{i};

                % Use stored bin edges if available
                if isfield(sd, 'bin_edges') && ~isempty(sd.bin_edges)
                    bin_edges = sd.bin_edges;
                else
                    bin_edges = buildBinEdges(config, []);
                end
                if isempty(bin_edges), continue; end
                bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

                % Guard: length check before plotting std bands
                if isfield(sd, 'mean_corr') && numel(sd.mean_corr) == numel(bin_centers)
                    if isfield(sd, 'std_corr') && sum(sd.std_corr) > eps
                        fill(ax, [bin_centers, fliplr(bin_centers)], ...
                            [sd.mean_corr - sd.std_corr, fliplr(sd.mean_corr + sd.std_corr)], ...
                            colors(i,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                    end
                    if isfield(sd, 'std_incorr') && sum(sd.std_incorr) > eps
                        fill(ax, [bin_centers, fliplr(bin_centers)], ...
                            [sd.mean_incorr - sd.std_incorr, fliplr(sd.mean_incorr + sd.std_incorr)], ...
                            colors(i,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                    end
                end

                if numel(sd.correct) == numel(bin_centers)
                    plot(ax, bin_centers, sd.correct,   '-o',  'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', sprintf('Correct C%d', i));
                    plot(ax, bin_centers, sd.incorrect,  ':x', 'Color', colors(i,:), 'LineWidth', 1.5, 'DisplayName', sprintf('Incorrect C%d', i));
                end
            end

            xline(ax, config.true_mu, '--k', 'LineWidth', 2, 'HandleVisibility', 'off');
            hold(ax, 'off');
            title(ax, 'Contextual Choice Distributions');
            xlabel(ax, 'Stimulus'); ylabel(ax, 'Count');
        catch ME
            warning('RealTimeAnalysis:ContextStimulusHist', '%s', ME.message);
        end
    end

% ==========================================================================
%  GENERAL UTILITY FUNCTIONS
% ==========================================================================

    function eligible = isPsychEligible(stimulus_mode, n_discrete)
        % Returns true if mode and stim count permit psychometric fitting.
        % Full: always eligible.
        % Discrete: eligible when n_discrete >= 2 (giving >= 4 unique stim values total).
        % Fixed Stimuli / No Sound: never eligible.
        try
            switch lower(strtrim(stimulus_mode))
                case 'full'
                    eligible = true;
                case 'discrete'
                    eligible = (n_discrete >= 2);
                otherwise
                    eligible = false;
            end
        catch
            eligible = false;
        end
    end

    function edges = buildBinEdges(config, stim_vals)
        % Builds histogram bin edges appropriate for the current stimulus mode.
        % Full mode: linspace around true_mu.
        % Discrete mode: midpoints between unique observed stimulus values.
        try
            if strcmpi(config.stimulus_mode, 'full') || isempty(stim_vals)
                left_edges  = linspace(min(config.stimuli_range), config.true_mu, 6);
                right_edges = linspace(config.true_mu, max(config.stimuli_range), 6);
                edges = unique([left_edges, right_edges]);
            else
                % Discrete: use actual unique values as bin centers
                unique_stims = sort(unique(stim_vals(~isnan(stim_vals))));
                if numel(unique_stims) < 2
                    edges = []; return;
                end
                gaps  = diff(unique_stims) / 2;
                edges = [unique_stims(1) - gaps(1), ...
                    unique_stims(1:end-1)' + gaps', ...
                    unique_stims(end) + gaps(end)];
            end
        catch
            edges = [];
        end
    end

    function setAxisUnavailableMessage(ax, mode_name)
        % Clears an axis and displays a friendly 'not available' message.
        try
            if ~ishandle(ax) || ~isvalid(ax), return; end
            cla(ax, 'reset');
            text(ax, 0.5, 0.5, sprintf('Not available\nfor %s mode', mode_name), ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', 9, 'Color', [0.5 0.5 0.5]);
            axis(ax, 'off');
        catch
        end
    end

    function relevant = findRelevantBlocks(blockStats, start_idx, end_idx)
        % Returns blockStats entries whose index range falls within [start_idx, end_idx].
        relevant = [];
        if isempty(blockStats), return; end
        for k = 1:numel(blockStats)
            bi = blockStats(k).indices;
            if ~isempty(bi) && min(bi) >= start_idx && max(bi) <= end_idx
                relevant = [relevant, blockStats(k)]; %#ok<AGROW>
            end
        end
    end

    function blockStat = makeEmptyBlockStat(stimulus_mode)
        blockStat.indices       = [];
        blockStat.hitRates      = struct('overall', NaN, 'left', NaN, 'right', NaN);
        blockStat.stimulus_mode = stimulus_mode;
        blockStat.stimCounts    = struct('correct', [], 'incorrect', [], 'bin_edges', []);
        blockStat.fitCurve      = struct('xGrid', [], 'y_pred', []);
        blockStat.fitParams     = [NaN, NaN, NaN, NaN];
    end

    function tableRow = makeEmptyTableRow(config)
        tableRow = {false, string(config.stimulus_mode), '', '', '', NaN, NaN, NaN, ...
            config.true_mu, NaN, NaN, NaN, 'Empty block', NaN, NaN, NaN};
    end

    function dist_type = getDistributionType(data, indices, rule)
        try
            dist_left  = char(mode(categorical(data.full_dist_left(indices))));
            dist_right = char(mode(categorical(data.full_dist_right(indices))));
            hard_dists = {'exponential', 'half-normal', 'sinusoidal'};
            if strcmpi(dist_left, dist_right), dist_type = dist_left; return; end
            is_left_hard  = ismember(lower(dist_left),  hard_dists);
            is_right_hard = ismember(lower(dist_right), hard_dists);
            if contains(string(rule), 'Right', 'IgnoreCase', true)
                if is_right_hard && ~is_left_hard,  dist_type = 'Hard B';
                elseif ~is_right_hard && is_left_hard, dist_type = 'Hard A';
                else, dist_type = 'unknown'; end
            else
                if is_left_hard && ~is_right_hard,  dist_type = 'Hard B';
                elseif ~is_left_hard && is_right_hard, dist_type = 'Hard A';
                else, dist_type = 'unknown'; end
            end
        catch
            dist_type = 'unknown';
        end
    end

    function cmap = createTemporalColormap(n_colors)
        if n_colors == 0, cmap = []; return; end
        if n_colors == 1, cmap = [0.8 0 0]; return; end
        if n_colors <= 5
            cmap = [0.8 0.1 0.1; 0.1 0.5 0.8; 0.1 0.7 0.2; 0.7 0.2 0.7; 0.9 0.6 0.0];
            cmap = cmap(1:n_colors, :);
        else
            h = linspace(0.6, 0, n_colors)';
            s = linspace(0.8, 1, n_colors)';
            v = linspace(0.7, 1, n_colors)';
            cmap = hsv2rgb([h, s, v]);
        end
    end

% ---------- PSYCHOMETRIC FITTING ----------

    function [y_pred, fitParams, methodUsed, fitStatus] = realtimepsychometricFit(stim, resp, rangeStim, options)
        % realtimepsychometricFit Robust real-time psychometric fitting and plotting.
        %
        % This function fits a 4-parameter logistic psychometric function. It includes
        % internal checks for data quality and fitting stability, plus performance
        % optimizations for repeated real-time calls (warm-start, analytic Jacobian).
        %
        % Inputs:
        %   stim        - vector of stimulus values.
        %   resp        - binary response vector (0 or 1).
        %   rangeStim   - 1x2 or 1x3 vector for the stimulus grid [min, max].
        %   options     - (Optional) struct with fields:
        %                 .MinTrials    - Min trials to attempt fit (default: 15).
        %                 .LapseUB      - Upper bound for lapse rates (default: 0.1).
        %                 .StdTol       - Tolerance for stimulus std dev (default: 1e-6).
        %                 .SlopeTol     - Tolerance for slope parameter (default: 1e-5).
        %                 .WarmStart    - [mu, sigma, lapseL, lapseR] from a previous
        %                                 fit on similar data, used to seed lsqcurvefit
        %                                 instead of the ridge/glmfit-derived guess.
        %                                 Validated against current bounds before use;
        %                                 silently ignored if invalid, stale, or absent.
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

        fitParams = [nan,nan,nan,nan];
        y_pred = [];
        fitStatus = 'Success'; % Assume success initially

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

        stim = stim(:);
        resp = resp(:);

        % Strip NaN/Inf entries before any statistics are computed.
        bad = isnan(stim) | isnan(resp) | isinf(stim) | isinf(resp);
        stim = stim(~bad);
        resp = resp(~bad);

        if numel(stim) < options.MinTrials
            methodUsed = 'Fit Canceled';
            fitStatus = sprintf('Insufficient trials (n=%d, min=%d)', numel(stim), options.MinTrials);
            return;
        end

        if std(stim) < options.StdTol
            methodUsed = 'Fit Canceled';
            fitStatus = 'Insufficient stimulus variance';
            return;
        end

        % Require stimuli on both sides of the boundary.
        approx_mu = mean(rangeStim);
        if ~any(stim < approx_mu) || ~any(stim > approx_mu)
            methodUsed = 'Fit Canceled';
            fitStatus = 'Stimuli present on only one side of the boundary';
            return;
        end

        %% 2. Initial Fit (Ridge)
        stim_std = (stim - mean(stim)) / std(stim);
        methodUsed = 'ridge';

        try
            % Standardize=false: stim_std is already z-scored above, so skip the
            % redundant internal re-standardization lassoglm does by default.
            [B, FitInfo] = lassoglm(stim_std, resp, 'binomial', 'Alpha', 1e-6, 'Lambda', 0.1, ...
                'Standardize', false);
            b0 = FitInfo.Intercept;
            b1 = B(1);

            if abs(b1) < options.SlopeTol
                throw(MException('MyFit:ZeroSlope', 'Initial ridge fit found no slope.'));
            end
            if abs(b1) > 10
                throw(MException('MyFit:SteepSlope', 'Initial ridge fit is too steep.'));
            end

            mu = -b0 / b1 * std(stim) + mean(stim);
            sigma = std(stim) / b1;

            predTrain = 1 ./ (1 + exp(-(b0 + b1 * stim_std)));
            lapseEstimate = mean(abs(predTrain - resp));
            lapseL = min(max(lapseEstimate * 1.2, 0), options.LapseUB);
            lapseR = lapseL;

        catch ME
            methodUsed = 'robust';
            fitStatus = sprintf('Switched to glmfit fallback. Reason: %s', ME.message);

            try
                brob = glmfit(stim, resp, 'binomial', 'link', 'logit');

                if abs(brob(2)) < options.SlopeTol
                    methodUsed = 'Fit Failed';
                    fitStatus = 'Could not find a slope with either method.';
                    return;
                end

                mu = -brob(1) / brob(2);
                sigma = 1 / brob(2);
                lapseL = 0.02;
                lapseR = 0.02;
            catch
                methodUsed = 'Fit Failed';
                fitStatus = 'glmfit fallback also failed to converge.';
                return;
            end
        end

        %% 3. Final Nonlinear Fit (lsqcurvefit), warm-started + analytic Jacobian
        stim_min = min(rangeStim);
        stim_max = max(rangeStim);
        range_width = stim_max - stim_min;

        init = [mu, sigma, lapseL, lapseR];
        lb = [stim_min - 0.1*range_width, 0.1, 0, 0];
        ub = [stim_max + 0.1*range_width, 15, options.LapseUB, options.LapseUB];

        % Clamp the ridge/glmfit-derived init into bounds first (used as fallback
        % if WarmStart is absent or invalid).
        init(1) = max(min(init(1), ub(1)), lb(1));
        init(2) = max(min(init(2), ub(2)), lb(2));
        init(3) = max(min(init(3), ub(3)), lb(3));
        init(4) = max(min(init(4), ub(4)), lb(4));

        % --- Warm start: use only if well-formed AND within current bounds. ---
        % Guards against stale params from before a context switch changed
        % rangeStim, or a malformed/missing WarmStart field.
        if isfield(options, 'WarmStart') && numel(options.WarmStart) == 4 && all(isfinite(options.WarmStart))
            ws = double(options.WarmStart(:)');
            ws_valid = ws(1) >= lb(1) && ws(1) <= ub(1) && ...
                ws(2) >= lb(2) && ws(2) <= ub(2) && ...
                ws(3) >= lb(3) && ws(3) <= ub(3) && ...
                ws(4) >= lb(4) && ws(4) <= ub(4);
            if ws_valid
                init = ws;
            end
        end

        % --- Fit with analytic Jacobian; fall back to finite-difference if the
        % gradient-aware call errors for any reason (toolbox version, etc.). ---
        fitSucceeded = false;
        try
            lsqOpts = optimoptions('lsqcurvefit', 'Display', 'off', ...
                'SpecifyObjectiveGradient', true, ...
                'MaxIterations', 50, 'FunctionTolerance', 1e-4, 'StepTolerance', 1e-6);
            fitParams = lsqcurvefit(@psychModelFun, init, stim, resp, lb, ub, lsqOpts);
            fitSucceeded = true;
        catch ME1
            try
                lsqOpts = optimset('Display', 'off');
                fitParams = lsqcurvefit(@(p, x) psychModelFun(p, x), init, stim, resp, lb, ub, lsqOpts);
                fitSucceeded = true;
                fitStatus = sprintf('Gradient-based fit failed (%s); used finite-difference fallback.', ME1.message);
            catch ME2
                methodUsed = 'Fit Failed';
                fitStatus = sprintf('lsqcurvefit failed: %s', ME2.message);
                return;
            end
        end

        if ~fitSucceeded
            methodUsed = 'Fit Failed';
            fitStatus = 'lsqcurvefit did not return a result.';
            return;
        end

        %% 4. Post-Fit Sanity Checks & Prediction
        bound_tolerance = 0.01 * range_width;
        if (fitParams(1) <= lb(1) + bound_tolerance) || (fitParams(1) >= ub(1) - bound_tolerance)
            fitStatus = 'Warning: Threshold is at the edge of the stimulus range.';
            warning('realtimepsychometricFit:threshAtEdge', '%s', fitStatus);
        end

        if (fitParams(3) >= options.LapseUB*0.99) || (fitParams(4) >= options.LapseUB*0.99)
            fitStatus = 'Warning: Lapse rate may be underestimated (at upper bound).';
            warning('realtimepsychometricFit:lapseAtBound', '%s', fitStatus);
        end

        xGrid = linspace(stim_min, stim_max, 300)';
        y_pred = psychModelFun(fitParams, xGrid);

    end

% ==========================================================================
    function [F, J] = psychModelFun(p, x)
        % 4-parameter logistic psychometric function with analytic Jacobian.
        % F = p3 + (1 - p3 - p4) / (1 + exp(-(x-p1)/p2))
        % Supplying J avoids MATLAB's default finite-difference Jacobian, which
        % costs several extra function evaluations per lsqcurvefit iteration.
        z = (x - p(1)) ./ p(2);
        s = 1 ./ (1 + exp(-z));
        F = p(3) + (1 - p(3) - p(4)) .* s;

        if nargout > 1
            w  = (1 - p(3) - p(4));
            sd = s .* (1 - s);
            J = zeros(numel(x), 4);
            J(:,1) = -w .* sd ./ p(2);                    % dF/dmu
            J(:,2) = -w .* sd .* (x - p(1)) ./ (p(2)^2);   % dF/dsigma
            J(:,3) = 1 - s;                                % dF/dlapseL
            J(:,4) = -s;                                   % dF/dlapseR
        end
    end

end % end main function