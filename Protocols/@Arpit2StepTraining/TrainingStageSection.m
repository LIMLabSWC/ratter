function varargout = TrainingStageSection(obj, action, varargin)
% TrainingStageSection  -  automatic training for Arpit2StepTraining
%
% Two tracks run in parallel:
%
% A) TRAINING STAGES (what the rat has to do with its body: pokes, hold,
%    and from stage 7 on, using the rule without being helped)
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
%   5 Hold + sound        TwoStep trials (one side lit, one dark, sound during
%                         the hold). The aim is the HOLD: the rat learns to
%                         wait for the go cue instead of anticipating the
%                         sound. The sound is there so that the rule is
%                         learnt at the same time (conjunctively), but it is
%                         NOT part of the exit criterion. The hold grows from
%                         S4_max_CP to S5_target_CP; the stimulus has a fixed
%                         length S_A1_time and its onset varies within the
%                         hold. CueRule is locked from here on. Starts with
%                         short blocks of one category (BL1-BL3). 4-cell
%                         antibias (Standard, floor S5_AB_floor).
%                         Done: hold >= S5_target_CP, >= S5_min_trials valid
%                         trials in the stage, recent violation / timeout
%                         below threshold, stage violation < S5_stage_violation.
%   6 Random hold         The hold is drawn every trial in [S6_cp_min,
%                         S6_cp_max] (same in stages 7-8), so the go cue
%                         cannot be timed. Antibias as stage 5.
%                         Done: >= S6_min_trials valid trials in the stage,
%                         recent rates below threshold, stage violation
%                         < S6_stage_violation.
%   7 Rule & antibias     The rule must now be used. The antibias plays a
%                         cycle so the rat learns that strategies do not pay:
%                           STRONG for AB7_strong_trials valid trials, then
%                           FREE (gentle antibias) - the rat is watched over
%                           the last AB7_probe_window valid trials. If it
%                           starts to exploit something (one side, the lit
%                           port, one category, or one cell much worse than
%                           another) the antibias goes STRONG again for
%                           AB7_restrong trials, then FREE again, ...
%                         Done (checked every trial, only in a FREE phase):
%                         sound level 6 reached, no blocks, no exploitation,
%                         and every cell >= S7_cell_thresh over the last
%                         S7_window valid trials of the FREE phase
%                         (>= S7_min_per_cell per cell).
%   8 Test (no antibias)  Run like the experiment: Full distribution, no
%                         second chance, antibias OFF, MaxSame = Inf, longer
%                         error time-out S8_error_iti. Judged at the end of
%                         each session by a logistic fit
%                             P(responded loud) = f(b0 + b1*stim + b2*side)
%                         A session passes with >= S8_min_trials valid trials,
%                         every cell >= S8_cell_thresh, a clear stimulus effect
%                         (b1/SE > 2) and no category (b0) or side (b2) bias
%                         (|b| <= S8_max_bias and |b|/SE < 2).
%                         A session with a CLEAR bias or no stimulus effect
%                         sends the rat back to stage 7 (antibias again).
%                         READY FOR TEST (and handover to Arpit2StepTask):
%                         >= S8_min_sessions sessions in stage 8 AND the last
%                         S8_last_pass sessions all passed. The rat cannot
%                         come back from Arpit2StepTask, so this is strict.
%   Manual                Nothing is changed automatically.
%
% B) SOUND LEVEL (what the rat has to learn about the sound), independent of
%    the stages, with its own criterion. Used in stages 5-7 (stage 8 is
%    always level 6):
%      1 Discrete, 1 level per category, second chance (reward_type Always)
%      2 Discrete, 2 levels,  second chance
%      3 Discrete, 4 levels,  delayed second chance (1 s)
%      4 Discrete, 4 levels,  delayed second chance (3 s)
%      5 Full distribution,   delayed second chance (3 s)
%      6 Full distribution,   no second chance (as in the experiment)
%    Next level (checked every trial when Auto training is ON and the trials
%    are in random order, i.e. not in blocks): every cell >= SND_thresh_discrete
%    (levels 1-4) or SND_thresh_full (level 5) over the last SND_window valid
%    2-step trials at this level in this session (>= SND_min_per_cell per
%    cell, >= SND_min_trials in total). Can be set by hand (unlock first).
%
% Persistence: values that must survive between sessions are
% SoloParamHandles with 'save_with_settings' = 1 (the same mechanism that
% SessionDefinition's CreateHelperVar uses). GUI parameters are always
% saved with the settings file. 'end_of_session' is called from the
% protocol's pre_saving_settings, i.e. before the settings are saved.

GetSoloFunctionArgs(obj);

STAGES = {'1 Side pokes (free)', '2 Side pokes (timed)', '3 Centre poke', ...
          '4 Hold grows', '5 Hold + sound', '6 Random hold', '7 Rule & antibias', ...
          '8 Test (no antibias)', 'Manual'};
N_AUTO_STAGES = 8;
% One-line description of each stage (tooltips on the stage menu, the
% 'About' line in the main window, and the stage headers of the window)
STAGE_DESC = { ...
  'No centre poke. Side ports open, either side pays, lights say nothing. Go sound silent, then ramps in. Side antibias + MaxSame keep both sides used. Next: S1 valid trials and side switches.', ...
  'As stage 1, but the choice window shrinks (S2 RColl max -> min); no poke in time = timeout. Next: S2 valid trials and side switches.', ...
  'Trials start with a centre poke; the hold starts at S3 start CP and grows; then either side pays. Next: hold reaches the settling time and S3 min valid trials.', ...
  'The hold grows to S4 max CP (violations now count). Next: hold = S4 max CP, enough trials today, recent and stage violation/timeout rates below limits.', ...
  'Learn to hold through the sound and wait for the go cue (hold grows to S5 target CP). Sound is on so the rule is learnt alongside (sound level runs on its own). Blocks first, 4-cell antibias. Next: hold reached, S5 min trials, violation/timeout limits.', ...
  'The hold is random every trial (S6 hold min-max), so the go cue cannot be timed. Next: S6 min trials, violation/timeout limits.', ...
  'Use the rule. Antibias cycle: STRONG, then FREE (gentle) while the rat is watched for strategies; a strategy -> STRONG again. Next: sound level 6, in a FREE phase every cell >= S7 hit/cell, no strategy.', ...
  'Test, run like the experiment (Full, no reward on errors, NO antibias). Each session is judged by a logistic fit. A clear bias -> back to stage 7. Handover after >= S8 min sessions with the last S8 passing all passed.', ...
  'Manual: no automation; set everything by hand.'};
% Short form for the 'About' line in the main window (fits 140 px)
STAGE_SHORT = {'either side pays', 'choice time shrinks', 'centre poke, hold grows', ...
  'hold grows to S4 max', 'hold + sound, blocks', 'random hold', 'rule, antibias cycle', ...
  'test, no antibias', 'no automation'};

% Sound levels (track B): one row per level
%   menu name | Stimuli_State | levels per category (Discrete) | reward_type | second-chance delay (s)
SOUND_LEVELS = { ...
    '1 Discr. 1, 2nd ch.',  'Discrete', 1,   'Always',        0; ...
    '2 Discr. 2, 2nd ch.',  'Discrete', 2,   'Always',        0; ...
    '3 Discr. 4, delay 1',  'Discrete', 4,   'DelayedReward', 1; ...   % 8 levels: psychometric available
    '4 Discr. 4, delay 3',  'Discrete', 4,   'DelayedReward', 3; ...
    '5 Full, delay 3',      'Full',     NaN, 'DelayedReward', 3; ...
    '6 Full, no 2nd ch.',   'Full',     NaN, 'NoReward',      0};
N_SND = size(SOUND_LEVELS, 1);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------
    case 'init'
        x = varargin{1}; y = varargin{2};

        % ---- Main window (top of column 4): current stage and how to change it ----
        ToggleParam(obj, 'TrainingStageShow', 0, x, y, ...
            'OnString', 'Training Stages Shown', 'OffString', 'Show Training Stages', ...
            'TooltipString', 'Show/Hide the window with the stage thresholds and per-stage summary');
        set_callback(TrainingStageShow, {mfilename, 'show_hide'});
        next_row(y);
        DispParam(obj, 'StageBrief', '', x, y, 'label', 'Progress', 'labelfraction', 0.3, 'TooltipString', ...
            'Valid trials and sessions in this stage (details at the top of the Training Stages window)');
        next_row(y);
        DispParam(obj, 'StageAbout', STAGE_SHORT{1}, x, y, 'label', 'About', 'labelfraction', 0.3, 'TooltipString', ...
            'What the current stage does (full text: hover over the Stage menu, or open Show Training Stages)');
        set(get_ghandle(StageAbout), 'HorizontalAlignment', 'left');
        next_row(y);
        DispParam(obj, 'StageHit', '-', x, y, 'label', 'Stage hit', 'labelfraction', 0.3, 'TooltipString', ...
            'Hit rate in this stage over all its sessions, and today (hits / valid trials)');
        next_row(y);
        ToggleParam(obj, 'use_auto_train', 1, x, y, 'OnString', 'Auto training ON', ...
            'OffString', 'Auto training OFF', 'TooltipString', ...
            'If OFF, the stage and sound-level parameters are still applied but the rat never moves on automatically');
        next_row(y);
        tip = sprintf(['Sound level, used in stages 5-7 (stage 8 always uses level 6).\n' ...
            'It moves on by its own criterion (Training Stages window, "Sound level"),\n' ...
            'independent of the stage. To change it by hand: unlock, then pick a level.\n']);
        for k = 1:N_SND
            if strcmp(SOUND_LEVELS{k, 2}, 'Full'), d = 'Full distribution'; else, d = sprintf('Discrete, %d per category', SOUND_LEVELS{k, 3}); end
            switch SOUND_LEVELS{k, 4}
                case 'Always',        r = 'second chance';
                case 'DelayedReward', r = sprintf('second chance after %d s', SOUND_LEVELS{k, 5});
                otherwise,            r = 'no second chance';
            end
            tip = sprintf('%s\n%d: %s, %s', tip, k, d, r);
        end
        MenuParam(obj, 'SoundLevel', SOUND_LEVELS(:, 1)', SOUND_LEVELS{1, 1}, x, y, 'label', 'Sound', ...
            'labelfraction', 0.25, 'TooltipString', tip);
        set_callback(SoundLevel, {mfilename, 'SoundLevel_Changed'});
        next_row(y);
        tip = sprintf('Current training stage (dropdown). To change it by hand: click the Locked button below, then pick a stage.\nChanging it restarts that stage''s progress counters.\n');
        for k = 1:numel(STAGES), tip = sprintf('%s\n%s: %s', tip, STAGES{k}, STAGE_DESC{k}); end
        MenuParam(obj, 'TrainingStage', STAGES, STAGES{1}, x, y, 'label', 'Stage', ...
            'labelfraction', 0.25, 'TooltipString', tip);
        set_callback(TrainingStage, {mfilename, 'Stage_Changed'});
        next_row(y);
        SubheaderParam(obj, 'stage_main_title', 'Training stage', x, y);
        next_row(y);

        oldx = x; oldy = y; parentfig = double(gcf);

        SoloParamHandle(obj, 'myfig', 'value', figure( ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], ...
            'MenuBar', 'none', 'Name', 'Training Stages', 'Units', 'pixels', ...
            'Position', [60 80 1190 680], 'Visible', 'off'), 'saveable', false);
        LF = 0.62;   % label fraction in this window: wider labels, numbers need little room

        x = 10; y = 5;

        % ---- column 1: stages 8 and 7 ----
        ToggleParam(obj, 'handover_on', 1, x, y, 'OnString', 'Hand over to Arpit2StepTask: ON', ...
            'OffString', 'Hand over to Arpit2StepTask: OFF', 'TooltipString', sprintf([ ...
            'When the rat is READY FOR TEST, write tomorrow''s Arpit2StepTask settings file\n' ...
            'with this rat''s values, so runrats loads the experiment protocol next session.'])); next_row(y);
        NumeditParam(obj, 'S8_error_iti', 7, x, y, 'labelfraction', LF, 'label', 'S8 error timeout (s)', 'TooltipString', ...
            'Stage 8: longer time-out after a wrong poke, so errors cost time and cannot be offset by doing more trials'); next_row(y);
        NumeditParam(obj, 'S8_max_bias', 0.5, x, y, 'labelfraction', LF, 'label', 'S8 max |bias| (logit)'); next_row(y);
        NumeditParam(obj, 'S8_cell_thresh', 0.65, x, y, 'labelfraction', LF, 'label', 'S8 hit/cell'); next_row(y);
        NumeditParam(obj, 'S8_min_trials', 200, x, y, 'labelfraction', LF, 'label', 'S8 min valid tr/sess'); next_row(y);
        NumeditParam(obj, 'S8_last_pass', 5, x, y, 'labelfraction', LF, 'label', 'S8 last sess. passing', 'TooltipString', ...
            'Handover needs this many passing sessions in a row, ending with the last one'); next_row(y);
        NumeditParam(obj, 'S8_min_sessions', 7, x, y, 'labelfraction', LF, 'label', 'S8 min sessions', 'TooltipString', ...
            'At least this many sessions in stage 8 (about one week) before the handover'); next_row(y);
        SubheaderParam(obj, 'sub8', 'Stage 8: Test (no antibias)', x, y, 'TooltipString', STAGE_DESC{8}); next_row(y, 1.5);

        NumeditParam(obj, 'AB7_cell_gap', 0.3, x, y, 'labelfraction', LF, 'label', 'Strategy: cell gap >=', 'TooltipString', ...
            'FREE phase: best cell hit rate minus worst cell hit rate >= this counts as a strategy'); next_row(y);
        NumeditParam(obj, 'AB7_frac', 0.7, x, y, 'labelfraction', LF, 'label', 'Strategy: frac >=', 'TooltipString', sprintf([ ...
            'FREE phase: one side, the lit port, or one category ("loud") chosen\n' ...
            'on >= this fraction (or <= 1-this) of the probe window counts as a strategy'])); next_row(y);
        NumeditParam(obj, 'AB7_probe_window', 80, x, y, 'labelfraction', LF, 'label', 'Probe window (valid)', 'TooltipString', ...
            'FREE phase: strategies are checked over the last this many valid trials of the phase'); next_row(y);
        NumeditParam(obj, 'AB7_restrong', 150, x, y, 'labelfraction', LF, 'label', 'Re-strong (valid tr)', 'TooltipString', ...
            'Length of a STRONG phase after a strategy was seen (or after coming back from stage 8)'); next_row(y);
        NumeditParam(obj, 'AB7_strong_trials', 300, x, y, 'labelfraction', LF, 'label', 'First strong (valid)', 'TooltipString', ...
            'Length of the first STRONG antibias phase when the rat enters stage 7'); next_row(y);
        NumeditParam(obj, 'S7_min_per_cell', 20, x, y, 'labelfraction', LF, 'label', 'S7 min trials/cell'); next_row(y);
        NumeditParam(obj, 'S7_window', 200, x, y, 'labelfraction', LF, 'label', 'S7 window (valid tr)'); next_row(y);
        NumeditParam(obj, 'S7_cell_thresh', 0.7, x, y, 'labelfraction', LF, 'label', 'S7 hit/cell'); next_row(y);
        DispParam(obj, 'AB7_phase_disp', '-', x, y, 'labelfraction', 0.4, 'label', 'Antibias phase'); next_row(y);
        SubheaderParam(obj, 'sub7', 'Stage 7: Rule & antibias', x, y, 'TooltipString', STAGE_DESC{7}); next_row(y, 1.5);

        % ---- column 2: stages 6 and 5, blocks ----
        next_column(x); y = 5;
        NumeditParam(obj, 'S6_stage_violation', 0.3, x, y, 'labelfraction', LF, 'label', 'S6 max stage viol'); next_row(y);
        NumeditParam(obj, 'S6_min_trials', 300, x, y, 'labelfraction', LF, 'label', 'S6 min valid trials'); next_row(y);
        NumeditParam(obj, 'S6_cp_max', 2.2, x, y, 'labelfraction', LF, 'label', 'S6-8 hold max (s)'); next_row(y);
        NumeditParam(obj, 'S6_cp_min', 1.5, x, y, 'labelfraction', LF, 'label', 'S6-8 hold min (s)', 'TooltipString', ...
            'Stages 6-8: the hold is drawn every trial between min and max; the stimulus onset varies within it'); next_row(y);
        SubheaderParam(obj, 'sub6', 'Stage 6: Random hold', x, y, 'TooltipString', STAGE_DESC{6}); next_row(y, 1.5);

        NumeditParam(obj, 'S5_stage_violation', 0.3, x, y, 'labelfraction', LF, 'label', 'S5 max stage viol'); next_row(y);
        NumeditParam(obj, 'S5_min_trials', 300, x, y, 'labelfraction', LF, 'label', 'S5 min valid trials'); next_row(y);
        NumeditParam(obj, 'S5_AB_floor', 0.15, x, y, 'labelfraction', LF, 'label', 'S5-6 antibias floor'); next_row(y);
        NumeditParam(obj, 'S_error_iti', 1, x, y, 'labelfraction', LF, 'label', 'S5-7 error timeout (s)', 'TooltipString', ...
            'Time-out after a wrong poke in stages 5-7 (matters on sound level 6, no second chance)'); next_row(y);
        NumeditParam(obj, 'S_A1_time', 0.4, x, y, 'labelfraction', LF, 'label', 'S5-8 stim length (s)', 'TooltipString', ...
            'Fixed stimulus duration from stage 5 on'); next_row(y);
        NumeditParam(obj, 'S5_target_CP', 2.2, x, y, 'labelfraction', LF, 'label', 'S5 target CP', 'TooltipString', ...
            'Stage 5: the hold grows from S4 max CP to this value'); next_row(y);
        SubheaderParam(obj, 'sub5', 'Stage 5: Hold + sound', x, y, 'TooltipString', STAGE_DESC{5}); next_row(y, 1.5);
        % ---- blocks ----
        NumeditParam(obj, 'FB_bias', 0.8, x, y, 'labelfraction', LF, 'label', 'Fallback if bias >=', 'TooltipString', ...
            'End of session: lit-port or "loud" fraction >= this (or <= 1-this) puts the rat back into short blocks'); next_row(y);
        NumeditParam(obj, 'FB_max', 2, x, y, 'labelfraction', LF, 'label', 'Max fallbacks/stage'); next_row(y);
        NumeditParam(obj, 'FB_level', 2, x, y, 'labelfraction', LF, 'label', 'Fallback block level', 'TooltipString', ...
            'Ladder level used for a fallback (2 = BL2 length), then it shrinks again'); next_row(y);
        NumeditParam(obj, 'BL_cap', 300, x, y, 'labelfraction', LF, 'label', 'Max valid tr/level', 'TooltipString', ...
            'A block level is left after this many valid trials even if the criterion is not met, so blocks never become a resting place'); next_row(y);
        NumeditParam(obj, 'BL_min_trials', 40, x, y, 'labelfraction', LF, 'label', 'Min valid tr/level'); next_row(y);
        NumeditParam(obj, 'BL_acc', 0.7, x, y, 'labelfraction', LF, 'label', 'Block hit rate >='); next_row(y);
        NumeditParam(obj, 'BL_switch_acc', 0.6, x, y, 'labelfraction', LF, 'label', 'Switch-trial hit >=', 'TooltipString', ...
            'Hit rate on the first valid trial of each block. Only the sound can tell the rat the rule changed, so this shows it is listening'); next_row(y);
        NumeditParam(obj, 'BL_switch_n', 10, x, y, 'labelfraction', LF, 'label', 'Switch trials needed'); next_row(y);
        NumeditParam(obj, 'BL1', 12, x, y, 'position', [x y 66 20], 'label', 'BL1', 'labelfraction', 0.45);
        NumeditParam(obj, 'BL2', 8,  x, y, 'position', [x+67 y 66 20], 'label', 'BL2', 'labelfraction', 0.45);
        NumeditParam(obj, 'BL3', 4,  x, y, 'position', [x+134 y 66 20], 'label', 'BL3', 'labelfraction', 0.45); next_row(y);
        SubheaderParam(obj, 'subbl', 'Blocks (from stage 5, fallback)', x, y); next_row(y, 1.5);

        % ---- column 3: sound level, stages 4 and 3 ----
        next_column(x); y = 5;
        NumeditParam(obj, 'S4_stage_violation', 0.35, x, y, 'labelfraction', LF, 'label', 'S4 max stage viol'); next_row(y);
        NumeditParam(obj, 'S4_min_session_trials', 100, x, y, 'labelfraction', LF, 'label', 'S4 min trials today'); next_row(y);
        NumeditParam(obj, 'S4_frac_increase', 0.001, x, y, 'labelfraction', LF, 'label', 'S4-5 CP frac increase'); next_row(y);
        NumeditParam(obj, 'S4_max_CP', 1.0, x, y, 'labelfraction', LF, 'label', 'S4 max CP', 'TooltipString', ...
            'Stage 4 ends when the hold reaches this value; stage 5 (sound) starts from it'); next_row(y);
        SubheaderParam(obj, 'sub4', 'Stage 4: Hold grows', x, y, 'TooltipString', STAGE_DESC{4}); next_row(y, 1.5);

        NumeditParam(obj, 'S3_min_trials', 50, x, y, 'labelfraction', LF, 'label', 'S3 min valid trials'); next_row(y);
        NumeditParam(obj, 'S3_frac_increase', 0.002, x, y, 'labelfraction', LF, 'label', 'S3 CP frac increase'); next_row(y);
        NumeditParam(obj, 'S3_start_CP', 0.05, x, y, 'labelfraction', LF, 'label', 'S3 start CP'); next_row(y);
        SubheaderParam(obj, 'sub3', 'Stage 3: Centre poke', x, y, 'TooltipString', STAGE_DESC{3}); next_row(y, 1.5);

        NumeditParam(obj, 'SND_thresh_full', 0.65, x, y, 'labelfraction', LF, 'label', 'Hit/cell (Full)'); next_row(y);
        NumeditParam(obj, 'SND_thresh_discrete', 0.7, x, y, 'labelfraction', LF, 'label', 'Hit/cell (Discrete)'); next_row(y);
        NumeditParam(obj, 'SND_min_trials', 100, x, y, 'labelfraction', LF, 'label', 'Min valid tr/level'); next_row(y);
        NumeditParam(obj, 'SND_min_per_cell', 20, x, y, 'labelfraction', LF, 'label', 'Min trials/cell'); next_row(y);
        NumeditParam(obj, 'SND_window', 200, x, y, 'labelfraction', LF, 'label', 'Window (valid tr)'); next_row(y);
        DispParam(obj, 'SND_progress', '-', x, y, 'labelfraction', 0.3, 'label', 'Level'); next_row(y);
        SubheaderParam(obj, 'subsnd', 'Sound level (stages 5-7)', x, y, 'TooltipString', sprintf([ ...
            'Independent of the stage. Next level when, in random order (no blocks),\n' ...
            'every cell >= Hit/cell over the last Window valid 2-step trials at this\n' ...
            'level today (>= Min trials/cell, >= Min valid tr/level). Level 6 is needed\n' ...
            'to leave stage 7.'])); next_row(y, 1.5);

        % ---- column 4: stages 1-2, all stages ----
        next_column(x); y = 5;
        NumeditParam(obj, 'recent_window', 50, x, y, 'labelfraction', LF, 'label', 'Recent window (tr)'); next_row(y);
        NumeditParam(obj, 'recent_timeout', 0.15, x, y, 'labelfraction', LF, 'label', 'Max recent timeout'); next_row(y);
        NumeditParam(obj, 'recent_violation', 0.15, x, y, 'labelfraction', LF, 'label', 'Max recent violation', 'TooltipString', ...
            'Stages 4-6: the recent violation / timeout rates must be below these to move on'); next_row(y);
        MenuParam(obj, 'MaxSame_training', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, Inf}, 4, x, y, 'labelfraction', LF, ...
            'label', 'MaxSame (st 1-7)', 'TooltipString', ...
            'MaxSame and MaxSameCat applied at the start of each session in stages 1-7 (stage 8 uses Inf)'); next_row(y);
        SubheaderParam(obj, 'title', 'All stages', x, y); next_row(y, 1.5);

        NumeditParam(obj, 'S2_RColl_step', 10, x, y, 'labelfraction', LF, 'label', 'S2 RColl step (s)'); next_row(y);
        NumeditParam(obj, 'S2_RColl_min', 60, x, y, 'labelfraction', LF, 'label', 'S2 RColl min (s)'); next_row(y);
        NumeditParam(obj, 'S2_RColl_max', 200, x, y, 'labelfraction', LF, 'label', 'S2 RColl max (s)'); next_row(y);
        NumeditParam(obj, 'S2_switches', 200, x, y, 'labelfraction', LF, 'label', 'S2 side switches'); next_row(y);
        NumeditParam(obj, 'S2_trials', 400, x, y, 'labelfraction', LF, 'label', 'S2 valid trials'); next_row(y);
        SubheaderParam(obj, 'sub2', 'Stage 2: Side pokes (timed)', x, y, 'TooltipString', STAGE_DESC{2}); next_row(y, 1.5);

        NumeditParam(obj, 'S1_go_vol_end', 0.01, x, y, 'labelfraction', LF, 'label', 'S1 go vol end', 'TooltipString', ...
            'Go sound volume reached at the end of stage 1 and used in all later stages'); next_row(y);
        NumeditParam(obj, 'S1_go_vol_start', 0.001, x, y, 'labelfraction', LF, 'label', 'S1 go vol start'); next_row(y);
        NumeditParam(obj, 'S1_go_start', 200, x, y, 'labelfraction', LF, 'label', 'S1 go sound from tr', 'TooltipString', sprintf([ ...
            'Stage 1: no go sound for the first S1_go_start valid trials, then the volume ramps\n' ...
            'linearly from S1_go_vol_start to S1_go_vol_end by S1_trials valid trials\n' ...
            '(as in ArpitCentrePokeTraining). Helps rats that are afraid of sounds.'])); next_row(y);
        NumeditParam(obj, 'S1_switches', 200, x, y, 'labelfraction', LF, 'label', 'S1 side switches'); next_row(y);
        NumeditParam(obj, 'S1_trials', 400, x, y, 'labelfraction', LF, 'label', 'S1 valid trials'); next_row(y);
        SubheaderParam(obj, 'sub1', 'Stage 1: Side pokes (free)', x, y, 'TooltipString', STAGE_DESC{1}); next_row(y, 1.5);

        % ---- column 5: performance per stage and this session ----
        % Same information as PerformanceSummarySection / SessionPerformanceSection
        % in ArpitCentrePokeTraining. The per-stage rows are display-only but
        % saved with the settings, so they accumulate across sessions.
        next_column(x); y = 5;
        DispParam(obj, 'Stage_viol',     NaN, x, y, 'labelfraction', 0.62, 'label', 'Stage violation');  next_row(y);
        DispParam(obj, 'Stage_timeout',  NaN, x, y, 'labelfraction', 0.62, 'label', 'Stage timeout');    next_row(y);
        DispParam(obj, 'Recent_viol',    NaN, x, y, 'labelfraction', 0.62, 'label', 'Recent violation'); next_row(y);
        DispParam(obj, 'Recent_timeout', NaN, x, y, 'labelfraction', 0.62, 'label', 'Recent timeout');   next_row(y);
        DispParam(obj, 'Session_viol',   NaN, x, y, 'labelfraction', 0.62, 'label', 'Session violation'); next_row(y);
        DispParam(obj, 'Session_timeout',NaN, x, y, 'labelfraction', 0.62, 'label', 'Session timeout');   next_row(y);
        SubheaderParam(obj, 'subperf', 'This session / stage', x, y); next_row(y, 1.5);
        for k = N_AUTO_STAGES:-1:1
            DispParam(obj, sprintf('StageSummary_%d', k), '-', x, y, 'label', sprintf('Stage %d', k), ...
                'labelfraction', 0.17, 'position', [x y 340 20], 'save_with_settings', 1);
            next_row(y);
        end
        SubheaderParam(obj, 'subsum', 'Per stage: trials | today | valid | viol | tout | hit | hit today', x, y, ...
            'position', [x y 340 20], 'TooltipString', sprintf(['Saved with the settings, so it adds up over sessions and over\n' ...
            'return visits to a stage. viol / tout = fraction of trials; hit = hits / valid trials\n' ...
            '(stages 1-4: either side pays, so hit is about 1 when the rat pokes)']));
        next_row(y);

        % Full status lines across the top of the window
        top = fit_window(value(myfig), 1190, 22);
        DispParam(obj, 'S8_last_result', '', 10, top, 'label', 'Last test session', 'labelfraction', 0.1, ...
            'position', [10 top 1170 20]);
        DispParam(obj, 'StageStatus', '', 10, top + 22, 'label', 'Status', 'labelfraction', 0.1, ...
            'position', [10 top+22 1170 20]);
        set([get_ghandle(StageStatus) get_ghandle(S8_last_result)], 'HorizontalAlignment', 'left');

        % Per-stage counts (saved): rows = stages 1-8, columns =
        % [trials, trials today, valid, violations, timeouts, hits, valid today, hits today]
        SoloParamHandle(obj, 'stage_summary', 'value', zeros(N_AUTO_STAGES, 8), 'save_with_settings', 1);

        % ---- Persistent counters (saved with settings) ----
        SoloParamHandle(obj, 'stage_valid_trials', 'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_all_trials',   'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_viol_trials',  'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_switches',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_last_choice',  'value', '', 'save_with_settings', 1);
        SoloParamHandle(obj, 'stage_sessions',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'snd_level_sessions', 'value', 0,  'save_with_settings', 1);   % sessions at the current sound level
        SoloParamHandle(obj, 'ab_phase',           'value', 'strong', 'save_with_settings', 1); % stage 7: 'strong' | 'free'
        SoloParamHandle(obj, 'ab_phase_trials',    'value', 0,  'save_with_settings', 1);   % valid 2-step trials in this phase
        SoloParamHandle(obj, 'ab_phase_len',       'value', 300, 'save_with_settings', 1);  % length of the current STRONG phase
        SoloParamHandle(obj, 'ab7_cycles',         'value', 0,  'save_with_settings', 1);   % strategies seen -> back to STRONG
        SoloParamHandle(obj, 's8_results',         'value', [], 'save_with_settings', 1);   % [b0 b1 b2 se0 se1 se2 ntrials pass] per stage-8 session
        SoloParamHandle(obj, 's8_returns',         'value', 0,  'save_with_settings', 1);   % stage 8 -> 7 because of a clear bias
        SoloParamHandle(obj, 'ready_for_test',     'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'handover_done',      'value', 0,  'save_with_settings', 1);
        SoloParamHandle(obj, 'cue_rule_locked',    'value', '', 'save_with_settings', 1);   % CueRule fixed from stage 5 on
        SoloParamHandle(obj, 'block_level',        'value', 0,  'save_with_settings', 1);   % 1-3 = BL1-BL3, 0 = random order
        SoloParamHandle(obj, 'block_level_trials', 'value', 0,  'save_with_settings', 1);   % valid 2-step trials at this level
        SoloParamHandle(obj, 'fallback_count',     'value', 0,  'save_with_settings', 1);   % fallbacks used in this stage
        % Not saved (this session only): first trial that counts for ...
        SoloParamHandle(obj, 'level_start',     'value', 1);   % ... the current block level
        SoloParamHandle(obj, 'random_since',    'value', 1);   % ... random order (no blocks)
        SoloParamHandle(obj, 'snd_level_start', 'value', 1);   % ... the current sound level
        SoloParamHandle(obj, 'ab_phase_start',  'value', 1);   % ... the current antibias phase (stage 7)

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

    case 'SoundLevel_Changed'
        % Changed by hand (or by the automatic criterion)
        snd_level_sessions.value = 0;
        snd_level_start.value = n_done_trials + 1;
        st = feval(mfilename, obj, 'get_stage');
        if st >= 5 && st <= 7
            feval(mfilename, obj, 'apply_sound_level');
        end
        feval(mfilename, obj, 'update_status');

    case 'reset_counters'
        % Called when the stage changes. The sound level is NOT reset: it is
        % an independent track.
        st = feval(mfilename, obj, 'get_stage');
        n1 = n_done_trials + 1;
        stage_valid_trials.value = 0;
        stage_all_trials.value   = 0;
        stage_viol_trials.value  = 0;
        stage_switches.value     = 0;
        stage_last_choice.value  = '';
        stage_sessions.value     = 0;
        ready_for_test.value     = 0;
        fallback_count.value     = 0;
        % Stage 7 starts with a STRONG antibias phase
        ab_phase.value        = 'strong';
        ab_phase_trials.value = 0;
        ab_phase_len.value    = value(AB7_strong_trials);
        ab_phase_start.value  = n1;
        % Blocks: stage 5 starts in BL1; stages 6-7 keep the current block
        % level (blocks are left on their own criterion); 1-4 and 8: none.
        if st == 5
            block_level.value = 1;
        elseif st < 5 || st == 8
            block_level.value = 0;
        end
        block_level_trials.value = 0;
        level_start.value = n1;
        if value(block_level) > 0, random_since.value = Inf; else, random_since.value = n1; end
        snd_level_start.value = n1;

    case 'get_stage'
        k = find(strcmp(STAGES, value(TrainingStage)), 1);
        if isempty(k) || k > N_AUTO_STAGES, k = 0; end   % 0 = Manual
        varargout{1} = k;

    case 'get_sound_level'
        k = find(strcmp(SOUND_LEVELS(:, 1), value(SoundLevel)), 1);
        if isempty(k), k = 1; end
        varargout{1} = k;

    case 'push_trial_history'
        % Per-trial record of the stage bookkeeping (non-GUI values have no
        % automatic per-trial history in BControl).
        push_history(stage_valid_trials); push_history(stage_all_trials);
        push_history(stage_viol_trials);  push_history(stage_switches);
        push_history(ab_phase);           push_history(ab_phase_trials);
        push_history(ready_for_test);     push_history(stage_summary);
        push_history(block_level); push_history(block_level_trials); push_history(fallback_count);

    case 'get_summary'
        % For an SQL summary / analysis and the performance monitor
        st = feval(mfilename, obj, 'get_stage');
        out.stage_no = st;
        out.stage_name = value(TrainingStage);
        out.stage_summary = value(stage_summary);   % [trials today valid viol timeout hits valid_today hits_today] per stage
        out.stage_sessions = value(stage_sessions);
        out.sound_level = feval(mfilename, obj, 'get_sound_level');
        out.sound_level_sessions = value(snd_level_sessions);
        out.ab_phase = value(ab_phase);
        out.ab7_cycles = value(ab7_cycles);
        out.s8_results = value(s8_results);
        out.s8_returns = value(s8_returns);
        out.ready_for_test = value(ready_for_test);
        out.cue_rule = SideSection(obj, 'get_cue_rule');
        out.block_level = value(block_level);
        out.fallback_count = value(fallback_count);
        varargout{1} = out;

    case 'is_ready_for_test'
        varargout{1} = value(ready_for_test);

    % ------------------------------------------------------------------
    %              PREPARE NEXT TRIAL (called from SideSection after scoring)
    % ------------------------------------------------------------------
    case 'prepare_next_trial'
        try
            st = feval(mfilename, obj, 'get_stage');
            n  = n_done_trials + 0;
            if n == 0
                % new session: the session-only windows start again
                level_start.value = 1;
                snd_level_start.value = 1;
                ab_phase_start.value = 1;
                if value(block_level) > 0, random_since.value = Inf; else, random_since.value = 1; end
                ss = value(stage_summary);
                if size(ss, 2) < 8, ss(:, end+1:8) = 0; end                 % older settings: 5 columns
                if size(ss, 1) < N_AUTO_STAGES, ss(end+1:N_AUTO_STAGES, :) = 0; end   % older settings: 7 stages
                ss(:, [2 7 8]) = 0;                                          % today's counts
                stage_summary.value = ss;
            end

            if st > 0 && n > 0
                % Update stage counters with the trial that just finished
                valid = ~isnan(hit_history(n));
                stage_all_trials.value = value(stage_all_trials) + 1;
                stage_viol_trials.value = value(stage_viol_trials) + double(violation_history(n));
                ss = value(stage_summary);
                ss(st, 1) = ss(st, 1) + 1;
                ss(st, 2) = ss(st, 2) + 1;
                ss(st, 3) = ss(st, 3) + double(valid);
                ss(st, 4) = ss(st, 4) + double(violation_history(n));
                ss(st, 5) = ss(st, 5) + double(timeout_history(n));
                ss(st, 6) = ss(st, 6) + double(hit_history(n) == 1);
                ss(st, 7) = ss(st, 7) + double(valid);
                ss(st, 8) = ss(st, 8) + double(hit_history(n) == 1);
                stage_summary.value = ss;
                if valid
                    stage_valid_trials.value = value(stage_valid_trials) + 1;
                    ch = choice_history(n);
                    if (ch == 'l' || ch == 'r')
                        if ~isempty(value(stage_last_choice)) && ch ~= value(stage_last_choice)
                            stage_switches.value = value(stage_switches) + 1;
                        end
                        stage_last_choice.value = ch;
                    end
                end

                % Block ladder (stages 5-7)
                if st >= 5 && st <= 7 && value(block_level) > 0
                    feval(mfilename, obj, 'block_progress', n);
                end

                % Stage 7: antibias cycle (STRONG <-> FREE)
                if st == 7
                    feval(mfilename, obj, 'ab7_cycle', n, valid);
                end

                % Sound level (track B, stages 5-7, independent of the stage)
                if value(use_auto_train) == 1 && st >= 5 && st <= 7 && value(block_level) == 0
                    k = feval(mfilename, obj, 'get_sound_level');
                    if k < N_SND && feval(mfilename, obj, 'sound_level_test', k)
                        SoundLevel.value = SOUND_LEVELS{k + 1, 1};
                        msg = sprintf('[trial %d] sound level %d -> %d (%s)', n, k, k + 1, SOUND_LEVELS{k + 1, 1});
                        try CommentsSection(obj, 'append_line', msg); catch, end
                        fprintf(1, 'Arpit2StepTraining %s\n', msg);
                        feval(mfilename, obj, 'SoundLevel_Changed');
                    end
                end

                % Stage completion test (stage 8 is judged in end_of_session)
                if value(use_auto_train) == 1 && st < 8 && feval(mfilename, obj, 'completion_test', st)
                    TrainingStage.value = STAGES{st + 1};
                    feval(mfilename, obj, 'reset_counters');
                    st = st + 1;
                    feval(mfilename, obj, 'apply_stage', st, true);
                    msg = sprintf('[trial %d] moved to stage "%s"', n, STAGES{st});
                    try CommentsSection(obj, 'append_line', msg); catch, end
                    fprintf(1, 'Arpit2StepTraining %s\n', msg);
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
    %   COMPLETION TEST for stage st -> true / false   (stages 1-7)
    % ------------------------------------------------------------------
    case 'completion_test'
        st = varargin{1};
        n  = n_done_trials + 0;
        done = false;
        stage_vr = value(stage_viol_trials) / max(1, value(stage_all_trials));
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
                done = cp >= value(S4_max_CP) - 1e-6 && n >= value(S4_min_session_trials) && ...
                       rv < value(recent_violation) && rt < value(recent_timeout) && ...
                       stage_vr < value(S4_stage_violation);
            case 5
                % Hold only: the sound / rule is not part of this criterion
                cp = SideSection(obj, 'get_cp');
                [rv, rt] = feval(mfilename, obj, 'recent_rates');
                done = cp >= value(S5_target_CP) - 1e-6 && value(stage_valid_trials) >= value(S5_min_trials) && ...
                       rv < value(recent_violation) && rt < value(recent_timeout) && ...
                       stage_vr < value(S5_stage_violation);
            case 6
                [rv, rt] = feval(mfilename, obj, 'recent_rates');
                done = value(stage_valid_trials) >= value(S6_min_trials) && ...
                       rv < value(recent_violation) && rt < value(recent_timeout) && ...
                       stage_vr < value(S6_stage_violation);
            case 7
                if feval(mfilename, obj, 'get_sound_level') == N_SND && value(block_level) == 0 && ...
                        strcmp(value(ab_phase), 'free')
                    first = max(value(ab_phase_start), value(random_since));
                    [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', value(S7_window), first);
                    strat = feval(mfilename, obj, 'strategy_check', first);
                    done = isempty(strat) && all(n_c >= value(S7_min_per_cell)) && all(hit_c >= value(S7_cell_thresh));
                end
        end
        varargout{1} = done;

    % ------------------------------------------------------------------
    %   SOUND_LEVEL_TEST: is sound level k passed?
    % ------------------------------------------------------------------
    case 'sound_level_test'
        k = varargin{1};
        if strcmpi(SOUND_LEVELS{k, 2}, 'Full'), thr = value(SND_thresh_full); else, thr = value(SND_thresh_discrete); end
        first = max(value(snd_level_start), value(random_since));
        [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', value(SND_window), first);
        varargout{1} = sum(n_c) >= value(SND_min_trials) && all(n_c >= value(SND_min_per_cell)) && all(hit_c >= thr);

    % ------------------------------------------------------------------
    %   AB7_CYCLE (stage 7, every trial): STRONG for ab_phase_len valid
    %   trials, then FREE (gentle) until a strategy shows, then STRONG again.
    % ------------------------------------------------------------------
    case 'ab7_cycle'
        n = varargin{1}; valid = varargin{2};
        if valid && ~isnan(cell_history(n))
            ab_phase_trials.value = value(ab_phase_trials) + 1;
        end
        if strcmp(value(ab_phase), 'strong')
            if value(ab_phase_trials) >= value(ab_phase_len)
                feval(mfilename, obj, 'ab7_switch', 'free', n, ...
                    sprintf('strong phase done (%d valid trials)', value(ab_phase_trials)));
            end
        else
            strat = feval(mfilename, obj, 'strategy_check', value(ab_phase_start));
            if ~isempty(strat)
                ab7_cycles.value = value(ab7_cycles) + 1;
                ab_phase_len.value = value(AB7_restrong);
                feval(mfilename, obj, 'ab7_switch', 'strong', n, ['strategy: ' strat]);
            end
        end

    case 'ab7_switch'
        % ab7_switch, new phase, trial, reason
        ph = varargin{1}; n = varargin{2};
        ab_phase.value = ph;
        ab_phase_trials.value = 0;
        ab_phase_start.value = n + 1;
        if strcmp(ph, 'strong'), pr = 'Strong'; else, pr = 'Gentle'; end
        AntibiasSection(obj, 'configure', 1, 'cells', NaN, pr);
        msg = sprintf('[trial %d] stage 7 antibias -> %s (%s)', n, upper(ph), varargin{3});
        try CommentsSection(obj, 'append_line', msg); catch, end
        fprintf(1, 'Arpit2StepTraining %s\n', msg);

    case 'strategy_check'
        % Returns '' or a description of the strategy seen over the last
        % AB7_probe_window valid 2-step trials from trial <first> on.
        % Empty while the window is not yet full.
        first = max(1, varargin{1});
        hh = value(hit_history); hh = hh(:);
        ca = value(category_history); ca = ca(:);
        ch = value(choice_history); ch = ch(:);
        lh = value(light_history); lh = lh(:);
        m = min([numel(hh) numel(ca) numel(ch) numel(lh)]);
        idx = first:m;
        v = idx(~isnan(hh(idx)) & ~isnan(ca(idx)) & (lh(idx) == 'l' | lh(idx) == 'r'));
        w = round(value(AB7_probe_window));
        s = '';
        if numel(v) >= w
            v = v(end-w+1:end);
            f = value(AB7_frac);
            fleft = mean(ch(v) == 'l');
            flit  = mean(ch(v) == lh(v));
            floud = mean((hh(v) == 1 & ca(v) == 1) | (hh(v) == 0 & ca(v) == 0));
            [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', w, first);
            gap = max(hit_c(n_c >= 5)) - min(hit_c(n_c >= 5));
            if fleft >= f || fleft <= 1 - f, s = sprintf('side (left %.2f)', fleft);
            elseif flit >= f || flit <= 1 - f, s = sprintf('light (lit port %.2f)', flit);
            elseif floud >= f || floud <= 1 - f, s = sprintf('category ("loud" %.2f)', floud);
            elseif ~isempty(gap) && gap >= value(AB7_cell_gap), s = sprintf('cells %s', mat2str(round(hit_c*100)/100));
            end
        end
        varargout{1} = s;
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
        if at_start && st <= 7
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
            case {5, 6, 7, 8}
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
                    % stages 6-8: hold drawn every trial in [S6_cp_min, S6_cp_max]
                    p.random_CP = 1;
                    p.increase_CP_training = 0;
                    p.cp_rand_min = value(S6_cp_min);
                    p.cp_rand_max = value(S6_cp_max);
                end
                % Blocks (stages 5-7 only)
                if st <= 7 && value(block_level) > 0
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
                if st <= 7
                    if at_start, p.error_iti = value(S_error_iti); end
                    % Sound (track B): Stimuli_State, levels, second chance
                    k = feval(mfilename, obj, 'get_sound_level');
                else
                    % Stage 8: as the experiment
                    if at_start
                        p.error_iti = value(S8_error_iti);
                        if ~strcmp(value(SoundLevel), SOUND_LEVELS{N_SND, 1})
                            SoundLevel.value = SOUND_LEVELS{N_SND, 1};
                            snd_level_sessions.value = 0;
                        end
                    end
                    p.MaxSame = Inf; p.MaxSameCat = Inf;
                    k = N_SND;
                end
                p.Stimuli_State   = SOUND_LEVELS{k, 2};
                p.reward_type     = SOUND_LEVELS{k, 4};
                p.secondhit_delay = SOUND_LEVELS{k, 5};
                if at_start
                    if ~isnan(SOUND_LEVELS{k, 3}), StimulusSection(obj, 'set_n_discrete', SOUND_LEVELS{k, 3}); end
                    switch st
                        case {5, 6}
                            AntibiasSection(obj, 'configure', 1, 'cells', value(S5_AB_floor), 'Standard');
                        case 7
                            if strcmp(value(ab_phase), 'strong'), pr = 'Strong'; else, pr = 'Gentle'; end
                            AntibiasSection(obj, 'configure', 1, 'cells', NaN, pr);
                        case 8
                            AntibiasSection(obj, 'configure', 0, 'cells', NaN, 'Standard');
                    end
                end
        end
        if st <= 4 && at_start
            AntibiasSection(obj, 'configure', 1, 'side', NaN, 'Standard');   % either side pays: act on the side
            p.random_CP = 0;
            p.block_len = 0;
        end
        SideSection(obj, 'set_stage_params', p);

    case 'apply_sound_level'
        % New sound level during a session (stages 5-7)
        k = feval(mfilename, obj, 'get_sound_level');
        p = struct('Stimuli_State', SOUND_LEVELS{k, 2}, 'reward_type', SOUND_LEVELS{k, 4}, ...
                   'secondhit_delay', SOUND_LEVELS{k, 5});
        if ~isnan(SOUND_LEVELS{k, 3}), StimulusSection(obj, 'set_n_discrete', SOUND_LEVELS{k, 3}); end
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
            st = feval(mfilename, obj, 'get_stage');
            stage_sessions.value = value(stage_sessions) + 1;
            if st >= 5 && st <= 7, snd_level_sessions.value = value(snd_level_sessions) + 1; end
            SideSection(obj, 'end_of_session');
            if st == 8
                feval(mfilename, obj, 'evaluate_test_session');
            end
            feval(mfilename, obj, 'check_fallback');
            if value(ready_for_test) == 1 && value(handover_done) == 0 && value(handover_on) == 1
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
        if st < 5 || st > 7 || value(block_level) > 0 || value(fallback_count) >= value(FB_max), return; end
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
    %   STAGE 8: judge today's session (called from end_of_session, after
    %   stage_sessions has counted it)
    % ------------------------------------------------------------------
    case 'evaluate_test_session'
        [fit, msg] = feval(mfilename, obj, 'session_bias_fit');
        hit_c = feval(mfilename, obj, 'cell_performance', Inf, 1);
        clear_bias = false;
        if isempty(fit)
            pass = false;
            res = ['FAIL: ' msg];
            fit = NaN(1, 7);
        else
            b = fit(1:3); se = fit(4:6); ntr = fit(7);
            reasons = {};
            if ntr < value(S8_min_trials),            reasons{end+1} = sprintf('%d trials', ntr); end
            if any(isnan(hit_c)) || any(hit_c < value(S8_cell_thresh))
                reasons{end+1} = sprintf('cells %s', mat2str(round(hit_c*100)/100));
            end
            % A CLEAR bias (or no use of the sound) sends the rat back to stage 7
            if ~(b(2) / se(2) > 2),                   reasons{end+1} = 'no stimulus effect'; clear_bias = true; end
            if abs(b(1)) > value(S8_max_bias) && abs(b(1)) / se(1) >= 2, reasons{end+1} = sprintf('category bias %.2f', b(1)); clear_bias = true;
            elseif abs(b(1)) > value(S8_max_bias) || abs(b(1)) / se(1) >= 2, reasons{end+1} = sprintf('weak category bias %.2f', b(1)); end
            if abs(b(3)) > value(S8_max_bias) && abs(b(3)) / se(3) >= 2, reasons{end+1} = sprintf('side bias %.2f', b(3)); clear_bias = true;
            elseif abs(b(3)) > value(S8_max_bias) || abs(b(3)) / se(3) >= 2, reasons{end+1} = sprintf('weak side bias %.2f', b(3)); end
            % too few trials: the fit is not trusted for sending the rat back
            if ntr < value(S8_min_trials), clear_bias = false; end
            pass = isempty(reasons);
            if pass
                res = sprintf('PASS (b0=%.2f b1=%.2f b2=%.2f, n=%d)', b(1), b(2), b(3), ntr);
            else
                res = ['FAIL: ' strjoin(reasons, ', ')];
            end
        end
        h = value(s8_results);
        s8_results.value = [h; fit(:)' double(pass)];
        r = value(s8_results);
        nlast = round(value(S8_last_pass));
        npass = 0;   % passing sessions in a row, ending with today
        for i = size(r, 1):-1:1
            if r(i, end) == 1, npass = npass + 1; else, break; end
        end
        res = sprintf('Session %d in stage 8: %s | passing in a row %d/%d', value(stage_sessions), res, npass, nlast);
        if clear_bias
            % back to stage 7, with a (shorter) STRONG antibias phase first
            s8_returns.value = value(s8_returns) + 1;
            TrainingStage.value = STAGES{7};
            feval(mfilename, obj, 'reset_counters');
            ab_phase_len.value = value(AB7_restrong);
            res = sprintf('%s -> BACK TO STAGE 7 (antibias), return #%d', res, value(s8_returns));
        elseif value(stage_sessions) >= value(S8_min_sessions) && npass >= nlast
            ready_for_test.value = 1;
            res = [res ' -> READY FOR TEST'];
        end
        S8_last_result.value = res;
        try CommentsSection(obj, 'append_line', ['Test: ' res]); catch, end
        fprintf(1, 'Arpit2StepTraining test: %s\n', res);
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
        if size(ss, 2) < 8, ss(:, end+1:8) = 0; end
        if size(ss, 1) < N_AUTO_STAGES, ss(end+1:N_AUTO_STAGES, :) = 0; end
        hr = @(h, v) iff_str(v > 0, sprintf('%.2f', h / max(v, 1)), '-');
        for k = 1:N_AUTO_STAGES
            if ss(k, 1) > 0
                str = sprintf('%d | %d | %d | %.2f | %.2f | %s | %s', ss(k,1), ss(k,2), ss(k,3), ss(k,4)/ss(k,1), ss(k,5)/ss(k,1), ...
                    hr(ss(k,6), ss(k,3)), hr(ss(k,8), ss(k,7)));
            else
                str = '-';
            end
            eval(sprintf('StageSummary_%d.value = str;', k));
        end
        if st > 0
            StageHit.value = sprintf('%s (today %s)', hr(ss(st,6), ss(st,3)), hr(ss(st,8), ss(st,7)));
        else
            StageHit.value = '-';
        end
        if st > 0 && ss(st, 1) > 0
            Stage_viol.value    = round(ss(st,4)/ss(st,1)*100)/100;
            Stage_timeout.value = round(ss(st,5)/ss(st,1)*100)/100;
        end
        % Sound level progress
        kl = feval(mfilename, obj, 'get_sound_level');
        if st >= 5 && st <= 7
            first = max(value(snd_level_start), value(random_since));
            [hit_c, n_c] = feval(mfilename, obj, 'cell_performance', value(SND_window), first);
            snd = sprintf('%d/%d, %d sess, cells %s (n %d)', kl, N_SND, value(snd_level_sessions), ...
                mat2str(round(hit_c*100)/100), sum(n_c));
            if value(block_level) > 0, snd = sprintf('%d/%d, %d sess, waits for blocks to end', kl, N_SND, value(snd_level_sessions)); end
        elseif st == 8
            snd = sprintf('%d/%d (fixed in stage 8)', N_SND, N_SND);
        else
            snd = sprintf('%d/%d (used from stage 5)', kl, N_SND);
        end
        SND_progress.value = snd;
        % Stage 7 antibias phase
        if st == 7
            if strcmp(value(ab_phase), 'strong')
                ph = sprintf('STRONG %d/%d', value(ab_phase_trials), value(ab_phase_len));
            else
                ph = sprintf('FREE, %d valid', value(ab_phase_trials));
            end
            AB7_phase_disp.value = sprintf('%s (cycles %d)', ph, value(ab7_cycles));
        else
            AB7_phase_disp.value = '-';
        end
        npass = 0; r = value(s8_results);
        for i = size(r, 1):-1:1
            if r(i, end) == 1, npass = npass + 1; else, break; end
        end
        if st == 0
            s = 'Manual (no automation)';
            brief = 'Manual';
        else
            brief = sprintf('%d valid, %d sess.', value(stage_valid_trials), value(stage_sessions));
            if st == 7
                if strcmp(value(ab_phase), 'strong'), brief = sprintf('%s, AB strong', brief);
                else, brief = sprintf('%s, AB free', brief); end
            elseif st == 8
                brief = sprintf('%d sess., pass %d/%d', value(stage_sessions), npass, round(value(S8_last_pass)));
                if value(ready_for_test) == 1, brief = 'READY FOR TEST'; end
            end
            s = sprintf('%s | valid %d | switches %d | sessions %d', value(TrainingStage), ...
                value(stage_valid_trials), value(stage_switches), value(stage_sessions));
            if n > 0
                s = sprintf('%s | recent viol %.2f to %.2f', s, rv, rt);
            end
            if st >= 5
                s = sprintf('%s | rule %s | sound %s', s, SideSection(obj, 'get_cue_rule'), snd);
            end
            if st >= 5 && st <= 7
                s = sprintf('%s | %s', s, feval(mfilename, obj, 'block_name', value(block_level)));
            end
            if st == 7
                s = sprintf('%s | antibias %s', s, value(AB7_phase_disp));
            elseif st == 8
                s = sprintf('%s | sessions %d/%d, passing in a row %d/%d', s, value(stage_sessions), ...
                    round(value(S8_min_sessions)), npass, round(value(S8_last_pass)));
                if value(ready_for_test) == 1, s = [s ' | READY FOR TEST']; end
                if value(handover_done) == 1, s = [s ' | handed over to Arpit2StepTask']; end
            end
        end
        StageStatus.value = s;
        StageBrief.value  = brief;
        k = find(strcmp(STAGES, value(TrainingStage)), 1); if isempty(k), k = numel(STAGES); end
        StageAbout.value  = STAGE_SHORT{k};

    case 'enable_controls'
        h = {TrainingStage, SoundLevel, use_auto_train, MaxSame_training, S1_trials, S1_switches, S2_trials, S2_switches, ...
            S2_RColl_max, S2_RColl_min, S2_RColl_step, S3_start_CP, S3_frac_increase, S3_min_trials, ...
            S4_max_CP, S4_frac_increase, S4_min_session_trials, S4_stage_violation, recent_violation, ...
            recent_timeout, recent_window, S5_AB_floor, S5_target_CP, S5_min_trials, S5_stage_violation, ...
            S_A1_time, S_error_iti, S6_cp_min, S6_cp_max, S6_min_trials, S6_stage_violation, ...
            SND_window, SND_min_per_cell, SND_min_trials, SND_thresh_discrete, SND_thresh_full, ...
            S7_cell_thresh, S7_window, S7_min_per_cell, AB7_strong_trials, AB7_restrong, AB7_probe_window, ...
            AB7_frac, AB7_cell_gap, S8_min_sessions, S8_last_pass, S8_min_trials, S8_cell_thresh, ...
            S8_max_bias, S8_error_iti, S1_go_start, S1_go_vol_start, S1_go_vol_end, ...
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


% -----------------------------------------------------------------------
% Size a pop-up window to its controls (BControl places them in pixels
% from the bottom-left). Returns the y of the free row above them.
function top = fit_window(fig, width, extra)
if nargin < 3, extra = 0; end
h = findall(fig, 'type', 'uicontrol');
top = 0;
for k = 1:numel(h)
    p = get(h(k), 'Position');
    if strcmp(get(h(k), 'Units'), 'pixels'), top = max(top, p(2) + p(4)); end
end
top = top + 8;
pos = get(fig, 'Position');
set(fig, 'Units', 'pixels', 'Position', [pos(1) pos(2) width top + 30 + extra]);


function s = iff_str(c, a, b)
if c, s = a; else, s = b; end
