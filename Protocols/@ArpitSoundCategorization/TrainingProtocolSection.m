function varargout = TrainingProtocolSection(obj, action, varargin)
% TrainingProtocolSection
%
% Implements manually-selected training stages that automate distribution
% selection at the start of each session, and (for switch-type sessions)
% an automatic within-session distribution flip.
%
%   Stage 1  - Uniform every session. No state.
%   Stage 2a - Alternating fixed blocks: RunLength_N sessions on one
%              asymmetric distribution, then RunLength_N sessions on the
%              other, forever. Starting distribution is randomized fresh
%              on stage entry.
%   Stage 2b - Independent 50/50 coin flip (Hard A / Hard B) every session.
%   Stage 3  - Same coin flip as Stage 2b for the day's base distribution,
%              plus one within-session auto-switch to the other
%              distribution at a trial drawn uniformly from
%              [Stage3_SwitchTrialMin, Stage3_SwitchTrialMax] and shown
%              in an editable field the experimenter can override live.
%              Fired via the same path as the manual Switch_Distr button.
%   Stage 4  - Session-mode pool: Uniform / Single-Asymmetric / Switch-
%              Asymmetric, drawn using RunLength_N + "must differ from
%              current unless RunLength_N==1" rule. Single-Asymmetric
%              behaves like a Stage 2b session; Switch-Asymmetric behaves
%              like a Stage 3 session.
%
% RunLength_N is a single shared edit box used as the block length for
% Stage 2a and the run length for Stage 4 — only one is ever visible/
% relevant at a time, so they share one control rather than two.
%
% All decisions apply starting at n_done_trials==1 (i.e. when preparing
% trial 2), never at 'init', so a freshly-loaded session's first trial
% always uses whatever was loaded from the previous day's settings before
% this section can act. (The 'init'-time call chain does call
% prepare_next_trial once at n_done_trials==0, before settings load —
% harmless, since ApplySessionStartStage never fires there.)
%
% Selecting a new stage in the dropdown immediately resets that stage's
% own internal counters to a clean start; no progress carries over between
% visits to a stage.

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

        % Show/hide toggle lives in the CALLER's figure (e.g. SideSection's
        % main GUI) — created before switching to our own figure below,
        % matching the pattern used by StimulusSection/PsychometricSection.
        ToggleParam(obj, 'TrainingProtocolShow', 0, x, y, ...
            'OnString', 'Training Protocol Shown', 'OffString', 'Show Training Protocol', ...
            'TooltipString', 'Show/Hide the Training Protocol panel');
        set_callback(TrainingProtocolShow, {mfilename, 'show_hide'});
        next_row(y);

        oldx = x; oldy = y; parentfig = double(gcf);

        SoloParamHandle(obj, 'myfig', 'value', figure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], ...
            'MenuBar', 'none', 'Name', 'Training Protocol', 'Units', 'normalized', ...
            'Position', [0.35, 0.3, 0.28, 0.5], 'Visible', 'off'), 'saveable', false);

        x = 10; y = 5;

        MenuParam(obj, 'TrainingStage', {'Stage 1','Stage 2a','Stage 2b','Stage 3','Stage 4'}, ...
            'Stage 1', x, y, 'label', 'Training Stage', 'labelfraction', 0.45, ...
            'TooltipString', sprintf(['\nStage 1: Uniform only, every session.\n', ...
            'Stage 2a: Alternating fixed blocks of RunLength_N sessions, Hard A / Hard B.\n', ...
            'Stage 2b: Random coin-flip Hard A/Hard B, every session.\n', ...
            'Stage 3: Stage 2b + automatic within-session switch.\n', ...
            'Stage 4: Random pool of Uniform / Single-Asym / Switch-Asym session modes.']));
        set_callback(TrainingStage, {mfilename, 'Stage_Changed'});
        next_row(y); next_row(y);

        % ---- Shared run-length box: Stage 2a's block length, or Stage 4's
        % run length. Only one is ever visible at a time. ----
        NumeditParam(obj, 'RunLength_N', 1, x, y, 'label', 'Run length (sessions)', ...
            'TooltipString', sprintf(['Stage 2a: number of sessions on one distribution before alternating.\n', ...
            'Stage 4: number of sessions a picked session mode stays before reselecting (1 = a new mode every session, repeats allowed).\n', ...
            'Shared between the two stages — check this value when moving between them.\n', ...
            'A change applies starting the next session, not the current one.']));
        next_row(y);
        DispParam(obj, 'RunLength_Status', 'n/a for this stage', x, y, 'label', 'Current run', ...
            'TooltipString', 'What is currently running under RunLength_N, and how far through it this session is.');
        next_row(y); next_row(y);

        % ---- Stage 3 (also used by Stage 4's Switch-Asymmetric mode) ----
        NumeditParam(obj, 'Stage3_SwitchTrialMin', 100, x, y, 'label', 'Switch trial min', ...
            'TooltipString', 'Stage 3 / Stage 4 Switch-Asym: minimum trial number for the within-session auto switch.');
        next_row(y);
        NumeditParam(obj, 'Stage3_SwitchTrialMax', 300, x, y, 'label', 'Switch trial max', ...
            'TooltipString', 'Stage 3 / Stage 4 Switch-Asym: maximum trial number for the within-session auto switch.');
        next_row(y);
        NumeditParam(obj, 'Stage3_SwitchTrial_ThisSession', NaN, x, y, 'label', 'Switch @ trial', ...
            'TooltipString', sprintf(['This session''s scheduled switch trial (drawn fresh each switch-type session\n', ...
            'from [min, max] above). Editable live — change it to push the switch earlier or later\n', ...
            'this session; takes effect on the very next trial check.']));
        next_row(y); next_row(y);

        % ---- Stage 4 ----
        ToggleParam(obj, 'Stage4_Include_Uniform', 1, x, y, ...
            'OnString', 'Uniform: IN pool', 'OffString', 'Uniform: OUT of pool', ...
            'TooltipString', 'Stage 4: include Uniform (no switch) as a possible session mode.');
        next_row(y);
        ToggleParam(obj, 'Stage4_Include_SingleAsym', 1, x, y, ...
            'OnString', 'Single-Asym: IN pool', 'OffString', 'Single-Asym: OUT of pool', ...
            'TooltipString', 'Stage 4: include Single-Asymmetric (Hard A or B, no switch) as a possible session mode.');
        next_row(y);
        ToggleParam(obj, 'Stage4_Include_SwitchAsym', 1, x, y, ...
            'OnString', 'Switch-Asym: IN pool', 'OffString', 'Switch-Asym: OUT of pool', ...
            'TooltipString', 'Stage 4: include Switch-Asymmetric (Hard A/B with a within-session switch) as a possible session mode.');
        next_row(y); next_row(y);

        SubheaderParam(obj, 'title', 'Training Protocol', x, y);
        next_row(y);

        % ---- Saveable internal state (persists across day-to-day reload) ----
        SoloParamHandle(obj, 'Stage2a_block_counter', 'value', 0);
        SoloParamHandle(obj, 'Stage2a_current_dist',  'value', '');
        SoloParamHandle(obj, 'Stage3_switch_fired',   'value', false); % internal only, not shown
        SoloParamHandle(obj, 'Stage4_run_length_done','value', 0);
        SoloParamHandle(obj, 'Stage4_current_mode',   'value', '');

        % Set correct initial visibility/status for the default stage.
        TrainingProtocolSection(obj, 'RefreshVisibility');
        TrainingProtocolSection(obj, 'UpdateStatusDisplay');

        x = oldx; y = oldy;
        figure(parentfig);

        varargout{1} = x;
        varargout{2} = y;

    % ------------------------------------------------------------------
    %              STAGE DROPDOWN CHANGED
    %  Resets ONLY the entering stage's own counters. Nothing here touches
    %  Category_Dist directly — the actual distribution change only ever
    %  happens at the next n_done_trials==1 session-start check, never
    %  immediately on a mid-session dropdown click.
    % ------------------------------------------------------------------
    case 'Stage_Changed'
        try
            switch value(TrainingStage)
                case 'Stage 2a'
                    Stage2a_block_counter.value = 0;
                    Stage2a_current_dist.value  = '';
                case 'Stage 3'
                    Stage3_SwitchTrial_ThisSession.value = NaN;
                    Stage3_switch_fired.value = false;
                case 'Stage 4'
                    Stage4_run_length_done.value = 0;
                    Stage4_current_mode.value    = '';
            end
            TrainingProtocolSection(obj, 'RefreshVisibility');
            TrainingProtocolSection(obj, 'UpdateStatusDisplay');
        catch ME
            warning('TrainingProtocolSection:StageChanged', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %              PER-TRIAL ENTRY POINT (called every trial)
    % ------------------------------------------------------------------
    case 'prepare_next_trial'
        try
            if n_done_trials == 0
                % Very first trial of a freshly loaded session. Clear any
                % leftover switch schedule from the previous session
                % before anything else can act on it, and refresh the
                % panel to reflect whatever stage was just loaded.
                Stage3_SwitchTrial_ThisSession.value = NaN;
                Stage3_switch_fired.value = false;
                TrainingProtocolSection(obj, 'RefreshVisibility');
                TrainingProtocolSection(obj, 'UpdateStatusDisplay');
            end

            if n_done_trials == 1
                TrainingProtocolSection(obj, 'ApplySessionStartStage');
            end

            TrainingProtocolSection(obj, 'CheckAutoSwitch');
        catch ME
            warning('TrainingProtocolSection:PrepareNextTrial', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %              SESSION-START STAGE DISPATCH
    %  Fires once per session, at n_done_trials==1 (preparing trial 2).
    % ------------------------------------------------------------------
    case 'ApplySessionStartStage'
        try
            % Always clear the switch schedule first; the stage logic
            % below re-populates it only if today is a switch-type session.
            Stage3_SwitchTrial_ThisSession.value = NaN;
            Stage3_switch_fired.value = false;

            dist = '';
            switch value(TrainingStage)

                case 'Stage 1'
                    dist = 'Uniform';

                case 'Stage 2a'
                    N = value(RunLength_N);
                    if isempty(value(Stage2a_current_dist))
                        % First session since entering this stage.
                        pool2 = {'Hard A', 'Hard B'};
                        Stage2a_current_dist.value  = pool2{randi(2)};
                        Stage2a_block_counter.value = 1;
                    else
                        Stage2a_block_counter.value = value(Stage2a_block_counter) + 1;
                        if value(Stage2a_block_counter) > N
                            % Block complete — flip to the other distribution.
                            if strcmp(value(Stage2a_current_dist), 'Hard A')
                                Stage2a_current_dist.value = 'Hard B';
                            else
                                Stage2a_current_dist.value = 'Hard A';
                            end
                            Stage2a_block_counter.value = 1;
                        end
                    end
                    dist = value(Stage2a_current_dist);

                case 'Stage 2b'
                    dist = TrainingProtocolSection(obj, 'Pick_Asym_Random');

                case 'Stage 3'
                    dist = TrainingProtocolSection(obj, 'Pick_SwitchAsym_Session');

                case 'Stage 4'
                    dist = TrainingProtocolSection(obj, 'Pick_Stage4_Mode');
            end

            if ~isempty(dist)
                StimulusSection(obj, 'Pushbutton_SwitchDistribution', dist);
            end

            % Mode/counters are now finalized for today — refresh the panel.
            TrainingProtocolSection(obj, 'RefreshVisibility');
            TrainingProtocolSection(obj, 'UpdateStatusDisplay');
        catch ME
            warning('TrainingProtocolSection:ApplySessionStartStage', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %              HELPER: plain Hard A / Hard B coin flip
    % ------------------------------------------------------------------
    case 'Pick_Asym_Random'
        pool2 = {'Hard A', 'Hard B'};
        varargout{1} = pool2{randi(2)};

    % ------------------------------------------------------------------
    %              HELPER: a switch-type session (Stage 3, or Stage 4's
    %              Switch-Asym mode). Picks the base distribution AND
    %              schedules today's within-session switch.
    % ------------------------------------------------------------------
    case 'Pick_SwitchAsym_Session'
        dist = TrainingProtocolSection(obj, 'Pick_Asym_Random');

        mn = round(value(Stage3_SwitchTrialMin));
        mx = round(value(Stage3_SwitchTrialMax));
        if mx < mn
            mx = mn; % guard against a misconfigured window
        end
        Stage3_SwitchTrial_ThisSession.value = randi([mn, mx]);
        Stage3_switch_fired.value = false;

        varargout{1} = dist;

    % ------------------------------------------------------------------
    %              STAGE 4: session-mode pool draw
    % ------------------------------------------------------------------
    case 'Pick_Stage4_Mode'
        pool = {};
        if value(Stage4_Include_Uniform),    pool{end+1} = 'Uniform';    end %#ok<AGROW>
        if value(Stage4_Include_SingleAsym), pool{end+1} = 'SingleAsym'; end %#ok<AGROW>
        if value(Stage4_Include_SwitchAsym), pool{end+1} = 'SwitchAsym'; end %#ok<AGROW>

        if isempty(pool)
            warning('TrainingProtocolSection:Stage4EmptyPool', ...
                'No Stage 4 modes selected; defaulting to Uniform for this session.');
            pool = {'Uniform'};
        end

        RL = max(1, round(value(RunLength_N)));
        need_new_pick = isempty(value(Stage4_current_mode)) || value(Stage4_run_length_done) >= RL;

        if need_new_pick
            if RL <= 1 || numel(pool) == 1
                candidates = pool; % repeats allowed, or forced if only one option
            else
                candidates = pool(~strcmp(pool, value(Stage4_current_mode)));
                if isempty(candidates)
                    candidates = pool; % safety net
                end
            end
            Stage4_current_mode.value    = candidates{randi(numel(candidates))};
            Stage4_run_length_done.value = 1;
        else
            Stage4_run_length_done.value = value(Stage4_run_length_done) + 1;
        end

        switch value(Stage4_current_mode)
            case 'Uniform'
                dist = 'Uniform';
            case 'SingleAsym'
                dist = TrainingProtocolSection(obj, 'Pick_Asym_Random');
            case 'SwitchAsym'
                dist = TrainingProtocolSection(obj, 'Pick_SwitchAsym_Session');
            otherwise
                dist = 'Uniform'; % defensive fallback, should not occur
        end

        varargout{1} = dist;

    % ------------------------------------------------------------------
    %              PER-TRIAL AUTO-SWITCH CHECK
    %  Fires the within-session flip once the trial being prepared
    %  reaches the scheduled switch trial (editable live via
    %  Stage3_SwitchTrial_ThisSession), using the same path as the manual
    %  Switch_Distr button so it registers identically in
    %  PsychometricSection's context tracking.
    % ------------------------------------------------------------------
    case 'CheckAutoSwitch'
        sched = value(Stage3_SwitchTrial_ThisSession);
        if ~isnan(sched) && ~value(Stage3_switch_fired)
            upcoming_trial = n_done_trials + 1;
            if upcoming_trial >= sched
                current_dist = value(Category_Dist);
                if strcmpi(current_dist, 'Hard A')
                    next_dist = 'Hard B';
                else
                    next_dist = 'Hard A'; % covers 'Hard B' and any unexpected value defensively
                end
                StimulusSection(obj, 'Pushbutton_SwitchDistribution', next_dist);
                Stage3_switch_fired.value = true;
            end
        end

    % ------------------------------------------------------------------
    %              STATUS DISPLAY (read-only)
    % ------------------------------------------------------------------
    case 'UpdateStatusDisplay'
        try
            switch value(TrainingStage)
                case 'Stage 2a'
                    cur = value(Stage2a_current_dist);
                    if isempty(cur), cur = '(not yet set)'; end
                    RunLength_Status.value = sprintf('%s -- session %d of %d', ...
                        cur, value(Stage2a_block_counter), round(value(RunLength_N)));
                case 'Stage 4'
                    cur = value(Stage4_current_mode);
                    if isempty(cur), cur = '(not yet set)'; end
                    RunLength_Status.value = sprintf('%s -- session %d of %d', ...
                        cur, value(Stage4_run_length_done), round(value(RunLength_N)));
                otherwise
                    RunLength_Status.value = 'n/a for this stage';
            end
        catch ME
            warning('TrainingProtocolSection:UpdateStatusDisplay', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %              VISIBILITY (show only what's relevant to the
    %              currently selected stage / today's drawn mode)
    % ------------------------------------------------------------------
    case 'RefreshVisibility'
        try
            stage = value(TrainingStage);

            % Run-length box + status: Stage 2a or Stage 4 only
            if strcmp(stage,'Stage 2a') || strcmp(stage,'Stage 4')
                make_visible(RunLength_N); make_visible(RunLength_Status);
            else
                make_invisible(RunLength_N); make_invisible(RunLength_Status);
            end

            % Switch window (min/max): Stage 3 or Stage 4 (Stage 4 may
            % draw a Switch-Asym session on any given day, so keep the
            % configured window visible whenever Stage 4 is selected).
            if strcmp(stage,'Stage 3') || strcmp(stage,'Stage 4')
                make_visible(Stage3_SwitchTrialMin); make_visible(Stage3_SwitchTrialMax);
            else
                make_invisible(Stage3_SwitchTrialMin); make_invisible(Stage3_SwitchTrialMax);
            end

            % This-session switch trial: Stage 3 always; Stage 4 only when
            % today's drawn mode is actually Switch-Asym.
            show_switch_trial = strcmp(stage,'Stage 3') || ...
                (strcmp(stage,'Stage 4') && strcmp(value(Stage4_current_mode), 'SwitchAsym'));
            if show_switch_trial
                make_visible(Stage3_SwitchTrial_ThisSession);
            else
                make_invisible(Stage3_SwitchTrial_ThisSession);
            end

            % Stage 4 pool checkboxes only meaningful in Stage 4
            if strcmp(stage,'Stage 4')
                make_visible(Stage4_Include_Uniform); make_visible(Stage4_Include_SingleAsym); make_visible(Stage4_Include_SwitchAsym);
            else
                make_invisible(Stage4_Include_Uniform); make_invisible(Stage4_Include_SingleAsym); make_invisible(Stage4_Include_SwitchAsym);
            end
        catch ME
            warning('TrainingProtocolSection:RefreshVisibility', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %              FIGURE / VISIBILITY CASES
    % ------------------------------------------------------------------
    case 'close'
        set(value(myfig), 'visible', 'off');
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

    case 'hide'
        TrainingProtocolShow.value = 0;
        set(value(myfig), 'visible', 'off');

    case 'show'
        TrainingProtocolShow.value = 1;
        set(value(myfig), 'visible', 'on');

    case 'show_hide'
        if TrainingProtocolShow == 1
            set(value(myfig), 'visible', 'on');
        else
            set(value(myfig), 'visible', 'off');
        end

end

return;