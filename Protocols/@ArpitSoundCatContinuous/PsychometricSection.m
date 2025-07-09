function varargout = PsychometricSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------

    case 'init'
        if length(varargin) < 2
            error('Need at least two arguments, x and y position, to initialize %s', mfilename);
        end
        x = varargin{1}; y = varargin{2};

        % Display on the main GUI

        % Context 1
        DispParam(obj, 'Context3_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','t_start','TooltipString','3rd context started at this trial');
        DispParam(obj, 'Context3_trialEnd', 1,x,y, 'position', [x + 101, y, 100 20],'label','t_end','TooltipString','3rd context ended at this trial')
        next_row(y);
        DispParam(obj, 'Context3_Dist', Category_Dist, x,y,'label','Context3_Distr','TooltipString','stim distribution for 3rd context');
        make_invisible(Context3_Dist); make_invisible(Context3_trialStart);make_invisible(Context3_trialEnd);
        next_row(y);
        
        % Context 2
        DispParam(obj, 'Context2_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','t_start','TooltipString','2nd context started at this trial');
        DispParam(obj, 'Context2_trialEnd', 1,x,y, 'position', [x + 101, y, 100 20],'label','t_end','TooltipString','2nd context ended at this trial')
        next_row(y);
        DispParam(obj, 'Context2_Dist', Category_Dist, x,y,'label','Context2_Distr','TooltipString','stim distribution for 2nd context');    	
        make_invisible(Context2_Dist); make_invisible(Context2_trialStart);make_invisible(Context2_trialEnd);
        next_row(y);
        
        % Context 3
        DispParam(obj, 'Context1_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','Trial_start','TooltipString','1st context started at this trial');
        DispParam(obj, 'Context1_trialEnd', 1,x,y, 'position', [x +  101, y, 100 20],'label','Trial_end','TooltipString','1st context ended at this trial')        
        next_row(y);
        DispParam(obj, 'Context1_Dist', Category_Dist, x,y,'label','Context1_Distr','TooltipString','stim distribution for 1st context');
    	next_row(y);
       
        PushbuttonParam(obj, 'Switch_Distr', x, y, 'label', 'Change Stim Distribution','TooltipString', 'Change the context by switching distribution');
        set_callback(Switch_Distr, {mfilename, 'PushButton_Distribution_Switch'}); %#ok<NODEF> (Defined just above)
        next_row(y,2)
        NumeditParam(obj,'trial_plot',30,x,y,'label','Trails 2 Plot','TooltipString','update psychometric curve after these many valid trials');
        next_row(y);
        ToggleParam(obj, 'PsychometricShow', 0, x, y, 'OnString', 'Psychometric Show', ...
            'OffString', 'Psychometric Hidden', 'TooltipString', 'Show/Hide Psychometric panel');
        set_callback(PsychometricShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
        next_row(y);
        SubheaderParam(obj, 'title', 'Psychometric Section', x, y);next_row(y);

        oldx=x; oldy=y;    parentfig=double(gcf);

        % SoloParams
        SoloParamHandle(obj, 'thiscontext', 'value', 1);
        SoloParamHandle(obj, 'last_trial_plotted', 'value', 0);
        vars = ["Select","Rule","Distribution","Start_trial","End_trial","Slope","TrueBoundary",...
            "CalBoundary","LapseA","LapseB","fit_Method", "Pred_Y"];
        vars_type = ["logical","string","string","double","double","double","double","double",...
            "double","double","string","cell"];
        t = table('Size', [0, numel(vars)], ...
                       'VariableTypes', vars_type, ...
                       'VariableNames', vars);
        SoloParamHandle(obj, 'TableData', 'value', t);

        % New Fig Window to show the Psychometric Curves
        SoloParamHandle(obj, 'myfig', 'value', uifigure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'],...
             'Name', mfilename, 'Units', 'normalized','Visible', 'off'), 'saveable', false);

        % Panel for Table
        hndl_uipanelTable = uipanel('Units', 'normalized','Parent', value(myfig), ...
                'Title', 'Psychometric Summary', ...
                'Tag', 'uipanelTable', ...
                'Position', [0.06,0.2,0.4,0.75]);
        SoloParamHandle(obj, 'uit','value', uitable(hndl_uipanelTable,'Units', 'normalized','Data',value(TableData),...
            'ColumnSortable', true,'Position',[0.02 0.02 0.95 0.95],...
            'ColumnEditable', [true, false, false, false, false, false,false, false, false, false, false,false]),'savable',false);

        % Panel for Axes
        hndl_uipanelAxes = uipanel('Units', 'normalized','Parent', value(myfig), ...
                'Title', 'Psychometric Plots', ...
                'Tag', 'uipanelplot', ...
                'Position', [0.5,0.05,0.4,0.9]);
        SoloParamHandle(obj, 'axplot1', 'value', axes(hndl_uipanelAxes,'Units', 'normalized','Position', [0.1,0.53, ...
            0.8,0.43]), 'saveable', false);
        ylabel('Prob A','FontSize',8,'FontName','Cambria Math');

        SoloParamHandle(obj, 'axplot2', 'value', axes(hndl_uipanelAxes,'Units', 'normalized','Position', [0.1,0.05, ...
            0.8,0.43]), 'saveable', false);
        xlabel('Stim','FontSize',8,'FontName','Cambria Math');
        ylabel('Prob A','FontSize',8,'FontName','Cambria Math');

        % Creating a new figure for Push button and edit box because they
        % are based upon Java, so they wont plot on uifig which is web
        % based

        % New Fig Window to show the Psychometric Curves
        SoloParamHandle(obj, 'myfig1', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'],...
             'MenuBar', 'none','Name', mfilename, 'Units', 'normalized','Visible', 'off'), 'saveable', false);

        % Edit and Push Button for Psych Plots
        if ~exist('Plot_Trial_Start', 'var') || ~isa(Plot_Trial_Start, 'SoloParamHandle')
            NumeditParam(obj, 'Plot_Trial_Start', 1, 1, 1,'label','Trial Start','labelpos','top');
        end
        if ~exist('Plot_Trial_End', 'var') || ~isa(Plot_Trial_End, 'SoloParamHandle')
            NumeditParam(obj, 'Plot_Trial_End', 1, 1, 1,'label','Trial End','labelpos','top');
        end
        if ~exist('Plot_Selected', 'var') || ~isa(Plot_Selected, 'SoloParamHandle')
            PushbuttonParam(obj, 'Plot_Selected', 1, 1);
            set_callback(Plot_Selected, {mfilename, 'PushButton_SelectedTrial'});
        end
        if ~exist('Plot_Context', 'var') || ~isa(Plot_Context, 'SoloParamHandle')
            PushbuttonParam(obj, 'Plot_Context', 1, 1);
            set_callback(Plot_Context, {mfilename, 'PushButton_Context'});
        end

        hndl_uipanelSettings = uipanel('Units', 'normalized','Parent', value(myfig1), ...
                'Title', 'Plot Variables', ...
                'Tag', 'uipanelsetting', ...
                'Position', [0.02,0.02,0.9,0.9]);
        
        set(get_ghandle(Plot_Trial_Start), ...
            'Parent', hndl_uipanelSettings, ...
            'Units', 'normalized', ...
            'Tag', 'trial_start', ...
            'TooltipString', 'trial start for plot', ...
            'FontSize', 10.0, ...
            'Position', [0.02,0.5,0.15,0.2]);
        delete(get_lhandle(Plot_Trial_Start));

        set(get_ghandle(Plot_Trial_End), ...
            'Parent', hndl_uipanelSettings, ...
            'Units', 'normalized', ...
            'Tag', 'trial_end', ...
            'TooltipString', 'trial end for plot', ...
            'FontSize', 10.0, ...
            'Position', [0.28,0.5,0.15,0.2]);
        delete(get_lhandle(Plot_Trial_End));

        set(get_ghandle(Plot_Selected), ...
            'Parent', hndl_uipanelSettings, ...
            'Units', 'normalized', ...
            'Tag', 'plotselected_trials', ...
            'Position', [0.04,0.05,0.4,0.4]);
        delete(get_lhandle(Plot_Selected));

        set(get_ghandle(Plot_Context), ...
            'Parent', hndl_uipanelSettings, ...
            'Units', 'normalized', ...
            'Tag', 'plot_context', ...
            'Position', [0.55,0.05,0.4,0.4]);
        delete(get_lhandle(Plot_Context));

        % Edit and Push Button for Psych Plots
        % NumeditParam(obj,'Plot_Trial_Start',1,50,100,'position',[5,10,100,20],'label','Trial Start','labelpos','top');        
        % NumeditParam(obj,'Plot_Trial_End',1,150,100,'position',[150,10,100,20],'label','Trial End','labelpos','top');
        % PushbuttonParam(obj, 'Plot_Selected', 300, 20, 'label', 'Plot Selected Trials','TooltipString', 'Change the context by switching distribution');
        % set_callback(Plot_Selected, {mfilename, 'PushButton_SelectedTrial'});
        % PushbuttonParam(obj, 'Plot_Context', 300, 40, 'label', 'Plot Context','TooltipString', 'Change the context by switching distribution');
        % set_callback(Switch_Distr, {mfilename, 'PushButton_Context'});
        
        varargout{1} = x;
        varargout{2} = y;

    case 'PushButton_Distribution_Switch'

        % eval(sprintf('present_context_dist = value(Context%i_Dist)',value(thiscontext)));
        eval(sprintf('present_context_start = value(Context%i_trialStart);',value(thiscontext)));
        eval(sprintf('present_context_end = value(Context%i_trialEnd);',value(thiscontext)));
        
        if ~strcmpi(Category_Dist,'Uniform') && present_context_end > present_context_start
            
            if value(thiscontext) < 3 % & ~strcmpi(present_context_dist,Category_Dist)
                thiscontext.value = value(thiscontext) + 1;
                eval(sprintf('Context%i_Dist.value = Category_Dist;',value(thiscontext)));
                eval(sprintf('Context%i_trialStart.value = n_done_trials + 1;',value(thiscontext)));
                eval(sprintf('Context%i_trialEnd.value = n_done_trials + 1;',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_Dist);',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_trialStart);',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_trialEnd);',value(thiscontext)));
            end

            if strcmpi(Category_Dist,'Hard A')
                StimulusSection(obj,'Pushbutton_SwitchDistribution','Hard B');
            elseif strcmpi(Category_Dist,'Hard B')
                StimulusSection(obj,'Pushbutton_SwitchDistribution','Hard A');
            end
        end
         
    case 'StimSection_Distribution_Switch'
        
        eval(sprintf('present_context_start = value(Context%i_trialStart);',value(thiscontext)));
        eval(sprintf('present_context_end = value(Context%i_trialEnd);',value(thiscontext)));
        
        if present_context_end > present_context_start
            if value(thiscontext) < 3 % & ~strcmpi(present_context_dist,Category_Dist)
                thiscontext.value = value(thiscontext) + 1;
                eval(sprintf('Context%i_Dist.value = Category_Dist;',value(thiscontext)));
                eval(sprintf('Context%i_trialStart.value = n_done_trials + 1;',value(thiscontext)));
                eval(sprintf('Context%i_trialEnd.value = n_done_trials + 1;',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_Dist);',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_trialStart);',value(thiscontext)));
                eval(sprintf('make_visible(Context%i_trialEnd);',value(thiscontext)));
            end
        else
            eval(sprintf('Context%i_Dist.value = Category_Dist;',value(thiscontext)));
        end

    case 'PushButton_SelectedTrial'
        try
            stim2analyze = stimulus_history(value(Plot_Trial_Start):value(Plot_Trial_End));
            sides2analyze = previous_sides(value(Plot_Trial_Start):value(Plot_Trial_End));
            hit_history2analyze = hit_history(value(Plot_Trial_Start):value(Plot_Trial_End));
            category_distribution2analyze = stimulus_distribution_history(value(Plot_Trial_Start):value(Plot_Trial_End));
            valid_hit_history_trials = find(~isnan(hit_history2analyze));
            sides = sides2analyze(valid_hit_history_trials);
            stim = stim2analyze(valid_hit_history_trials);
            category_distribution = category_distribution2analyze(valid_hit_history_trials);
            hit_values = hit_history2analyze(valid_hit_history_trials)';
            resp = zeros(size(hit_values));

            if strcmpi(Rule,'S1>S_boundary Left') % Category B is Left so its value is 1
                resp((sides == 108 & hit_values == 1) | (sides == 114 & hit_values == 0)) = 1;
            else % Category B is Right so its value is 1
                resp((sides == 114 & hit_values == 1) | (sides == 108 & hit_values == 0)) = 1;
            end

            Stim_Params = StimulusSection(obj,'stim_params');
            try
                [y_pred, fitParams, methodUsed,fitStatus] = realtimepsychometricFit(stim,resp,Stim_Params);
            catch
                y_pred =[];
                fitParams = [nan,nan,nan,nan];
                methodUsed = "Failed";
                fitStatus = "";
            end
            % Update the Table
            

            % Convert category string with comma separator
            category = unique(category_distribution);
            category_selected = strjoin(category, ',');

            variableNames = ["Select","Rule","Distribution","Start_trial","End_trial","Slope","TrueBoundary",...
                "CalBoundary","LapseA","LapseB","fit_Method", "Pred_Y"];
            newRow = table(false,string(Rule),string(category_selected),value(Plot_Trial_Start),value(Plot_Trial_End),...
                fitParams(2),Stim_Params(2),fitParams(1),fitParams(3),fitParams(4),string(methodUsed) + " (" + fitStatus + ")",...
                {y_pred},'VariableNames', variableNames);
            t_new = [value(TableData);newRow];
            TableData.value = t_new;
            t_handle = value(uit);
            t_handle.Data = t_new;

            % Plot the Psychometric
            xGrid = linspace(Stim_Params(1), Stim_Params(3), 300)';
            cla(value(axplot2))
            hold (value(axplot2),'on')
            if ~(contains(methodUsed,'Failed') || contains(methodUsed,'Canceled'))
                plot(value(axplot2),xGrid, y_pred, 'b-', 'LineWidth', 2);
                xline(value(axplot2),fitParams(1), 'g--', sprintf('PSE (%.2f)', fitParams(1)));
            end
            xline(value(axplot2),Stim_Params(2), 'r--', 'Boundary');
            ylim([-0.05, 1.05]);
            xlabel('Stimulus (dB)');
            ylabel('P("Category B" Response)');
            grid on;
        catch
        end
    case 'PushButton_Context'
        try
            Stim_Params = StimulusSection(obj,'stim_params');
            xGrid = linspace(Stim_Params(1), Stim_Params(3), 300)';
            cla(value(axplot2));
            hold (value(axplot2),'on')
            
            colors_to_use = createTemporalColormap(value(thiscontext));

            for n_plot = 1:value(thiscontext)

                eval(sprintf('trial_start = value(Context%i_trialStart);',n_plot));
                eval(sprintf('trial_end = value(Context%i_trialEnd);',n_plot));
                stim2analyze = stimulus_history(trial_start:trial_end);
                sides2analyze = previous_sides(trial_start:trial_end);
                hit_history2analyze = hit_history(trial_start:trial_end);
                category_distribution2analyze = stimulus_distribution_history(trial_start:trial_end);          
                valid_hit_history_trials = find(~isnan(hit_history2analyze));
                sides = sides2analyze(valid_hit_history_trials);
                stim = stim2analyze(valid_hit_history_trials);
                category_distribution = category_distribution2analyze(valid_hit_history_trials);
                hit_values = hit_history2analyze(valid_hit_history_trials)';
                resp = zeros(size(hit_values));

                if strcmpi(Rule,'S1>S_boundary Left') % Category B is Left so its value is 1
                    resp((sides == 108 & hit_values == 1) | (sides == 114 & hit_values == 0)) = 1;
                else % Category B is Right so its value is 1
                    resp((sides == 114 & hit_values == 1) | (sides == 108 & hit_values == 0)) = 1;
                end

                try
                    [y_pred, fitParams, methodUsed,fitStatus] = realtimepsychometricFit(stim,resp,Stim_Params);
                catch
                    y_pred =[];
                    fitParams = [nan,nan,nan,nan];
                    methodUsed = "Failed";
                    fitStatus = "";
                end
                % Update the Table
                            
                % Convert category string with comma separator
                category = unique(category_distribution);
                category_selected = strjoin(category, ',');
                variableNames = ["Select","Rule","Distribution","Start_trial","End_trial","Slope","TrueBoundary",...
                    "CalBoundary","LapseA","LapseB","fit_Method", "Pred_Y"];
                newRow = table(false,string(Rule),string(category_selected),trial_start,trial_end,...
                    fitParams(2),Stim_Params(2),fitParams(1),fitParams(3),fitParams(4),string(methodUsed) + " (" + fitStatus + ")",...
                    {y_pred},'VariableNames', variableNames);
                t_new = [value(TableData);newRow];
                TableData.value = t_new;
                t_handle = value(uit);
                t_handle.Data = t_new;

                % Plot the Psychometric
                if ~(contains(methodUsed,'Failed') || contains(methodUsed,'Canceled'))
                    plot(value(axplot2),xGrid, y_pred, 'Color', colors_to_use(n_plot, :), 'LineWidth', 2,'DisplayName',sprintf('Context %s',category_selected));
                    xline(value(axplot2),fitParams(1), '--','Color', colors_to_use(n_plot, :), 'Label', sprintf('PSE (%.2f)', fitParams(1)));
                end

            end

            xline(value(axplot2),Stim_Params(2), 'r--', 'Boundary');
            ylim([-0.05, 1.05]);
            xlabel('Stimulus (dB)');
            ylabel('P("Category B" Response)');
            grid on;
        catch
        end

    %%update after each trial    
    case 'update'
        % update the trial end for this context
        if n_done_trials > 1
            eval(sprintf('Context%i_trialEnd.value = n_done_trials;',value(thiscontext)));

            try
                % Check to see if we need to plot the Psychometric Curve
                n_trials_valid = numel(find(~isnan(hit_history)));

                if n_trials_valid >= value(trial_plot) && n_trials_valid > value(last_trial_plotted) % means we may plot the psychometric
                    if n_trials_valid - value(last_trial_plotted) >= value(trial_plot)

                        Stim_Params = StimulusSection(obj,'stim_params');
                        sides2analyze = previous_sides(value(last_trial_plotted) + 1: n_done_trials);
                        stim2analyze = stimulus_history(value(last_trial_plotted) + 1: n_done_trials);
                        hit_history2analyze = hit_history(value(last_trial_plotted) + 1: n_done_trials);
                        category_distribution2analyze = stimulus_distribution_history(value(last_trial_plotted) + 1: n_done_trials);
                        trial2_analyze = find(~isnan(hit_history2analyze));
                        stim = stim2analyze(trial2_analyze);
                        sides = sides2analyze(trial2_analyze);
                        category_distribution = category_distribution2analyze(trial2_analyze);
                        hit_values = hit_history2analyze(trial2_analyze)';
                        resp = zeros(size(hit_values));

                        if strcmpi(Rule,'S1>S_boundary Left') % Category B is Left so its value is 1
                            resp((sides == 108 & hit_values == 1) | (sides == 114 & hit_values == 0)) = 1;
                        else % Category B is Right so its value is 1
                            resp((sides == 114 & hit_values == 1) | (sides == 108 & hit_values == 0)) = 1;
                        end

                        % The psychometric Fit
                        try
                            [y_pred, fitParams, methodUsed,fitStatus] = realtimepsychometricFit(stim,resp,Stim_Params);
                        catch
                            y_pred =[];
                            fitParams = [nan,nan,nan,nan];
                            methodUsed = "Failed";
                            fitStatus = "";
                        end
                        % Update the Table

                        % Based upon fit result we decide whether to plot
                        % psychometric or not

                        % Determine the 'Select' status based on fit success
                        select_status = ismember(methodUsed, {'ridge', 'robust'});

                        variableNames = ["Select","Rule","Distribution","Start_trial","End_trial","Slope","TrueBoundary",...
                            "CalBoundary","LapseA","LapseB","fit_Method", "Pred_Y"];

                        % Convert category string with comma separator
                        category = unique(category_distribution);
                        category_selected = strjoin(category, ',');

                        if select_status
                            newRow = table(select_status,string(Rule),string(category_selected),value(last_trial_plotted) + 1,n_done_trials,...
                                fitParams(2),Stim_Params(2),fitParams(1),fitParams(3),fitParams(4),string(methodUsed) + " (" + fitStatus + ")",...
                                {y_pred},'VariableNames', variableNames);
                        else
                            newRow = table(select_status,string(Rule),string(category_selected),value(last_trial_plotted) + 1,n_done_trials,...
                                nan,Stim_Params(2),nan,nan,nan,string(methodUsed) + " (" + fitStatus + ")",...
                                {[]},'VariableNames', variableNames);
                        end

                        t_new = [value(TableData); newRow];
                        TableData.value = t_new;
                        t_handle = value(uit);
                        t_handle.Data = t_new;

                        % Identify the user selected trials (usually the one
                        % plotted realtime and not by user)
                        selectedData = t_new(t_new.Select, :);
                        xGrid = linspace(Stim_Params(1), Stim_Params(3), 300)';
                        cla(value(axplot1));
                        hold (value(axplot1),'on');

                        if ~isempty(selectedData)
                            % plot the selected Psychometric
                            num_to_plot = height(selectedData);
                            colors_to_use = createTemporalColormap(num_to_plot);
                            for i = 1:num_to_plot
                                % Get parameters for the i-th selected row
                                plot_data_matrix = selectedData.Pred_Y{i};
                                if isempty(plot_data_matrix), continue; end
                                y_data = plot_data_matrix(:);
                                % Plot the curve using the generated color
                                plot(value(axplot1), xGrid, y_data, ...
                                    'Color', colors_to_use(i, :), ...
                                    'LineWidth', 2, ...
                                    'DisplayName', sprintf('Fit %d (Trials %d-%d)', i, selectedData.Start_trial(i), selectedData.End_trial(i)));
                                if i == num_to_plot
                                    xline(value(axplot1),fitParams(1), 'g--', sprintf('PSE (%.2f)', fitParams(1)));
                                end
                            end
                            % else
                            %     % Plot the recently calculated Psychometric
                            %     plot(value(axplot1),xGrid, y_pred, 'b-', 'LineWidth', 2); hold on;
                        end

                        xline(value(axplot1),Stim_Params(2), 'r--', 'Boundary');
                        ylim([-0.05, 1.05]);
                        xlabel('Stimulus (dB)');
                        ylabel('P("Category B" Response)');
                        grid on;
                        legend(value(axplot1),'show','Location','southeast')
                        hold (value(axplot1),'off');

                        last_trial_plotted.value = n_done_trials;
                    end
                end

            catch
            end
        end

        %% Case close
    case 'close'
        set(value(myfig), 'Visible', 'off');
        set(value(myfig1), 'Visible', 'off');
        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        if exist('myfig1', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig1)) %#ok<NODEF>
            delete(value(myfig1));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

        %% Case hide
    case 'hide'
        PsychometricShow.value = 0;
        set(value(myfig), 'Visible', 'off');
        set(value(myfig1), 'Visible', 'off');

         %% Case Show_hide
    case 'show_hide'
        if PsychometricShow == 1
            set(value(myfig), 'Visible', 'on'); 
            set(value(myfig1), 'Visible', 'on'); 
        else
            set(value(myfig), 'Visible', 'off');
            set(value(myfig1), 'Visible', 'on'); 
        end

end

end