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

        % Context display widgets (3 max)
        DispParam(obj, 'Context3_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','t_start','TooltipString','3rd context started at this trial');
        DispParam(obj, 'Context3_trialEnd', 1,x,y, 'position', [x + 101, y, 100 20],'label','t_end','TooltipString','3rd context ended at this trial');
        next_row(y);
        DispParam(obj, 'Context3_Dist', Category_Dist, x,y,'label','Context3_Distr','TooltipString','stim distribution/mode for 3rd context');
        make_invisible(Context3_Dist); make_invisible(Context3_trialStart); make_invisible(Context3_trialEnd);
        next_row(y);

        DispParam(obj, 'Context2_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','t_start','TooltipString','2nd context started at this trial');
        DispParam(obj, 'Context2_trialEnd', 1,x,y, 'position', [x + 101, y, 100 20],'label','t_end','TooltipString','2nd context ended at this trial');
        next_row(y);
        DispParam(obj, 'Context2_Dist', Category_Dist, x,y,'label','Context2_Distr','TooltipString','stim distribution/mode for 2nd context');
        make_invisible(Context2_Dist); make_invisible(Context2_trialStart); make_invisible(Context2_trialEnd);
        next_row(y);

        DispParam(obj, 'Context1_trialStart', 1,x,y, 'position', [x, y, 100 20],'label','Trial_start','TooltipString','1st context started at this trial');
        DispParam(obj, 'Context1_trialEnd', 1,x,y, 'position', [x + 101, y, 100 20],'label','Trial_end','TooltipString','1st context ended at this trial');
        next_row(y);
        DispParam(obj, 'Context1_Dist', Category_Dist, x,y,'label','Context1_Distr','TooltipString','stim distribution/mode for 1st context');
        next_row(y);

        PushbuttonParam(obj, 'Switch_Distr', x, y, 'label', 'Change Stim Distribution', ...
            'TooltipString', 'Change the context by switching distribution (Full mode only)');
        set_callback(Switch_Distr, {mfilename, 'PushButton_Distribution_Switch'});
        next_row(y,2);
        NumeditParam(obj,'trial_plot',30,x,y,'label','Trials 2 Plot','TooltipString','Update plots after these many valid trials');
        next_row(y);
        ToggleParam(obj, 'PsychometricShow', 0, x, y, 'OnString', 'Psychometric Show', ...
            'OffString', 'Psychometric Hidden', 'TooltipString', 'Show/Hide analysis panel');
        set_callback(PsychometricShow, {mfilename, 'show_hide'});
        next_row(y);
        SubheaderParam(obj, 'title', 'Psychometric Section', x, y); next_row(y);

        oldx = x; oldy = y; parentfig = double(gcf);

        % --- State management struct ---
        state.last_analyzed_valid_trial = 0;
        state.block_count               = 0;
        state.context_blocks            = 0;
        state.table_row_editable        = [];
        % blockStatsHistory entries now include stimulus_mode and bin_edges fields
        % case 'init':
        state.blockStatsHistory = struct('indices', {}, 'hitRates', {}, 'stimCounts', {}, ...
            'stimulus_mode', {}, 'fitCurve', {}, 'fitParams', {});
        % Mode tracking
        state.last_stable_mode          = 'Full';
        % Pending switch struct: supports accidental-state-change detection
        state.pending_switch.active      = false;
        state.pending_switch.from_mode   = '';
        state.pending_switch.to_mode     = '';
        state.pending_switch.start_trial = NaN;
        state.pending_switch.trial_count = 0;

        SoloParamHandle(obj, 'states_value', 'value', state);
        SoloParamHandle(obj, 'thiscontext',  'value', 1);
        SoloParamHandle(obj, 'last_trial_plotted', 'value', 0);

        % --- Table schema: added Stimulus_Mode column ---
        vars = ["Select","Stimulus_Mode","Rule","DistributionLeft","DistributionRight", ...
                "Start_trial","End_trial","Slope","TrueBoundary","CalBoundary", ...
                "LapseA","LapseB","fit_Method","Overall Hit %","Left Hit %","Right Hit %"];
        vars_type = ["logical","string","string","string","string", ...
                     "double","double","double","double","double", ...
                     "double","double","string","double","double","double"];
        t = table('Size', [0, numel(vars)], 'VariableTypes', vars_type, 'VariableNames', vars);

        % --- Main analysis figure ---
        SoloParamHandle(obj, 'myfig', 'value', figure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], ...
            'Name', 'Real-Time Analysis', 'Units', 'normalized', ...
            'Position', [0.3, 0.1, 0.6, 0.8], 'Visible', 'off'), 'saveable', false);

        % Pre-define controls (must be created before panels reparent them)
        NumeditParam(obj, 'Plot_Trial_Start', 1,  1, 1, 'TooltipString', 'Start trial for custom plot');
        NumeditParam(obj, 'Plot_Trial_End',   30, 1, 1, 'TooltipString', 'End trial for custom plot');
        ToggleParam(obj,  'Show_Table_Toggle', 0, 1, 1, 'OnString', 'Table Shown', 'OffString', 'Show Table');
        PushbuttonParam(obj, 'Plot_Custom_Button', 1, 1, 'label', 'Plot Custom Range');
        PushbuttonParam(obj, 'Plot_Context_Button', 1, 1, 'label', 'Plot Context');

        % --- Panels ---
        hndl_live_plots_panel = uipanel('Parent', value(myfig), 'Title', 'Live Update Plots', ...
            'Units', 'normalized', 'Position', [0.05, 0.55, 0.9, 0.43]);
        hndl_custom_plots_panel = uipanel('Parent', value(myfig), 'Title', 'Custom Range Plots', ...
            'Units', 'normalized', 'Position', [0.05, 0.2, 0.9, 0.33]);
        hndl_controls_panel = uipanel('Parent', value(myfig), 'Title', 'Controls', ...
            'Units', 'normalized', 'Position', [0.05, 0.02, 0.9, 0.16]);

        % --- Axes ---
        axes_h.live_psych   = axes('Parent', hndl_live_plots_panel, 'Units', 'normalized', 'Position', [0.06, 0.1, 0.28, 0.8]);
        title(axes_h.live_psych, 'Live Psychometric'); ylabel(axes_h.live_psych, 'P(Right)');
        axes_h.live_hitrate = axes('Parent', hndl_live_plots_panel, 'Units', 'normalized', 'Position', [0.38, 0.1, 0.28, 0.8]);
        title(axes_h.live_hitrate, 'Live Hit Rate'); xlabel(axes_h.live_hitrate, 'Block');
        axes_h.live_stim    = axes('Parent', hndl_live_plots_panel, 'Units', 'normalized', 'Position', [0.7,  0.1, 0.28, 0.8]);
        title(axes_h.live_stim, 'Live Stimulus Dist.');
        axes_h.custom_psych   = axes('Parent', hndl_custom_plots_panel, 'Units', 'normalized', 'Position', [0.06, 0.1, 0.28, 0.8]);
        title(axes_h.custom_psych, 'Custom Psychometric'); ylabel(axes_h.custom_psych, 'P(Right)');
        axes_h.custom_hitrate = axes('Parent', hndl_custom_plots_panel, 'Units', 'normalized', 'Position', [0.38, 0.1, 0.28, 0.8]);
        title(axes_h.custom_hitrate, 'Custom Hit Rate');
        axes_h.custom_stim    = axes('Parent', hndl_custom_plots_panel, 'Units', 'normalized', 'Position', [0.7,  0.1, 0.28, 0.8]);
        title(axes_h.custom_stim, 'Custom Stimulus Dist.');

        SoloParamHandle(obj, 'PlotAxes', 'value', axes_h, 'saveable', false);

        % --- Arrange controls in bottom panel ---
        set(get_ghandle(Show_Table_Toggle), 'Parent', hndl_controls_panel, 'Units', 'normalized', 'Position', [0.03, 0.25, 0.18, 0.5]);
        uicontrol('Parent', hndl_controls_panel, 'Style','text', 'String','Start Trial', 'Units','normalized', 'Position',[0.25, 0.7, 0.1, 0.2]);
        set(get_ghandle(Plot_Trial_Start), 'Parent', hndl_controls_panel, 'Units', 'normalized', 'Position', [0.35, 0.65, 0.1, 0.3]);
        delete(get_lhandle(Plot_Trial_Start));
        uicontrol('Parent', hndl_controls_panel, 'Style','text', 'String','End Trial', 'Units','normalized', 'Position',[0.47, 0.7, 0.1, 0.2]);
        set(get_ghandle(Plot_Trial_End), 'Parent', hndl_controls_panel, 'Units', 'normalized', 'Position', [0.57, 0.65, 0.1, 0.3]);
        delete(get_lhandle(Plot_Trial_End));
        set(get_ghandle(Plot_Custom_Button),  'Parent', hndl_controls_panel, 'Units', 'normalized', 'Position', [0.35, 0.15, 0.22, 0.4]);
        set(get_ghandle(Plot_Context_Button), 'Parent', hndl_controls_panel, 'Units', 'normalized', 'Position', [0.68, 0.25, 0.18, 0.5]);

        SoloParamHandle(obj, 'Update_Psychometric', 'value', uicontrol('Parent', hndl_controls_panel, 'Style', 'checkbox', 'Units', 'normalized', 'String', 'Psych',   'Value', 1, 'Position', [0.9, 0.65, 0.08, 0.3]), 'saveable', false);
        SoloParamHandle(obj, 'Update_HitRate',      'value', uicontrol('Parent', hndl_controls_panel, 'Style', 'checkbox', 'Units', 'normalized', 'String', 'HitRate', 'Value', 1, 'Position', [0.9, 0.35, 0.08, 0.3]), 'saveable', false);
        SoloParamHandle(obj, 'Update_Stimulus',     'value', uicontrol('Parent', hndl_controls_panel, 'Style', 'checkbox', 'Units', 'normalized', 'String', 'Stim',    'Value', 1, 'Position', [0.9, 0.05, 0.08, 0.3]), 'saveable', false);

        set_callback(Show_Table_Toggle,   {mfilename, 'show_hide_table'});
        set_callback(Plot_Custom_Button,  {mfilename, 'PushButton_SelectedTrial'});
        set_callback(Plot_Context_Button, {mfilename, 'PushButton_Context'});

        % --- Table figure (separate window) ---
        SoloParamHandle(obj, 'myfig_table', 'value', uifigure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide_table'');'], ...
            'Name', 'Psychometric Summary Table', 'Units', 'normalized', ...
            'Visible', 'off', 'Position', [0.1, 0.2, 0.4, 0.6]), 'saveable', false);

        SoloParamHandle(obj, 'uit', 'value', uitable(value(myfig_table), 'Data', t, ...
            'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
            'ColumnEditable', [true, repmat(false, 1, numel(vars)-1)], ...
            'CellEditCallback', @(src, evt) PsychometricSection(obj, 'check_box_table', src, evt)), ...
            'saveable', true);

        SoloFunctionAddVars('SideSection', 'rw_args', {'Switch_Distr'});

        varargout{1} = oldx;
        varargout{2} = oldy;

    % ------------------------------------------------------------------
    %              CALCULATE PARAMS
    % ------------------------------------------------------------------
    case 'Calculate_Params'
        try
            % Convert ASCII side codes to 0/1.
            % 'r' (ASCII 114) -> 1 (right), everything else -> 0 (left).
            % After this, sides can only ever be 0 or 1 — no further masking needed.
            sides = zeros(size(previous_sides));
            sides(previous_sides == 114) = 1;

            n = n_done_trials;
            data.hit_history       = hit_history(1:n);
            data.previous_sides    = sides(1:n);
            data.stim_history      = stimulus_history(1:n);
            data.full_rule_history = Rule;
            data.full_dist_right   = stimulus_right_distribution_history(1:n);
            data.full_dist_left    = stimulus_left_distribution_history(1:n);

            handles.ui_table  = value(uit);
            handles.main_fig  = value(myfig);
            handles.axes_h    = value(PlotAxes);

            % Guard: validate StimulusSection output before indexing
            Stim_Params = StimulusSection(obj, 'stim_params');
            if isempty(Stim_Params) || numel(Stim_Params) < 3
                error('StimulusSection:InvalidParams', 'stim_params returned fewer than 3 elements');
            end

            config.trials_per_block = value(trial_plot);
            config.true_mu          = Stim_Params(2);
            config.stimuli_range    = [Stim_Params(1), Stim_Params(3)];
            config.stimulus_mode    = value(Stimuli_State); % plain string, not SoloParamHandle
            config.n_discrete       = value(n_discrete);    % plain double
            config.debug            = false;

            state = value(states_value);

            % Sync table_row_editable length with actual table height
            required_length = height(handles.ui_table.Data);
            if ~isfield(state, 'table_row_editable') || isempty(state.table_row_editable)
                state.table_row_editable = false(required_length, 1);
            elseif numel(state.table_row_editable) ~= required_length
                current_length = numel(state.table_row_editable);
                if required_length > current_length
                    state.table_row_editable = [state.table_row_editable(:); false(required_length - current_length, 1)];
                else
                    state.table_row_editable = state.table_row_editable(1:required_length);
                end
            end
            state.table_row_editable = state.table_row_editable(:);

            psych_obj = value(Update_Psychometric); flags.psych = logical(psych_obj.Value);
            hit_obj   = value(Update_HitRate);      flags.hit   = logical(hit_obj.Value);
            stim_obj  = value(Update_Stimulus);     flags.stim  = logical(stim_obj.Value);

            varargout{1} = state;
            varargout{2} = data;
            varargout{3} = handles;
            varargout{4} = config;
            varargout{5} = flags;

        catch ME
            warning('PsychometricSection:CalcParams', 'Calculate_Params failed: %s', ME.message);
            varargout{1} = []; varargout{2} = []; varargout{3} = [];
            varargout{4} = []; varargout{5} = [];
        end

    % ------------------------------------------------------------------
    %              STIMULI STATE CHANGED
    %  Implements pending-switch logic:
    %    Case A - no pending switch: initiate one, show new context widget
    %    Case B - pending active, user reselects original mode: cancel
    %    Case C - pending active, user picks a third mode: cancel + new pending
    % ------------------------------------------------------------------
    case 'Stimuli_State_changed'
        try
            % Guard: n_done_trials may not exist at protocol startup
            if ~exist('n_done_trials', 'var') || isempty(n_done_trials)
                n_done_trials = 0;
            end

            state = value(states_value);
            % Backward compatibility for sessions saved before this refactor
            state = ensureStateFields(state);

            new_mode = value(Stimuli_State); % plain string — SoloParamHandle behaves
                                             % unpredictably outside BControl section context

            if ~state.pending_switch.active
                % ---- CASE A: no pending switch in progress ----
                if strcmpi(new_mode, state.last_stable_mode)
                    % User reselected the already-active mode — nothing to do
                    % Inline button state: Switch_Distr only for Full/not-pending
                    if strcmpi(new_mode, 'Full'), enable(Switch_Distr); else, disable(Switch_Distr); end
                    enable(PsychometricShow);
                    states_value.value = state;
                    return;
                end

                % PRE-EXPERIMENT GUARD: if no trials have been completed yet,
                % the user is still configuring the initial state — not switching
                % mid-session. Relabel context 1 in-place rather than creating a
                % new context. This prevents a phantom Context 1 [trial 1–1] in
                % the widget when the user simply sets a non-default mode at startup.
                if n_done_trials == 0
                    ctx = value(thiscontext);
                    eval(sprintf('Context%i_Dist.value = ''%s'';', ctx, new_mode));
                    state.last_stable_mode = new_mode;
                    if strcmpi(new_mode, 'Full'), enable(Switch_Distr); else, disable(Switch_Distr); end
                    enable(PsychometricShow);
                    states_value.value = state;
                    return;
                end

                % Hard limit: max 3 contexts
                if value(thiscontext) >= 3
                    warndlg(sprintf('Maximum 3 contexts reached. Cannot switch to ''%s''.', new_mode), 'Context Limit');
                    if strcmpi(state.last_stable_mode, 'Full'), enable(Switch_Distr); else, disable(Switch_Distr); end
                    enable(PsychometricShow);
                    states_value.value = state;
                    return;
                end

                % Open pending switch and show new context widget immediately
                % (inline: do NOT call subfunctions — SoloParamHandles not in their scope)
                state.pending_switch.active      = true;
                state.pending_switch.from_mode   = state.last_stable_mode;
                state.pending_switch.to_mode     = new_mode;
                state.pending_switch.start_trial = n_done_trials + 1;
                state.pending_switch.trial_count = 0;

                thiscontext.value = value(thiscontext) + 1;
                ctx = value(thiscontext);
                % Inline context widget update (eval runs in main function workspace)
                eval(sprintf('Context%i_Dist.value = ''%s'';',      ctx, new_mode));
                eval(sprintf('Context%i_trialStart.value = %d;',    ctx, n_done_trials + 1));
                eval(sprintf('Context%i_trialEnd.value   = %d;',    ctx, n_done_trials + 1));
                eval(sprintf('make_visible(Context%i_Dist);',       ctx));
                eval(sprintf('make_visible(Context%i_trialStart);', ctx));
                eval(sprintf('make_visible(Context%i_trialEnd);',   ctx));

                disable(Switch_Distr);  % block distribution switch while mode switch is pending
                enable(PsychometricShow);

            else
                % ---- A pending switch is already active ----
                if strcmpi(new_mode, state.pending_switch.from_mode)
                    % ---- CASE B: user reverted to original mode — cancel ----
                    ctx = value(thiscontext);
                    % Inline hide + reset context widget
                    eval(sprintf('make_invisible(Context%i_Dist);',       ctx));
                    eval(sprintf('make_invisible(Context%i_trialStart);', ctx));
                    eval(sprintf('make_invisible(Context%i_trialEnd);',   ctx));
                    eval(sprintf('Context%i_trialStart.value = 1;', ctx));
                    eval(sprintf('Context%i_trialEnd.value   = 1;', ctx));

                    % Guard: thiscontext must not go below 1
                    if value(thiscontext) > 1
                        thiscontext.value = value(thiscontext) - 1;
                    end
                    % Absorb the few pending trials silently into previous context
                    eval(sprintf('Context%i_trialEnd.value = n_done_trials;', value(thiscontext)));

                    % Clear pending switch
                    state.pending_switch = clearPendingSwitch();

                    % Restore button states for the original stable mode
                    from_mode = state.last_stable_mode;
                    if strcmpi(from_mode, 'Full'), enable(Switch_Distr); else, disable(Switch_Distr); end
                    enable(PsychometricShow);

                elseif strcmpi(new_mode, state.pending_switch.to_mode)
                    % User reselected the same pending mode — no structural change needed
                    disable(Switch_Distr);
                    enable(PsychometricShow);

                else
                    % ---- CASE C: third mode selected — cancel current, start new ----

                    % Step 1: cancel the current pending (inline hide + reset)
                    ctx = value(thiscontext);
                    eval(sprintf('make_invisible(Context%i_Dist);',       ctx));
                    eval(sprintf('make_invisible(Context%i_trialStart);', ctx));
                    eval(sprintf('make_invisible(Context%i_trialEnd);',   ctx));
                    eval(sprintf('Context%i_trialStart.value = 1;', ctx));
                    eval(sprintf('Context%i_trialEnd.value   = 1;', ctx));
                    if value(thiscontext) > 1
                        thiscontext.value = value(thiscontext) - 1;
                    end
                    eval(sprintf('Context%i_trialEnd.value = n_done_trials;', value(thiscontext)));

                    % Check limit again after decrement
                    if value(thiscontext) >= 3
                        warndlg(sprintf('Maximum 3 contexts reached. Cannot switch to ''%s''.', new_mode), 'Context Limit');
                        state.pending_switch = clearPendingSwitch();
                        states_value.value = state;
                        if strcmpi(state.last_stable_mode, 'Full'), enable(Switch_Distr); else, disable(Switch_Distr); end
                        enable(PsychometricShow);
                        return;
                    end

                    % Step 2: open new pending switch for the third mode (inline)
                    state.pending_switch.active      = true;
                    state.pending_switch.from_mode   = state.last_stable_mode;
                    state.pending_switch.to_mode     = new_mode;
                    state.pending_switch.start_trial = n_done_trials + 1;
                    state.pending_switch.trial_count = 0;

                    thiscontext.value = value(thiscontext) + 1;
                    ctx = value(thiscontext);
                    eval(sprintf('Context%i_Dist.value = ''%s'';',      ctx, new_mode));
                    eval(sprintf('Context%i_trialStart.value = %d;',    ctx, n_done_trials + 1));
                    eval(sprintf('Context%i_trialEnd.value   = %d;',    ctx, n_done_trials + 1));
                    eval(sprintf('make_visible(Context%i_Dist);',       ctx));
                    eval(sprintf('make_visible(Context%i_trialStart);', ctx));
                    eval(sprintf('make_visible(Context%i_trialEnd);',   ctx));

                    disable(Switch_Distr);
                    enable(PsychometricShow);
                end
            end

            states_value.value = state;

        catch ME
            warning('PsychometricSection:StateChanged', 'Stimuli_State_changed error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              DISTRIBUTION SWITCH (Full mode only)
    % ------------------------------------------------------------------
    case 'PushButton_Distribution_Switch'
        try
            state = value(states_value);
            state = ensureStateFields(state);

            % Block if a mode switch is still pending
            if state.pending_switch.active
                warndlg('Wait for the current mode switch to commit before changing distribution.', 'Action Blocked');
                return;
            end

            if strcmpi(Stimuli_State, 'Full')
                choice = questdlg('Are you sure you want to switch the distribution?', ...
                    'Confirm Action', 'Yes', 'No', 'No');

                if strcmp(choice, 'Yes')
                    eval(sprintf('present_context_start = value(Context%i_trialStart);', value(thiscontext)));
                    eval(sprintf('present_context_end   = value(Context%i_trialEnd);',   value(thiscontext)));

                    if ~strcmpi(Category_Dist, 'Uniform') && present_context_end > present_context_start
                        if value(thiscontext) < 3
                            thiscontext.value = value(thiscontext) + 1;
                            eval(sprintf('Context%i_Dist.value = Category_Dist;',             value(thiscontext)));
                            eval(sprintf('Context%i_trialStart.value = n_done_trials + 1;',   value(thiscontext)));
                            eval(sprintf('Context%i_trialEnd.value   = n_done_trials + 1;',   value(thiscontext)));
                            eval(sprintf('make_visible(Context%i_Dist);',                      value(thiscontext)));
                            eval(sprintf('make_visible(Context%i_trialStart);',                value(thiscontext)));
                            eval(sprintf('make_visible(Context%i_trialEnd);',                  value(thiscontext)));
                        end
                        if strcmpi(Category_Dist, 'Hard A')
                            StimulusSection(obj, 'Pushbutton_SwitchDistribution', 'Hard B');
                        elseif strcmpi(Category_Dist, 'Hard B')
                            StimulusSection(obj, 'Pushbutton_SwitchDistribution', 'Hard A');
                        end

                        [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
                        if ~isempty(data)
                            state = RealTimeAnalysis('context_switch', state, data, handles, config, flags);
                        end
                        states_value.value = state;
                    end
                end
            end
        catch ME
            warning('PsychometricSection:DistrSwitch', 'PushButton_Distribution_Switch error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              STIM SECTION DISTRIBUTION SWITCH (programmatic)
    % ------------------------------------------------------------------
    case 'StimSection_Distribution_Switch'
        try
            if strcmpi(Stimuli_State, 'Full')
                eval(sprintf('present_context_start = value(Context%i_trialStart);', value(thiscontext)));
                eval(sprintf('present_context_end   = value(Context%i_trialEnd);',   value(thiscontext)));

                if present_context_end > present_context_start
                    if value(thiscontext) < 3
                        thiscontext.value = value(thiscontext) + 1;
                        eval(sprintf('Context%i_Dist.value = Category_Dist;',           value(thiscontext)));
                        eval(sprintf('Context%i_trialStart.value = n_done_trials + 1;', value(thiscontext)));
                        eval(sprintf('Context%i_trialEnd.value   = n_done_trials + 1;', value(thiscontext)));
                        eval(sprintf('make_visible(Context%i_Dist);',                    value(thiscontext)));
                        eval(sprintf('make_visible(Context%i_trialStart);',              value(thiscontext)));
                        eval(sprintf('make_visible(Context%i_trialEnd);',                value(thiscontext)));

                        if present_context_end - present_context_start >= 20
                            [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
                            if ~isempty(data)
                                state = RealTimeAnalysis('context_switch', state, data, handles, config, flags);
                            end
                            states_value.value = state;
                        end
                    end
                else
                    eval(sprintf('Context%i_Dist.value = Category_Dist;', value(thiscontext)));
                end
            end
        catch ME
            warning('PsychometricSection:StimSectionSwitch', 'StimSection_Distribution_Switch error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              CUSTOM RANGE PLOT
    % ------------------------------------------------------------------
    case 'PushButton_SelectedTrial'
        try
            [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
            if ~isempty(data)
                start_t = value(Plot_Trial_Start);
                end_t   = value(Plot_Trial_End);
                if start_t >= 1 && end_t > start_t && end_t <= numel(data.hit_history)
                    state = RealTimeAnalysis('custom', state, data, handles, config, flags, start_t, end_t);
                    states_value.value = state;
                else
                    warning('PsychometricSection:CustomRange', 'Invalid trial range [%d %d] for custom plot.', start_t, end_t);
                end
            end
        catch ME
            warning('PsychometricSection:CustomPlot', 'PushButton_SelectedTrial error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              CONTEXT COMPARISON PLOT
    % ------------------------------------------------------------------
    case 'PushButton_Context'
        try
            [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
            if ~isempty(data)
                n_ctx = value(thiscontext);
                context_trials = cell(1, n_ctx);
                contexts_name  = cell(1, n_ctx);
                for n_plot = 1:n_ctx
                    eval(sprintf('trial_start   = value(Context%i_trialStart);', n_plot));
                    eval(sprintf('trial_end     = value(Context%i_trialEnd);',   n_plot));
                    eval(sprintf('context_name  = value(Context%i_Dist);',       n_plot));
                    context_trials{1,n_plot} = [trial_start, trial_end];
                    contexts_name{1,n_plot}  = context_name;
                end
                state = RealTimeAnalysis('context', state, data, handles, config, flags, context_trials, contexts_name);
                states_value.value = state;
            end
        catch ME
            warning('PsychometricSection:ContextPlot', 'PushButton_Context error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              RELOAD AFTER CRASH
    % ------------------------------------------------------------------
    case 'reload_after_crash'
        try
            % Make all used context widgets visible
            for n_contexts = 1:value(thiscontext)
                eval(sprintf('make_visible(Context%i_Dist);',        n_contexts));
                eval(sprintf('make_visible(Context%i_trialStart);',  n_contexts));
                eval(sprintf('make_visible(Context%i_trialEnd);',    n_contexts));
            end

            % Restore and upgrade state struct
            state = value(states_value);
            state = ensureStateFields(state);

            % If a pending switch was active when crash happened, keep its widget visible
            if state.pending_switch.active
                ctx = value(thiscontext);
                if ctx >= 1 && ctx <= 3
                    eval(sprintf('make_visible(Context%i_Dist);',       ctx));
                    eval(sprintf('make_visible(Context%i_trialStart);', ctx));
                    eval(sprintf('make_visible(Context%i_trialEnd);',   ctx));
                end
            end
            states_value.value = state;

            % Restore table handle (not saved as it's 'saveable', false)
            ui_table_handle = value(uit);
            table_fig = value(myfig_table);
            if ishandle(table_fig)
                ui_table_handle.Parent = table_fig;
            end
            if isempty(ui_table_handle.CellEditCallback)
                ui_table_handle.CellEditCallback = @(src, evt) PsychometricSection(obj, 'check_box_table', src, evt);
            end

            % Backward compat: add Stimulus_Mode column if missing (old saved sessions)
            if ~isempty(ui_table_handle.Data) && ...
               ~ismember('Stimulus_Mode', ui_table_handle.Data.Properties.VariableNames)
                n_rows = height(ui_table_handle.Data);
                ui_table_handle.Data.Stimulus_Mode = repmat("", n_rows, 1);
            end

            uit.value = ui_table_handle;

        catch ME
            warning('PsychometricSection:Reload', 'reload_after_crash error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              UPDATE (called after every trial by BControl)
    % ------------------------------------------------------------------
    case 'update'
        try
            if n_done_trials > 1
                % Step 1: persist pending_switch changes BEFORE Calculate_Params reads state
                state = value(states_value);
                state = ensureStateFields(state);

                % Update trial end for the currently-active context
                ctx = value(thiscontext);
                if ctx >= 1 && ctx <= 3
                    eval(sprintf('Context%i_trialEnd.value = n_done_trials;', ctx));
                end

                % Step 2: pending switch commit check (count every trial)
                if state.pending_switch.active
                    state.pending_switch.trial_count = state.pending_switch.trial_count + 1;
                    merge_threshold = max(1, round(2/3 * value(trial_plot)));

                    if state.pending_switch.trial_count >= merge_threshold
                        % --- Commit ---
                        committed_mode = state.pending_switch.to_mode;
                        state.last_stable_mode  = committed_mode;
                        state.pending_switch    = clearPendingSwitch();

                        if strcmpi(committed_mode, 'Full')
                            enable(Switch_Distr);
                        else
                            disable(Switch_Distr);
                        end
                        % PsychometricShow stays enabled for all modes
                        enable(PsychometricShow);
                    end
                    % Save pending_switch update before Calculate_Params overwrites state
                    states_value.value = state;
                end

                % Step 3: run analysis for all modes (mode gating is inside RealTimeAnalysis)
                [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
                if ~isempty(data)
                    state = RealTimeAnalysis('live', state, data, handles, config, flags);
                end
                if ~isempty(state)
                    states_value.value = state;
                end
            end
        catch ME
            warning('PsychometricSection:Update', 'update error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              UPDATE PLOT (called when figure becomes visible)
    % ------------------------------------------------------------------
    case 'update_plot'
        try
            if n_done_trials > 1
                [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
                if ~isempty(data)
                    state = RealTimeAnalysis('redraw', state, data, handles, config, flags);
                end
                if ~isempty(state)
                    states_value.value = state;
                end
            end
        catch ME
            warning('PsychometricSection:UpdatePlot', 'update_plot error: %s', ME.message);
        end

    % ------------------------------------------------------------------
    %              EVALUATE (end-of-session summary)
    % ------------------------------------------------------------------
    case 'evaluate'
        psych_result = [];
        try
            if n_done_trials > 1
                n_ctx = value(thiscontext);
                context_trials = cell(1, n_ctx);
                context_modes  = cell(1, n_ctx);
                psych_result   = cell(1, n_ctx);

                for n_context = 1:n_ctx
                    eval(sprintf('trial_start  = value(Context%i_trialStart);', n_context));
                    eval(sprintf('trial_end    = value(Context%i_trialEnd);',   n_context));
                    eval(sprintf('ctx_dist     = value(Context%i_Dist);',       n_context));
                    context_trials{1,n_context} = [trial_start, trial_end];
                    context_modes{1,n_context}  = ctx_dist;

                    % Pre-fill defaults (will be overwritten by RealTimeAnalysis)
                    psych_result{1,n_context}.start_trial              = trial_start;
                    psych_result{1,n_context}.end_trial                = trial_end;
                    psych_result{1,n_context}.valid_trials             = -1;
                    psych_result{1,n_context}.stimulus_mode            = ctx_dist;
                    psych_result{1,n_context}.distribution_type        = '';
                    psych_result{1,n_context}.calculated_boundary      = nan;
                    psych_result{1,n_context}.total_hit_percent        = -1;
                    psych_result{1,n_context}.total_violations_percent = -1;
                    psych_result{1,n_context}.right_correct_percent    = -1;
                    psych_result{1,n_context}.left_correct_percent     = -1;
                end

                [state, data, handles, config, flags] = PsychometricSection(obj, 'Calculate_Params');
                if ~isempty(data)
                    psych_result = RealTimeAnalysis('evaluate', state, data, handles, config, flags, context_trials, context_modes);
                end
            end
        catch ME
            fprintf(2, 'PsychometricSection evaluate error: %s\n', ME.message);
        end
        varargout{1} = psych_result;

    % ------------------------------------------------------------------
    %              TABLE CHECKBOX GUARD
    % ------------------------------------------------------------------
    case 'check_box_table'
        try
            if numel(varargin) < 2, return; end
            source    = varargin{1};
            event     = varargin{2};
            editedRow = event.Indices(1);
            editedCol = event.Indices(2);
            if editedCol ~= 1, return; end  % only act on Select column
            if ~event.NewData, return; end   % only act when checking (not unchecking)
            state = value(states_value);
            isRowEditable = state.table_row_editable;
            if editedRow > numel(isRowEditable), return; end
            if ~isRowEditable(editedRow)
                source.Data.Select(editedRow) = false;
            end
        catch
            % Silently ignore — table callback must never crash BControl
        end

    % ------------------------------------------------------------------
    %              FIGURE / VISIBILITY CASES
    % ------------------------------------------------------------------
    case 'close'
        try
            if ishandle(value(myfig)),       set(value(myfig),       'Visible', 'off'); end
            if ishandle(value(myfig_table)), set(value(myfig_table), 'Visible', 'off'); end
            if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig))
                delete(value(myfig));
            end
            if exist('myfig_table', 'var') && isa(myfig_table, 'SoloParamHandle') && ishandle(value(myfig_table))
                delete(value(myfig_table));
            end
            delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);
        catch ME
            warning('PsychometricSection:Close', '%s', ME.message);
        end

    case 'hide'
        PsychometricShow.value = 0;
        try
            if ishandle(value(myfig)),       set(value(myfig),       'Visible', 'off'); end
            if ishandle(value(myfig_table)), set(value(myfig_table), 'Visible', 'off'); end
        catch
        end

    case 'show_hide'
        try
            if ~ishandle(value(myfig)), return; end
            if PsychometricShow == 1
                set(value(myfig), 'Visible', 'on');
                PsychometricSection(obj, 'update_plot');
                if Show_Table_Toggle == 1 && ishandle(value(myfig_table))
                    set(value(myfig_table), 'Visible', 'on');
                elseif ishandle(value(myfig_table))
                    set(value(myfig_table), 'Visible', 'off');
                end
            else
                set(value(myfig), 'Visible', 'off');
                if ishandle(value(myfig_table))
                    set(value(myfig_table), 'Visible', 'off');
                end
            end
        catch ME
            warning('PsychometricSection:ShowHide', '%s', ME.message);
        end

    case 'show_hide_table'
        try
            if ~ishandle(value(myfig_table)), return; end
            set(value(myfig_table), 'Visible', iif(Show_Table_Toggle == 1, 'on', 'off'));
        catch
        end

    case 'hide_table'
        Show_Table_Toggle.value = 0;
        try
            if ishandle(value(myfig_table))
                set(value(myfig_table), 'Visible', 'off');
            end
        catch
        end
end % end switch

end % end main function

% ==========================================================================
%  LOCAL HELPER SUBFUNCTIONS
%  These have access only to what is passed as arguments — no SoloParamHandles
% ==========================================================================

function state = ensureStateFields(state)
% Ensures backward compatibility when loading sessions saved before this refactor.
    if ~isfield(state, 'pending_switch') || ~isstruct(state.pending_switch)
        state.pending_switch = struct();
    end
    if ~isfield(state.pending_switch, 'active'),      state.pending_switch.active      = false; end
    if ~isfield(state.pending_switch, 'from_mode'),   state.pending_switch.from_mode   = '';    end
    if ~isfield(state.pending_switch, 'to_mode'),     state.pending_switch.to_mode     = '';    end
    if ~isfield(state.pending_switch, 'start_trial'), state.pending_switch.start_trial = NaN;   end
    if ~isfield(state.pending_switch, 'trial_count'), state.pending_switch.trial_count = 0;     end
    if ~isfield(state, 'last_stable_mode'),           state.last_stable_mode           = 'Full'; end
    if ~isfield(state, 'block_count'),                state.block_count                = 0;     end
    if ~isfield(state, 'context_blocks'),             state.context_blocks             = 0;     end
    if ~isfield(state, 'table_row_editable'),         state.table_row_editable         = [];    end
    if ~isfield(state, 'blockStatsHistory')
        state.blockStatsHistory = struct('indices', {}, 'hitRates', {}, 'stimCounts', {}, ...
            'stimulus_mode', {}, 'fitCurve', {}, 'fitParams', {});
    end
end

function ps = clearPendingSwitch()
% Returns a clean, inactive pending_switch struct.
    ps.active      = false;
    ps.from_mode   = '';
    ps.to_mode     = '';
    ps.start_trial = NaN;
    ps.trial_count = 0;
end

% NOTE: safeContextSet/Show/Hide/Reset were removed.
% Subfunctions cannot access SoloParamHandles from the main function workspace.
% All context widget evals are now inlined inside Stimuli_State_changed directly.

function out = iif(cond, a, b)
% Inline if — returns a if cond is true, b otherwise.
    if cond, out = a; else, out = b; end
end