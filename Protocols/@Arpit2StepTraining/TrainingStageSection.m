function varargout = TrainingStageSection(obj, action, varargin)
% TrainingStageSection  -  automatic training stages for Arpit2StepTraining
%
% Each stage sets the trial structure through SideSection('set_stage_params'),
% StimulusSection and AntibiasSection, and is checked for completion after
% every trial (stage 7: at the end of every session).
%
%   1 Side pokes (free)   No centre poke. Side LEDs both on or both off
%                         (uninformative). Either port pays, unlimited time.
%                         Go sound plays with the water: silent for the first
%                         S1_go_start valid trials, then ramped in (S1_go_vol_*).
%                         Done: S1_trials valid trials and S1_switches
%                         changes of the rewarded side.
%   2 Side pokes (timed)  Same, but limited time (RColl_dur adapts between
%                         S2_RColl_max and S2_RColl_min). Done: as stage 1.
%   3 Centre poke         Centre LED -> poke -> go cue -> sides open.
%                         Hold grows from S3_start_CP up to SettlingIn_time
%                         + legal_cbreak, no violations. Done: hold reached
%                         and S3_min_trials valid trials.
%   4 Hold grows          Violations on, hold grows up to S4_max_CP (1 s),
%                         warm-up at session start. Done: hold reached,
%                         >= S4_min_session_trials this session, recent
%                         violation / timeout rates below threshold, stage
%                         violation rate below S4_stage_violation.
%   5 Two-step (easy)     TwoStep trials: one side lit, one dark, sound
%                         during the hold. The hold keeps growing from
%                         S4_max_CP (1 s) to S5_target_CP (2.2 s); the
%                         stimulus has a fixed length S_A1_time (0.4 s) and
%                         its onset varies within the hold. CueRule is
%                         locked from here on. (Discrete, S5_n_levels per
%                         category, symmetric, <= max_dB_discrete). Second
%                         chance after a wrong poke (reward_type Always).
%                         4-cell antibias ON (Auto beta, floor S5_AB_floor).
%                         Done: hold >= S5_target_CP and every cell >=
%                         S5_cell_thresh over the last S5_window valid
%                         2-step trials of the session (>= S5_min_per_cell
%                         trials per cell).
%   6 Expand              The hold is drawn every trial in [S6_cp_min,
%                         S6_cp_max] (1.5-2.2 s), the stimulus (0.4 s) onset
%                         varies within it (same in stage 7).
%                         A ladder of sub-steps (S6_LADDER below). Each step
%                         makes the task harder in one or two ways: more
%                         stimulus levels -> full continuous distribution,
%                         second chance -> delayed second chance -> no second
%                         chance, antibias floor rising towards 0.25 (= off).
%                         A step is passed when every cell >= the threshold
%                         (S6_thresh_discrete or S6_thresh_full) over the
%                         last S6_window valid 2-step trials since the step
%                         started in this session (>= S6_min_per_cell per
%                         cell, >= S6_min_trials in total). Passing the last
%                         step moves the rat to stage 7.
%   7 Probation           Test conditions: Full distribution, no second
%                         chance, antibias OFF, MaxSame / MaxSameCat = Inf,
%                         and a longer error time-out (S7_error_iti) so that
%                         errors cost time and cannot be offset by doing more
%                         trials in the fixed session.
%                         Judged once per session (end of session): a session
%                         passes when it has >= S7_min_trials valid trials,
%                         every cell >= S7_cell_thresh, and a logistic fit
%                             P(responded loud) = f(b0 + b1*stim + b2*side)
%                         gives a clear stimulus effect (b1/SE > 2) and no
%                         category bias (b0) or side bias (b2): each must be
%                         within +/- S7_max_bias (logit units) and not
%                         significant (|b|/SE < 2). After S7_sessions passing
%                         sessions in a row the rat is flagged READY FOR TEST.
%                         A failing session resets the count.
%   Manual                Nothing is changed automatically.
%
% Persistence: values that must survive between sessions are
% SoloParamHandles with 'save_with_settings' = 1 (the same mechanism that
% SessionDefinition's CreateHelperVar uses). GUI parameters are always
% saved with the settings file. 'end_of_session' is called from the
% protocol's pre_saving_settings, i.e. before the settings are saved.

GetSoloFunctionArgs(obj);

STAGES = {'1 Side pokes (free)', '2 Side pokes (timed)', '3 Centre poke', ...
          '4 Hold grows', '5 Two-step (easy)', '6 Expand', '7 Probation', 'Manual'};
N_AUTO_STAGES = 7;

% Stage 6 ladder: one row per sub-step
%   Stimuli_State | levels per category (Discrete) | reward_type | second-chance delay (s) | antibias floor
S6_LADDER = { ...
    'Discrete', 2,   'Always',        0, 0.15; ...
    'Discrete', 4,   'DelayedReward', 1, 0.18; ...   % 8 levels: psychometric becomes available
    'Discrete', 4,   'DelayedReward', 3, 0.20; ...
    'Full',     NaN, 'DelayedReward', 3, 0.20; ...
    'Full',     NaN, 'NoReward',      0, 0.22};

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------
    case 'init'
        x = varargin{1}; y = varargin{2};

        ToggleParam(obj, 'TrainingStageShow', 0, x, y, ...
            'OnString', 'Training Stages Shown', 'OffString', 'Show Training Stages', ...
            'TooltipString', 'Show/Hide the training stage panel');
        set_callback(TrainingStageShow, {mfilename, 'show_hide'});
        next_row(y);
        DispParam(obj, 'StageStatus', '', x, y, 'label', 'Stage', 'labelfraction', 0.2, ...
            'position', [x y 400 20]);
        next_row(y);

        oldx = x; oldy = y; parentfig = double(gcf);

        SoloParamHandle(obj, 'myfig', 'value', figure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], ...
            'MenuBar', 'none', 'Name', 'Training Stages', 'Units', 'normalized', ...
            'Position', [0.15, 0.1, 0.7, 0.8], 'Visible', 'off'), 'saveable', false);

        x = 10; y = 5;

        % ---- column 1: stages 6-7 ----
        NumeditParam(obj, 'S7_error_iti', 7, x, y, 'label', 'S7 error time-out (s)', 'TooltipString', ...
            'Stage 7: longer time-out after a wrong poke, so errors cost time and cannot be offset by doing more trials'); next_row(y);
        ToggleParam(obj, 'handover_on', 1, x, y, 'OnString', 'Hand over to Arpit2StepTask: ON', ...
            'OffString', 'Hand over to Arpit2StepTask: OFF', 'TooltipString', sprintf([ ...
            'When the rat is READY FOR TEST, write tomorrow''s Arpit2StepTask settings file\n' ...
            'with this rat''s values, so runrats loads the experiment protocol next session.'])); next_row(y);
        NumeditParam(obj, 'S7_sessions', 3, x, y, 'label', 'S7 passing sessions'); next_row(y);
        NumeditParam(obj, 'S7_max_bias', 0.5, x, y, 'label', 'S7 max |bias| (logit)'); next_row(y);
        NumeditParam(obj, 'S7_cell_thresh', 0.65, x, y, 'label', 'S7 hit/cell'); next_row(y);
        NumeditParam(obj, 'S7_min_trials', 200, x, y, 'label', 'S7 min valid trials'); next_row(y);
        DispParam(obj, 'S7_last_result', '', x, y, 'label', 'S7 last session', 'labelfraction', 0.3, ...
            'position', [x y 400 20]); next_row(y);
        SubheaderParam(obj, 'sub7', 'Stage 7: Probation (end of session)', x, y); next_row(y, 1.5);

        NumeditParam(obj, 'S6_error_iti', 1, x, y, 'label', 'S5-6 error time-out (s)', 'TooltipString', ...
            'Time-out after a wrong poke in stages 5-6 (used on the NoReward step)'); next_row(y);
        NumeditParam(obj, 'S6_thresh_full', 0.65, x, y, 'label', 'S6 hit/cell (Full)'); next_row(y);
        NumeditParam(obj, 'S6_thresh_discrete', 0.7, x, y, 'label', 'S6 hit/cell (Discrete)'); next_row(y);
        NumeditParam(obj, 'S6_min_trials', 100, x, y, 'label', 'S6 min trials/step'); next_row(y);
        NumeditParam(obj, 'S6_min_per_cell', 20, x, y, 'label', 'S6 min trials/cell'); next_row(y);
        NumeditParam(obj, 'S6_window', 200, x, y, 'label', 'S6 window (valid tr)'); next_row(y);
        NumeditParam(obj, 'S6_cp_max', 2.2, x, y, 'label', 'S6-7 hold max (s)'); next_row(y);
        NumeditParam(obj, 'S6_cp_min', 1.5, x, y, 'label', 'S6-7 hold min (s)', 'TooltipString', ...
            'Stages 6-7: the hold is drawn every trial between min and max; the stimulus onset varies within it'); next_row(y);
        DispParam(obj, 'S6_step_disp', 1, x, y, 'label', 'S6 current step'); next_row(y);
        SubheaderParam(obj, 'sub6', 'Stage 6: Expand (ladder of 5 steps)', x, y); next_row(y, 1.5);

        % ---- column 2: stages 4-5 ----
        next_column(x); y = 5;
        NumeditParam(obj, 'S5_min_per_cell', 20, x, y, 'label', 'S5 min trials/cell'); next_row(y);
        NumeditParam(obj, 'S5_window', 200, x, y, 'label', 'S5 window (valid tr)'); next_row(y);
        NumeditParam(obj, 'S5_cell_thresh', 0.7, x, y, 'label', 'S5 hit/cell'); next_row(y);
        NumeditParam(obj, 'S_A1_time', 0.4, x, y, 'label', 'S5-7 stimulus length (s)', 'TooltipString', ...
            'Fixed stimulus duration from stage 5 on'); next_row(y);
        NumeditParam(obj, 'S5_target_CP', 2.2, x, y, 'label', 'S5 target CP', 'TooltipString', ...
            'Stage 5: the hold grows from S4 max CP to this value'); next_row(y);
        NumeditParam(obj, 'S5_AB_floor', 0.15, x, y, 'label', 'S5 antibias floor'); next_row(y);
        NumeditParam(obj, 'S5_n_levels', 1, x, y, 'label', 'S5 levels/category'); next_row(y);
        SubheaderParam(obj, 'sub5', 'Stage 5: Two-step (easy)', x, y); next_row(y, 1.5);
        % ---- blocks ----
        NumeditParam(obj, 'FB_bias', 0.8, x, y, 'label', 'Fallback if bias >=', 'TooltipString', ...
            'End of session: lit-port or "loud" fraction >= this (or <= 1-this) puts the rat back into short blocks'); next_row(y);
        NumeditParam(obj, 'FB_max', 2, x, y, 'label', 'Max fallbacks/stage'); next_row(y);
        NumeditParam(obj, 'FB_level', 2, x, y, 'label', 'Fallback block level', 'TooltipString', ...
            'Ladder level used for a fallback (2 = BL2 length), then it shrinks again'); next_row(y);
        NumeditParam(obj, 'BL_cap', 300, x, y, 'label', 'Max valid trials/level', 'TooltipString', ...
            'A block level is left after this many valid trials even if the criterion is not met, so blocks never become a resting place'); next_row(y);
        NumeditParam(obj, 'BL_min_trials', 40, x, y, 'label', 'Min valid trials/level'); next_row(y);
        NumeditParam(obj, 'BL_acc', 0.7, x, y, 'label', 'Block hit rate >='); next_row(y);
        NumeditParam(obj, 'BL_switch_acc', 0.6, x, y, 'label', 'Switch-trial hit >=', 'TooltipString', ...
            'Hit rate on the first valid trial of each block. Only the sound can tell the rat the rule changed, so this shows it is listening'); next_row(y);
        NumeditParam(obj, 'BL_switch_n', 10, x, y, 'label', 'Switch trials needed'); next_row(y);
        NumeditParam(obj, 'BL1', 12, x, y, 'position', [x y 66 20], 'label', 'BL1', 'labelfraction', 0.45);
        NumeditParam(obj, 'BL2', 8,  x, y, 'position', [x+67 y 66 20], 'label', 'BL2', 'labelfraction', 0.45);
        NumeditParam(obj, 'BL3', 4,  x, y, 'position', [x+134 y 66 20], 'label', 'BL3', 'labelfraction', 0.45); next_row(y);
        SubheaderParam(obj, 'subbl', 'Blocks (start of stage 5, fallback)', x, y); next_row(y, 1.5);

        NumeditParam(obj, 'recent_window', 50, x, y, 'label', 'Recent window (tr)'); next_row(y);
        NumeditParam(obj, 'recent_timeout', 0.15, x, y, 'label', 'Max recent timeout'); next_row(y);
        NumeditParam(obj, 'recent_violation', 0.15, x, y, 'label', 'Max recent violation'); next_row(y);
        NumeditParam(obj, 'S4_stage_violation', 0.35, x, y, 'label', 'S4 max stage viol'); next_row(y);
        NumeditParam(obj, 'S4_min_session_trials', 100, x, y, 'label', 'S4 min trials today'); next_row(y);
        NumeditParam(obj, 'S4_frac_increase', 0.001, x, y, 'label', 'S4-7 CP frac increase'); next_row(y);
        NumeditParam(obj, 'S4_max_CP', 1.0, x, y, 'label', 'S4 max CP', 'TooltipString', ...
            'Stage 4 ends when the hold reaches this value; stage 5 (sound) starts from it'); next_row(y);
        SubheaderParam(obj, 'sub4', 'Stage 4: Hold grows', x, y); next_row(y, 1.5);

        % ---- column 3: stages 1-3 + stage selection ----
        next_column(x); y = 5;
        NumeditParam(obj, 'S3_min_trials', 50, x, y, 'label', 'S3 min valid trials'); next_row(y);
        NumeditParam(obj, 'S3_frac_increase', 0.002, x, y, 'label', 'S3 CP frac increase'); next_row(y);
        NumeditParam(obj, 'S3_start_CP', 0.05, x, y, 'label', 'S3 start CP'); next_row(y);
        SubheaderParam(obj, 'sub3', 'Stage 3: Centre poke', x, y); next_row(y, 1.5);

        NumeditParam(obj, 'S2_RColl_step', 10, x, y, 'label', 'S2 RColl step (s)'); next_row(y);
        NumeditParam(obj, 'S2_RColl_min', 60, x, y, 'label', 'S2 RColl min (s)'); next_row(y);
        NumeditParam(obj, 'S2_RColl_max', 200, x, y, 'label', 'S2 RColl max (s)'); next_row(y);
        NumeditParam(obj, 'S2_switches', 200, x, y, 'label', 'S2 side switches'); next_row(y);
        NumeditParam(obj, 'S2_trials', 400, x, y, 'label', 'S2 valid trials'); next_row(y);
        SubheaderParam(obj, 'sub2', 'Stage 2: Side pokes (timed)', x, y); next_row(y, 1.5);

        NumeditParam(obj, 'S1_go_vol_end', 0.01, x, y, 'label', 'S1 go vol end', 'TooltipString', ...
            'Go sound volume reached at the end of stage 1 and used in all later stages'); next_row(y);
        NumeditParam(obj, 'S1_go_vol_start', 0.001, x, y, 'label', 'S1 go vol start'); next_row(y);
        NumeditParam(obj, 'S1_go_start', 200, x, y, 'label', 'S1 go sound from trial', 'TooltipString', sprintf([ ...
            'Stage 1: no go sound for the first S1_go_start valid trials, then the volume ramps\n' ...
            'linearly from S1_go_vol_start to S1_go_vol_end by S1_trials valid trials\n' ...
            '(as in ArpitCentrePokeTraining). Helps rats that are afraid of sounds.'])); next_row(y);
        NumeditParam(obj, 'S1_switches', 200, x, y, 'label', 'S1 side switches'); next_row(y);
        NumeditParam(obj, 'S1_trials', 400, x, y, 'label', 'S1 valid trials'); next_row(y);
        SubheaderParam(obj, 'sub1', 'Stage 1: Side pokes (free)', x, y); next_row(y, 1.5);

        % (MaxSame_training, auto toggle and stage menu follow below)
        MenuParam(obj, 'MaxSame_training', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, Inf}, 4, x, y, ...
            'label', 'MaxSame (st 1-6)', 'TooltipString', ...
            'MaxSame and MaxSameCat applied at the start of each session in stages 1-6 (stage 7 uses Inf)'); next_row(y);
        ToggleParam(obj, 'use_auto_train', 1, x, y, 'OnString', 'Auto training ON', ...
            'OffString', 'Auto training OFF', 'TooltipString', ...
            'If OFF, the stage parameters are still applied but the rat never moves to the next stage automatically'); next_row(y);
        MenuParam(obj, 'TrainingStage', STAGES, STAGES{1}, x, y, 'label', 'Training Stage', ...
            'labelfraction', 0.4, 'TooltipString', 'Current stage. Changing it by hand resets that stage''s counters.');
        set_callback(TrainingStage, {mfilename, 'Stage_Changed'});
        next_row(y);
        SubheaderParam(obj, 'title', 'Training Stages', x, y);

        % ---- column 4: performance per stage and this session ----
        % Same information as PerformanceSummarySection / SessionPerformanceSection
        % in ArpitCentrePokeTraining. The per-stage rows are display-only but
        % saved with the settings, so they accumulate across sessions.
        next_column(x); y = 5;
        DispParam(obj, 'Stage_viol',     NaN, x, y, 'label', 'Stage violation');  next_row(y);
        DispParam(obj, 'Stage_timeout',  NaN, x, y, 'label', 'Stage timeout');    next_row(y);
        DispParam(obj, 'Recent_viol',    NaN, x, y, 'label', 'Recent violation'); next_row(y);
        DispParam(obj, 'Recent_timeout', NaN, x, y, 'label', 'Recent timeout');   next_row(y);
        DispParam(obj, 'Session_viol',   NaN, x, y, 'label', 'Session violation'); next_row(y);
        DispParam(obj, 'Session_timeout',NaN, x, y, 'label', 'Session timeout');   next_row(y);
        SubheaderParam(obj, 'subperf', 'This session / current stage', x, y); next_row(y, 1.5);
        for k = N_AUTO_STAGES:-1:1
            DispParam(obj, sprintf('StageSummary_%d', k), '-', x, y, 'label', sprintf('Stage %d', k), ...
                'labelfraction', 0.18, 'position', [x y 330 20], 'save_with_settings', 1);
            next_row(y);
        end
        SubheaderParam(obj, 'subsum', 'Per stage: trials | today | valid | viol | timeout', x, y);

        % Per-stage counts (saved): rows = stages 1-7,
        % columns = [trials, trials today, valid trials, violations, timeouts]
        SoloParamHandle(obj, 'stage_summary', 'value', zeros(N_AUTO_STAGES, 5), 'save_with_settings', 1);

        % ---- Persistent counters (saved with settings) ----
        SoloParamHandle(obj, 'stage_valid_trials', 'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_all_trials',   'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_viol_trials',  'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_switches',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_last_choice',  'value', '', 'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_sessions',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 's6_step',            'value', 1,  'save_with_settings', 1);
        SoloParamHandle(obj, 's7_pass_streak',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 's7_ready',           'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'handover_done',      'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 's6_step_sessions',   'value', 0,  'save_with_settings', 1);   % sessions on the current stage 6 step
        SoloParamHandle(obj, 'cue_rule_locked',    'value', '', 'save_with_settings', 1);   % CueRule fixed from stage 5 on
        SoloParamHandle(obj, 'block_level',        'value', 0,  'save_with_settings', 1);   % 1-3 = BL1-BL3, 0 = random order
        SoloParamHandle(obj, 'block_level_trials', 'value', 0,  'save_with_settings', 1);   % valid 2-step trials at this level
        SoloParamHandle(obj, 'fallback_count',     'value', 0,  'save_with_settings', 1);   % fallbacks used in this stage
        SoloParamHandle(obj, 'level_start',  'value', 1);   % (session) first trial at the current block level
        SoloParamHandle(obj, 'random_since', 'value', 1);   % (session) first trial in random order
        SoloParamHandle(obj, 's7_fit_history',     'value', [], 'save_with_settings', 1); % [b0 b1 b2 se0 se1 se2 ntrials pass] per session
        % Not saved: first trial (this session) that counts for the current stage 6 step
        SoloParamHandle(obj, 's6_step_start', 'value', 1);

        x = oldx; y = oldy;
        figure(parentfig);
        varargout{1} = x;
        varargout{2} = y;

    % ------------------------------------------------------------------
    case 'Stage_Changed'
        % Changed by hand in the menu
        feval(mfilename, obj, 'reset_counters');
        st = feval(mfilename, obj, 'get_stage');
        if st > 0
            feval(mfilename, obj, 'apply_stage', st, true);
        end
        feval(mfilename, obj, 'update_status');

    case 'reset_counters'
        stage_valid_trials.value = 0;
        stage_all_trials.value   = 0;
        stage_viol_trials.value  = 0;
        stage_switches.value     = 0;
        stage_last_choice.value  = '';
        stage_sessions.value     = 0;
        s6_step.value            = 1;
        s6_step_sessions.value   = 0;
        s6_step_start.value      = n_done_trials + 1;
        s7_pass_streak.value     = 0;
        s7_ready.value           = 0;
        % Stage 5 starts in blocks (BL1); every other stage starts in random order
        block_level.value        = double(feval(mfilename, obj, 'get_stage') == 5);
        block_level_trials.value = 0;
        fallback_count.value     = 0;
        level_start.value        = n_done_trials + 1;
        if value(block_level) > 0, random_since.value = Inf; else, random_since.value = n_done_trials + 1; end

    case 'get_stage'
        k = find(strcmp(STAGES, value(TrainingStage)), 1);
        if isempty(k) || k > N_AUTO_STAGES, k = 0; end   % 0 = Manual
        varargout{1} = k;

    case 'push_trial_history'
        % Per-trial record of the stage bookkeeping (non-GUI values have no
        % automatic per-trial history in BControl).
        push_history(stage_valid_trials); push_history(stage_all_trials);
        push_history(stage_viol_trials);  push_history(stage_switches);
        push_history(s6_step);            push_history(s6_step_start);
        push_history(s7_pass_streak);     push_history(s7_ready);
        push_history(stage_summary);
        push_history(block_level); push_history(block_level_trials); push_history(fallback_count);

    case 'get_summary'
        % For an SQL summary / analysis: stage number, name and per-stage counts
        st = feval(mfilename, obj, 'get_stage');
        out.stage_no = st;
        out.stage_name = value(TrainingStage);
        out.stage_summary = value(stage_summary);   % [trials today valid viol timeout] per stage
        out.s6_step = value(s6_step);
        out.s7_pass_streak = value(s7_pass_streak);
        out.s7_ready = value(s7_ready);
        out.stage_sessions = value(stage_sessions);
        out.s6_step_sessions = value(s6_step_sessions);
        out.cue_rule = SideSection(obj, 'get_cue_rule');
        out.block_level = value(block_level);
        out.fallback_count = value(fallback_count);
        varargout{1} = out;

    case 'is_ready_for_test'
        varargout{1} = value(s7_ready);

    % ------------------------------------------------------------------
    %              PREPARE NEXT TRIAL (called from SideSection after scoring)
    % ------------------------------------------------------------------
    case 'prepare_next_trial'
        try
            st = feval(mfilename, obj, 'get_stage');
            n  = n_done_trials + 0;
            if n == 0
                s6_step_start.value = 1;   % new session: stage 6 window starts again
                level_start.value = 1;
                if value(block_level) > 0, random_since.value = Inf; else, random_since.value = 1; end
                ss = value(stage_summary); ss(:, 2) = 0; stage_summary.value = ss;
            end

            if st > 0 && n > 0
                % Update stage counters with the trial that just finished
                stage_all_trials.value = value(stage_all_trials) + 1;
                stage_viol_trials.value = value(stage_viol_trials) + double(violation_history(n));
                ss = value(stage_summary);
                ss(st, 1) = ss(st, 1) + 1;
                ss(st, 2) = ss(st, 2) + 1;
                ss(st, 3) = ss(st, 3) + double(~isnan(hit_history(n)));
                ss(st, 4) = ss(st, 4) + double(violation_history(n));
                ss(st, 5) = ss(st, 5) + double(timeout_history(n));
                stage_summary.value = ss;
                if ~isnan(hit_history(n))
                    stage_valid_trials.value = value(stage_valid_trials) + 1;
                    ch = choice_history(n);
                    if (ch == 'l' || ch == 'r')
                        if ~isempty(value(stage_last_choice)) && ch ~= value(stage_last_choice)
                            stage_switches.value = value(stage_switches) + 1;
                        end
                        stage_last_choice.value = ch;
                    end
                end

                % Block ladder (stages 5-6)
                if (st == 5 || st == 6) && value(block_level) > 0
                    feval(mfilename, obj, 'block_progress', n);
                end

                % Completion test (stage 7 is judged in end_of_session)
                if value(use_auto_train) == 1 && st < 7 && feval(mfilename, obj, 'completion_test', st)
                    if st == 6 && value(s6_step) < size(S6_LADDER, 1)
                        % next rung of the stage 6 ladder
                        s6_step.value = value(s6_step) + 1;
                        s6_step_sessions.value = 0;
                        s6_step_start.value = n + 1;
                        feval(mfilename, obj, 'apply_stage', 6, true);
                        fprintf(1, 'Arpit2StepTraining: stage 6 step %d at trial %d\n', value(s6_step), n);
                    else
                        TrainingStage.value = STAGES{st + 1};
                        feval(mfilename, obj, 'reset_counters');
                        st = st + 1;
                        feval(mfilename, obj, 'apply_stage', st, true);
                        fprintf(1, 'Arpit2StepTraining: moved to stage "%s" at trial %d\n', STAGES{st}, n);
                    end
                end
            end

            if st > 0
                feval(mfilename, obj, 'apply_stage', st, n == 0);
            end
            feval(mfilename, obj, 'update_status');
        catch ME
            warning('TrainingStageSection:prepare_next_trial', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %   COMPLETION TEST for stage st -> true / false   (stages 1-6)
    % ------------------------------------------------------------------
    case 'completion_test'
        st = varargin{1};
        n  = n_done_trials + 0;
        done = false;
        switch st
            case 1
                done = value(stage_valid_trials) >= value(S1_trials) && value(stage_switches) >= value(S1_switches);
            case 2
                done = value(stage_valid_trials) >= value(S2_trials) && value(stage_switches) >= value(S2_switches);
            case 3
                cp = SideSection(obj, 'get_cp');
                done = cp >= SideSection(obj, 'get_settle_max') - 1e-6 && value(stage_valid_trials) >= value(S3_min_trials);
            case 4
                cp = SideSection(obj, 'get_cp');
                [rv, rt] = feval(mfilename, obj, 'recent_rates');
                stage_vr = value(stage_viol_trials) / max(1, value(stage_all_trials));
                done = cp >= value(S4_max_CP) - 1e-6 && n >= value(S4_min_session_trials) && ...
                       rv < value(recent_violation) && rt < value(recent_timeout) && ...
                       stage_vr < value(S4_stage_violation);
            case 5
                cp = SideSection(obj, 'get_cp');
                if value(block_level) == 0 && cp >= value(S5_target_CP) - 1e-6
                    % only trials in random order count
                    [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', value(S5_window), value(random_since));
                    done = all(n_c >= value(S5_min_per_cell)) && all(hit_c >= value(S5_cell_thresh));
                end
            case 6
                k = min(value(s6_step), size(S6_LADDER, 1));
                if strcmpi(S6_LADDER{k, 1}, 'Full'), thr = value(S6_thresh_full); else, thr = value(S6_thresh_discrete); end
                [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', value(S6_window), max(value(s6_step_start), value(random_since)));
                done = value(block_level) == 0 && sum(n_c) >= value(S6_min_trials) && all(n_c >= value(S6_min_per_cell)) && all(hit_c >= thr);
        end
        varargout{1} = done;

    % ------------------------------------------------------------------
    %   BLOCK_PROGRESS: move to shorter blocks (or random order) when the
    %   rat uses the sound, or when the level's trial cap is reached.
    % ------------------------------------------------------------------
    case 'block_progress'
        n = varargin{1};
        hh = value(hit_history); hh = hh(:);
        bh = value(block_history);
        if size(bh, 1) < n, return; end
        if ~isnan(hh(n)) && ~isnan(bh(n, 1))
            block_level_trials.value = value(block_level_trials) + 1;
        end
        idx = value(level_start):n;
        v   = idx(~isnan(hh(idx)) & ~isnan(bh(idx, 1)));
        sw  = v(bh(v, 5) == 1);
        k   = round(value(BL_switch_n));
        passed = false;
        if numel(sw) >= k && value(block_level_trials) >= value(BL_min_trials)
            sw = sw(end-k+1:end);
            passed = mean(hh(sw)) >= value(BL_switch_acc) && mean(hh(v)) >= value(BL_acc);
        end
        capped = value(block_level_trials) >= value(BL_cap);
        if passed || capped
            old = value(block_level);
            if old >= 3, block_level.value = 0; else, block_level.value = old + 1; end
            block_level_trials.value = 0;
            level_start.value = n + 1;
            if value(block_level) == 0
                random_since.value = n + 1;
                if feval(mfilename, obj, 'get_stage') == 6, s6_step_start.value = n + 1; end
            end
            if capped && ~passed, why = 'trial cap reached'; else, why = 'criterion met'; end
            msg = sprintf('[trial %d] blocks: level %d -> %s (%s)', n, old, ...
                feval(mfilename, obj, 'block_name', value(block_level)), why);
            try CommentsSection(obj, 'append_line', msg); catch, end
            fprintf(1, 'Arpit2StepTraining %s\n', msg);
        end

    case 'block_name'
        lv = varargin{1};
        if lv == 0, varargout{1} = 'random';
        else, L = [value(BL1) value(BL2) value(BL3)]; varargout{1} = sprintf('BL%d (%d trials)', lv, L(lv)); end

    case 'recent_rates'
        n = n_done_trials + 0;
        w = max(1, round(value(recent_window)));
        idx = max(1, n - w + 1):n;
        vh = value(violation_history); th = value(timeout_history);
        if isempty(idx) || numel(vh) < n || numel(th) < n
            varargout{1} = 1; varargout{2} = 1;
        else
            varargout{1} = mean(double(vh(idx)));
            varargout{2} = mean(double(th(idx)));
        end

    case 'cell_performance'
        % Hit fraction per cell over the last <window> valid 2-step trials
        % from trial <first> (of this session) onwards.
        w     = varargin{1};
        first = max(1, varargin{2});
        hh = value(hit_history); hh = hh(:);
        ce = value(cell_history); ce = ce(:);
        m  = min(numel(hh), numel(ce)); hh = hh(1:m); ce = ce(1:m);
        v  = find(~isnan(hh) & ~isnan(ce));
        v  = v(v >= first);
        v  = v(max(1, numel(v) - w + 1):end);
        hit_c = NaN(1, 4); n_c = zeros(1, 4);
        for c = 1:4
            u = v(ce(v) == c);
            n_c(c) = numel(u);
            if n_c(c) > 0, hit_c(c) = mean(hh(u)); end
        end
        varargout{1} = hit_c;
        varargout{2} = n_c;

    % ------------------------------------------------------------------
    %   APPLY STAGE st. varargin{2} = true at stage entry or session start
    % ------------------------------------------------------------------
    case 'apply_stage'
        st = varargin{1};
        at_start = varargin{2};
        p = struct();
        if at_start && st <= 6
            p.MaxSame    = value(MaxSame_training);
            p.MaxSameCat = value(MaxSame_training);
        end
        switch st
            case {1, 2}
                % Go sound: silent, then ramped in, during stage 1
                if st == 1
                    k = value(stage_valid_trials);
                    if k < value(S1_go_start)
                        p.go_sound_on = 0;
                    else
                        p.go_sound_on = 1;
                        frac = min(1, (k - value(S1_go_start)) / max(1, value(S1_trials) - value(S1_go_start)));
                        feval(mfilename, obj, 'set_go_volume', value(S1_go_vol_start) + frac * (value(S1_go_vol_end) - value(S1_go_vol_start)));
                    end
                elseif at_start
                    p.go_sound_on = 1;
                    feval(mfilename, obj, 'set_go_volume', value(S1_go_vol_end));
                end
                p.TrialMode = 'Shaping';
                p.CentrePokeRequired = 0;
                p.ChoiceTimeLimited = double(st == 2);
                p.Stimuli_State = 'No Sound';
                p.increase_CP_training = 0;
                p.warmup_on = 0;
                p.reward_type = 'Always';
                if st == 2
                    rc = SideSection(obj, 'get_rcoll');
                    if value(stage_all_trials) == 0
                        rc = value(S2_RColl_max);
                    elseif n_done_trials >= 2
                        th = value(timeout_history);
                        if all(th(end-1:end))
                            rc = value(S2_RColl_max);
                        elseif ~any(th(end-1:end))
                            rc = max(value(S2_RColl_min), rc - value(S2_RColl_step));
                        end
                    end
                    p.RewardCollection_duration = rc;
                end
            case {3, 4}
                if at_start
                    p.go_sound_on = 1;
                    feval(mfilename, obj, 'set_go_volume', value(S1_go_vol_end));
                end
                p.TrialMode = 'Shaping';
                p.CentrePokeRequired = 1;
                p.ChoiceTimeLimited = 1;
                p.Stimuli_State = 'No Sound';
                p.increase_CP_training = 1;
                p.reward_type = 'Always';
                if st == 3
                    p.warmup_on = 0;
                    p.cp_end = SideSection(obj, 'get_settle_max');
                    p.fraction_increase = value(S3_frac_increase);
                    if at_start
                        if value(stage_all_trials) == 0
                            p.cp_reached = value(S3_start_CP);
                            p.RewardCollection_duration = value(S2_RColl_min);
                        end
                        % continue from where the last session ended
                        p.cp_start = max(value(S3_start_CP), SideSection(obj, 'get_cp_reached'));
                    end
                else
                    p.warmup_on = 1;
                    p.cp_end = value(S4_max_CP);
                    p.fraction_increase = value(S4_frac_increase);
                    if at_start, p.cp_start = SideSection(obj, 'get_settle_max'); end
                end
            case {5, 6, 7}
                if at_start
                    p.go_sound_on = 1;
                    feval(mfilename, obj, 'set_go_volume', value(S1_go_vol_end));
                end
                p.TrialMode = 'TwoStep';
                p.CentrePokeRequired = 1;
                p.ChoiceTimeLimited = 1;
                p.warmup_on = 1;
                p.A1_time = value(S_A1_time);   % fixed stimulus length
                p.random_A1_time = 0;
                if at_start, p.random_PreStim_time = 1; end
                if st == 5
                    % hold grows from S4_max_CP to S5_target_CP
                    p.random_CP = 0;
                    p.increase_CP_training = 1;
                    p.cp_end = value(S5_target_CP);
                    p.fraction_increase = value(S4_frac_increase);
                    if at_start, p.cp_start = value(S4_max_CP); end
                else
                    % stages 6-7: hold drawn every trial in [S6_cp_min, S6_cp_max]
                    p.random_CP = 1;
                    p.increase_CP_training = 0;
                    p.cp_rand_min = value(S6_cp_min);
                    p.cp_rand_max = value(S6_cp_max);
                end
                % Blocks (stages 5-6 only)
                if st <= 6 && value(block_level) > 0
                    L = [value(BL1) value(BL2) value(BL3)];
                    p.block_len = L(value(block_level));
                else
                    p.block_len = 0;
                end
                % CueRule must not change once the sound is introduced
                cur_rule = SideSection(obj, 'get_cue_rule');
                if isempty(value(cue_rule_locked))
                    cue_rule_locked.value = cur_rule;
                    try CommentsSection(obj, 'append_line', ['CueRule locked: ' cur_rule]); catch, end
                elseif ~strcmp(cur_rule, value(cue_rule_locked))
                    p.CueRule = value(cue_rule_locked);
                    msg = sprintf('CueRule change to %s refused: this rat is trained on %s', cur_rule, value(cue_rule_locked));
                    try CommentsSection(obj, 'append_line', msg); catch, end
                    fprintf(2, '%s\n', msg);
                end
                if st <= 6 && at_start
                    p.error_iti = value(S6_error_iti);
                end
                if st == 5
                    p.Stimuli_State = 'Discrete';
                    p.reward_type = 'Always';
                    n_lev = value(S5_n_levels); ab_on = 1; ab_floor = value(S5_AB_floor);
                elseif st == 6
                    k = min(value(s6_step), size(S6_LADDER, 1));
                    S6_step_disp.value = k;
                    p.Stimuli_State = S6_LADDER{k, 1};
                    p.reward_type   = S6_LADDER{k, 3};
                    p.secondhit_delay = S6_LADDER{k, 4};
                    n_lev = S6_LADDER{k, 2}; ab_on = 1; ab_floor = S6_LADDER{k, 5};
                else
                    p.Stimuli_State = 'Full';
                    p.reward_type = 'NoReward';
                    p.error_iti = value(S7_error_iti);
                    p.MaxSame = Inf; p.MaxSameCat = Inf;
                    n_lev = NaN; ab_on = 0; ab_floor = 0.25;
                end
                if at_start
                    if ~isnan(n_lev), StimulusSection(obj, 'set_n_discrete', n_lev); end
                    AntibiasSection(obj, 'set', 'AB_On', ab_on);
                    AntibiasSection(obj, 'set', 'AB_BetaMode', 'Auto');
                    AntibiasSection(obj, 'set', 'AB_Floor', ab_floor);
                end
        end
        if st <= 4 && at_start
            AntibiasSection(obj, 'set', 'AB_On', 0);
            p.random_CP = 0;
            p.block_len = 0;
        end
        SideSection(obj, 'set_stage_params', p);

    case 'set_go_volume'
        % Change the GoSound volume only if it differs (regenerates the sound)
        v = varargin{1};
        try
            cur = SoundInterface(obj, 'get', 'GoSound', 'Vol');
            if isempty(cur) || isnan(cur) || abs(cur - v) > 1e-6
                SoundInterface(obj, 'set', 'GoSound', 'Vol', v);
            end
        catch ME
            warning('TrainingStageSection:go_volume', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    case 'end_of_session'
        try
            stage_sessions.value = value(stage_sessions) + 1;
            if feval(mfilename, obj, 'get_stage') == 6, s6_step_sessions.value = value(s6_step_sessions) + 1; end
            SideSection(obj, 'end_of_session');
            if feval(mfilename, obj, 'get_stage') == 7
                feval(mfilename, obj, 'evaluate_probation_session');
            end
            feval(mfilename, obj, 'check_fallback');
            if value(s7_ready) == 1 && value(handover_done) == 0 && value(handover_on) == 1
                feval(mfilename, obj, 'handover');
            end
            feval(mfilename, obj, 'update_status');
        catch ME
            warning('TrainingStageSection:end_of_session', '%s', ME.message);
        end

    % ------------------------------------------------------------------
    %   HANDOVER: write tomorrow's settings file for Arpit2StepTask.
    %   The two protocols use the same section / parameter names, so the
    %   values carry over directly; only parameters of the main file are
    %   renamed (Arpit2StepTraining_x -> Arpit2StepTask_x). Training-only
    %   values (TrainingStageSection) are left out. runrats picks the newest
    %   settings file (not later than today), so from tomorrow the rat runs
    %   Arpit2StepTask. The file is 'svn add'ed; runrats' end-of-session
    %   commit of the settings folder then includes it.
    % ------------------------------------------------------------------
    case 'handover'
        task = 'Arpit2StepTask';
        try
            if isempty(which(task))
                error('protocol %s not found on the MATLAB path', task);
            end
            [expmtr, rname] = SavingSection(obj, 'get_info');
            global Solo_datadir; %#ok<TLEV>
            if isempty(Solo_datadir)
                Solo_datadir = bSettings('get', 'GENERAL', 'Main_Data_Directory');
            end
            rat_dir = fullfile(Solo_datadir, 'Settings', expmtr, rname);
            if ~exist(rat_dir, 'dir'), mkdir(rat_dir); end

            handles = get_sphandle('owner', ['^@' class(obj) '$']);
            saved = struct; saved_autoset = struct;
            for i = 1:numel(handles)
                if ~gets_saved_with_settings(handles{i}), continue; end
                fn = get_fullname(handles{i});
                if strncmp(fn, 'TrainingStageSection_', 21), continue; end
                fn2 = regexprep(fn, ['^' class(obj) '_'], [task '_']);
                saved.(fn2) = value(handles{i});
                saved_autoset.(fn2) = get_autoset_string(handles{i});
            end
            fig_position = []; %#ok<NASGU>

            base = sprintf('settings_@%s_%s_%s_%s', task, expmtr, rname, yearmonthday(now + 1));
            letter = 'a';
            while exist(fullfile(rat_dir, [base letter '.mat']), 'file'), letter = char(letter + 1); end
            fname = fullfile(rat_dir, [base letter '.mat']);
            save(fname, 'saved', 'saved_autoset', 'fig_position');
            try system(['svn add "' fname '@"']); catch, end

            handover_done.value = 1;
            msg = sprintf('HANDOVER: rat is READY FOR TEST. Wrote %s. From the next session the rat runs %s (experiment group: default Stage 1 / uniform - set the group there).', fname, task);
        catch ME
            msg = ['HANDOVER FAILED: ' ME.message];
        end
        try CommentsSection(obj, 'append_line', msg); catch, end
        fprintf(1, 'Arpit2StepTraining %s\n', msg);

    % ------------------------------------------------------------------
    %   CHECK_FALLBACK (end of session): back into short blocks for the next
    %   session if, in random order, the rat followed / avoided the light or
    %   answered mostly one category.
    % ------------------------------------------------------------------
    case 'check_fallback'
        st = feval(mfilename, obj, 'get_stage');
        if ~(st == 5 || st == 6) || value(block_level) > 0 || value(fallback_count) >= value(FB_max), return; end
        hh = value(hit_history); hh = hh(:);
        ca = value(category_history); ca = ca(:);
        ch = value(choice_history); ch = ch(:);
        lh = value(light_history); lh = lh(:);
        m = min([numel(hh) numel(ca) numel(ch) numel(lh)]);
        idx = max(1, min(value(random_since), m + 1)):m;
        v = idx(~isnan(hh(idx)) & ~isnan(ca(idx)) & (lh(idx) == 'l' | lh(idx) == 'r'));
        if numel(v) < 100, return; end
        flit  = mean(ch(v) == lh(v));
        floud = mean((hh(v) == 1 & ca(v) == 1) | (hh(v) == 0 & ca(v) == 0));
        b = value(FB_bias);
        if flit >= b || flit <= 1 - b || floud >= b || floud <= 1 - b
            block_level.value = min(3, max(1, round(value(FB_level))));
            block_level_trials.value = 0;
            fallback_count.value = value(fallback_count) + 1;
            msg = sprintf('Fallback %d/%d: lit-port %.2f, loud %.2f -> next session starts with %s', ...
                value(fallback_count), value(FB_max), flit, floud, feval(mfilename, obj, 'block_name', value(block_level)));
            try CommentsSection(obj, 'append_line', msg); catch, end
            fprintf(1, 'Arpit2StepTraining %s\n', msg);
        end

    % ------------------------------------------------------------------
    %   STAGE 7: judge today's session
    % ------------------------------------------------------------------
    case 'evaluate_probation_session'
        [fit, msg] = feval(mfilename, obj, 'session_bias_fit');
        hit_c = feval(mfilename, obj, 'cell_performance', Inf, 1);
        if isempty(fit)
            pass = false;
            res = ['FAIL: ' msg];
            fit = NaN(1, 7);
        else
            b = fit(1:3); se = fit(4:6); ntr = fit(7);
            reasons = {};
            if ntr < value(S7_min_trials),            reasons{end+1} = sprintf('%d trials', ntr); end
            if any(isnan(hit_c)) || any(hit_c < value(S7_cell_thresh))
                reasons{end+1} = sprintf('cells %s', mat2str(round(hit_c*100)/100));
            end
            if ~(b(2) / se(2) > 2),                   reasons{end+1} = 'no stimulus effect'; end
            if abs(b(1)) > value(S7_max_bias) || abs(b(1)) / se(1) >= 2, reasons{end+1} = sprintf('category bias %.2f', b(1)); end
            if abs(b(3)) > value(S7_max_bias) || abs(b(3)) / se(3) >= 2, reasons{end+1} = sprintf('side bias %.2f', b(3)); end
            pass = isempty(reasons);
            if pass
                res = sprintf('PASS (b0=%.2f b1=%.2f b2=%.2f, n=%d)', b(1), b(2), b(3), ntr);
            else
                res = ['FAIL: ' strjoin(reasons, ', ')];
            end
        end
        h = value(s7_fit_history);
        s7_fit_history.value = [h; fit(:)' double(pass)];
        if pass
            s7_pass_streak.value = value(s7_pass_streak) + 1;
        else
            s7_pass_streak.value = 0;
        end
        if value(s7_pass_streak) >= value(S7_sessions)
            s7_ready.value = 1;
        end
        S7_last_result.value = res;
        fprintf(1, 'Arpit2StepTraining probation: %s | streak %d/%d\n', res, value(s7_pass_streak), value(S7_sessions));

    case 'session_bias_fit'
        % Logistic fit on today's valid 2-step trials with a stimulus:
        %   y  = 1 if the rat responded "loud" (went to the port a loud sound points to)
        %   x1 = stimulus (log), centred on the boundary and scaled by its SD
        %   x2 = +1 if the "loud" port was on the left, -1 if on the right
        % b0 = category bias (towards "loud"), b2 = side bias (towards left).
        hh  = value(hit_history); hh = hh(:);
        cat_h = value(category_history); cat_h = cat_h(:);
        lh  = value(light_history); lh = lh(:);
        sh  = value(stimulus_history); sh = sh(:);
        m   = min([numel(hh), numel(cat_h), numel(lh), numel(sh)]);
        hh = hh(1:m); cat_h = cat_h(1:m); lh = lh(1:m); sh = sh(1:m);
        v = ~isnan(hh) & ~isnan(cat_h) & ~isnan(sh) & (lh == 'l' | lh == 'r');
        if sum(v) < 30
            varargout{1} = []; varargout{2} = sprintf('only %d usable trials', sum(v)); return;
        end
        hh = hh(v); cat_h = cat_h(v); lh = lh(v); sh = sh(v);
        resp_loud = double((hh == 1 & cat_h == 1) | (hh == 0 & cat_h == 0));
        if strcmp(SideSection(obj, 'get_cue_rule'), 'Loud->Lit')
            loud_left = (lh == 'l');
        else
            loud_left = (lh == 'r');
        end
        x1 = sh - StimulusSection(obj, 'get_boundary');
        sd = std(x1); if sd <= 0 || isnan(sd), sd = 1; end
        X = [ones(numel(x1), 1), x1 / sd, 2*double(loud_left) - 1];
        [b, se] = logistic_fit(X, resp_loud);
        varargout{1} = [b(:)' se(:)' numel(resp_loud)];
        varargout{2} = '';

    case 'update_status'
        st = feval(mfilename, obj, 'get_stage');
        n  = n_done_trials + 0;
        [rv, rt] = feval(mfilename, obj, 'recent_rates');
        if n > 0
            Recent_viol.value     = round(rv*100)/100;
            Recent_timeout.value  = round(rt*100)/100;
            Session_viol.value    = round(mean(double(value(violation_history)))*100)/100;
            Session_timeout.value = round(mean(double(value(timeout_history)))*100)/100;
        end
        ss = value(stage_summary);
        for k = 1:N_AUTO_STAGES
            if ss(k, 1) > 0
                str = sprintf('%d | %d | %d | %.2f | %.2f', ss(k,1), ss(k,2), ss(k,3), ss(k,4)/ss(k,1), ss(k,5)/ss(k,1));
            else
                str = '-';
            end
            eval(sprintf('StageSummary_%d.value = str;', k));
        end
        if st > 0 && ss(st, 1) > 0
            Stage_viol.value    = round(ss(st,4)/ss(st,1)*100)/100;
            Stage_timeout.value = round(ss(st,5)/ss(st,1)*100)/100;
        end
        if st == 0
            s = 'Manual (no automation)';
        else
            s = sprintf('%s | valid %d | switches %d | sessions %d', value(TrainingStage), ...
                value(stage_valid_trials), value(stage_switches), value(stage_sessions));
            if n > 0
                s = sprintf('%s | recent viol %.2f to %.2f', s, rv, rt);
            end
            s = sprintf('%s | rule %s', s, SideSection(obj, 'get_cue_rule'));
            if st == 5 || st == 6
                s = sprintf('%s | %s', s, feval(mfilename, obj, 'block_name', value(block_level)));
            end
            if st == 6
                s = sprintf('%s | step %d/%d', s, value(s6_step), size(S6_LADDER, 1));
            elseif st == 7
                s = sprintf('%s | passing streak %d/%d', s, value(s7_pass_streak), value(S7_sessions));
                if value(s7_ready) == 1, s = [s ' | READY FOR TEST']; end
                if value(handover_done) == 1, s = [s ' | handed over to Arpit2StepTask']; end
            end
        end
        StageStatus.value = s;

    case 'enable_controls'
        h = {TrainingStage, use_auto_train, MaxSame_training, S1_trials, S1_switches, S2_trials, S2_switches, ...
            S2_RColl_max, S2_RColl_min, S2_RColl_step, S3_start_CP, S3_frac_increase, S3_min_trials, ...
            S4_max_CP, S4_frac_increase, S4_min_session_trials, S4_stage_violation, recent_violation, ...
            recent_timeout, recent_window, S5_n_levels, S5_AB_floor, S5_target_CP, S5_cell_thresh, ...
            S5_window, S5_min_per_cell, S6_window, S6_min_per_cell, S6_min_trials, S6_thresh_discrete, ...
            S6_thresh_full, S7_min_trials, S7_cell_thresh, S7_max_bias, S7_sessions, S7_error_iti, S6_error_iti, S1_go_start, S1_go_vol_start, S1_go_vol_end, ...
            S6_cp_min, S6_cp_max, S_A1_time, ...
            BL1, BL2, BL3, BL_switch_n, BL_switch_acc, BL_acc, BL_min_trials, BL_cap, FB_level, FB_max, FB_bias, handover_on};
        for i = 1:numel(h)
            if varargin{1} == 1, enable(h{i}); else, disable(h{i}); end
        end

    % ------------------------------------------------------------------
    case 'close'
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);

    case 'hide'
        TrainingStageShow.value = 0;
        set(value(myfig), 'visible', 'off');

    case 'show'
        TrainingStageShow.value = 1;
        set(value(myfig), 'visible', 'on');

    case 'show_hide'
        if TrainingStageShow == 1
            set(value(myfig), 'visible', 'on');
        else
            set(value(myfig), 'visible', 'off');
        end

    otherwise
        warning('TrainingStageSection:action', 'Unknown action %s', action);
end


% ----------------------------------------------------------------------
% Logistic regression by iteratively reweighted least squares (no toolbox
% needed). A tiny ridge term keeps the fit finite if the data separate
% perfectly. Returns coefficients b and their standard errors se.
% ----------------------------------------------------------------------
function [b, se] = logistic_fit(X, y)
k = size(X, 2);
b = zeros(k, 1);
ridge = 1e-4 * eye(k);
for it = 1:100
    eta = X * b;
    p = 1 ./ (1 + exp(-eta));
    w = max(p .* (1 - p), 1e-9);
    H = X' * (X .* repmat(w, 1, k)) + ridge;
    g = X' * (y - p) - ridge * b;
    step = H \ g;
    b = b + step;
    if max(abs(step)) < 1e-8, break; end
end
p = 1 ./ (1 + exp(-X * b));
w = max(p .* (1 - p), 1e-9);
H = X' * (X .* repmat(w, 1, k)) + ridge;
se = sqrt(diag(inv(H)));
