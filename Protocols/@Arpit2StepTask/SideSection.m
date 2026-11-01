% [x, y] = SideSection(obj, action, x, y)   --  Arpit2StepTask (experiment)
%
% Trial generation and scoring. Same file as in Arpit2StepTraining with the
% training parts fixed to their experiment values (TrialMode TwoStep, centre
% poke required, choice time limited, no blocks, no CP growth); those are
% plain values here, not controls. Parameter names are unchanged so a rat's
% values carry over from training.
%
% Each trial: a cell is drawn (reward side x category, 4-cell antibias,
% default OFF), the lit side follows from CueRule. In 'No Sound' and
% 'Fixed Stimuli' modes the cell is still drawn (matched statistics, 50%
% reward) and antibias is not applied.
%
% Per-trial histories: previous_sides, choice_history, light_history,
% category_history, cell_history, block_history (always NaN here),
% hit / violation / timeout_history.

function [x, y] = SideSection(obj, action, x, y)

GetSoloFunctionArgs(obj);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------
    case 'init'

        SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);

        [x, y] = AntibiasSection(obj, 'init', x, y);

        MenuParam(obj, 'MaxSame', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, Inf}, Inf, x, y, ...
            'TooltipString', sprintf(['\nTwoStep: max consecutive trials with the same reward side.\n' ...
            'Shaping: max consecutive rewarded pokes on the same side before only\n' ...
            'the other side pays. Overrides antibias.'])); next_row(y);
        MenuParam(obj, 'MaxSameCat', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, Inf}, Inf, x, y, ...
            'label', 'MaxSame Cat', 'TooltipString', ...
            'TwoStep: max consecutive trials with the same category (loud/quiet). Overrides antibias.'); next_row(y);
        % No blocks in the experiment (kept as fixed values for the shared code)
        SoloParamHandle(obj, 'block_jitter', 'value', 0.25);
        SoloParamHandle(obj, 'block_len', 'value', 0);
        NumeditParam(obj, 'left_wtr_mult', 1, x, y, 'TooltipString', 'all left reward times are multiplied by this number'); next_row(y);
        NumeditParam(obj, 'right_wtr_mult', 1, x, y, 'TooltipString', 'all right reward times are multiplied by this number'); next_row(y);
        DispParam(obj, 'ThisLight',    'NONE',   x, y, 'label', 'Lit side');    next_row(y);
        DispParam(obj, 'ThisCategory', 'NONE',   x, y, 'label', 'Category');    next_row(y);
        DispParam(obj, 'ThisTrial',    'EITHER', x, y, 'label', 'Reward side'); next_row(y);
        SubheaderParam(obj, 'title', 'Sides Section', x, y);
        next_row(y, 1.2);
        x_now = x; y_now = y;

        % Per-trial histories
        SoloParamHandle(obj, 'previous_sides',   'value', '');
        SoloParamHandle(obj, 'choice_history',   'value', '');
        SoloParamHandle(obj, 'light_history',    'value', '');
        SoloParamHandle(obj, 'category_history', 'value', []);
        SoloParamHandle(obj, 'cell_history',     'value', []);
        DeclareGlobals(obj, 'ro_args', {'previous_sides', 'choice_history', 'light_history', ...
            'category_history', 'cell_history'});
        SoloParamHandle(obj, 'this_cell', 'value', NaN);   % cell of the trial being prepared
        % Per-trial values that are not GUI parameters. Dispatcher only keeps a
        % per-trial history of GUI parameters, so these are pushed explicitly
        % every trial ('push_trial_history', called from the main file).
        SoloParamHandle(obj, 'this_cell_probs', 'value', NaN(1,4)); % cell probabilities actually used (after antibias + MaxSame)
        SoloParamHandle(obj, 'this_beta',       'value', NaN);      % antibias beta actually used
        SoloParamHandle(obj, 'this_water',      'value', NaN(1,3)); % [water uL, left valve s, right valve s]
        % Blocks (TwoStep): runs of the same category. block_len is the nominal
        % length (0 = random order); each block's actual length is jittered.
        SoloParamHandle(obj, 'block_id',      'value', 0);
        SoloParamHandle(obj, 'block_pos',     'value', 0);     % valid trials done in the current block
        SoloParamHandle(obj, 'block_cur_len', 'value', 0);     % jittered length of the current block
        SoloParamHandle(obj, 'block_cat',     'value', NaN);   % 1 loud, 0 quiet
        SoloParamHandle(obj, 'this_block',    'value', NaN(1,5)); % [block id, position, length, category, is switch trial]
        SoloParamHandle(obj, 'block_history', 'value', zeros(0,5)); % one row per trial, NaN when not in blocks
        DeclareGlobals(obj, 'ro_args', {'block_history'});

        next_column(x); y = 5;

        % ---- Trial structure (fixed in the experiment) ----
        SoloParamHandle(obj, 'TrialMode', 'value', 'TwoStep');
        SoloParamHandle(obj, 'CentrePokeRequired', 'value', 1);
        SoloParamHandle(obj, 'ChoiceTimeLimited', 'value', 1);
        SoloParamHandle(obj, 'ShapingLights', 'value', 'Both dark');
        % ---- Reward ----
        MenuParam(obj, 'reward_type', {'Always', 'DelayedReward', 'NoReward'}, 'NoReward', x, y, 'labelfraction', 0.35, ...
            'TooltipString', sprintf(['\nWhat happens after a wrong first poke (TwoStep / forced shaping trials):\n' ...
            'Always: reward still available at the correct port\n' ...
            'DelayedReward: available after SecondHit Delay\n' ...
            'NoReward: error ITI, no reward']));
        set_callback(reward_type, {mfilename, 'new_reward_type'}); next_row(y);
        NumeditParam(obj, 'secondhit_delay', 0, x, y, 'label', 'SecondHit Delay', 'TooltipString', 'Reward delay after a wrong first poke if reward_type = DelayedReward'); next_row(y);
        NumeditParam(obj, 'RewardCollection_duration', 10, x, y, 'label', 'RColl_dur', 'TooltipString', 'Time allowed for the side choice (if limited) and for the second chance'); next_row(y);
        NumeditParam(obj, 'reward_delay', 0.01, x, y, 'label', 'Reward Delay', 'TooltipString', 'Delay between side poke and reward delivery'); next_row(y);
        NumeditParam(obj, 'drink_time', 1, x, y, 'label', 'Drink Time', 'TooltipString', 'waits to finish water delivery'); next_row(y);
        NumeditParam(obj, 'error_iti', 7, x, y, 'label', 'Error Timeout', 'TooltipString', 'Time-out after a wrong first poke (NoReward)'); next_row(y);
        SoloParamHandle(obj, 'go_sound_on', 'value', 1);

        % ---- Centre poke ----
        NumeditParam(obj, 'CenterLed_duration', 200, x, y, 'label', 'C_LED dur', 'TooltipString', 'Time to start a centre poke before timeout'); next_row(y);
        NumeditParam(obj, 'violation_iti', 1, x, y, 'label', 'Violation Timeout', 'TooltipString', 'Centre poke violation duration'); next_row(y);
        NumeditParam(obj, 'timeout_iti', 1, x, y, 'label', 'Timeout ITI', 'TooltipString', 'ITI on timeout trials'); next_row(y);
        NumeditParam(obj, 'legal_cbreak', 0.1, x, y, 'position', [x, y, 175 20], 'TooltipString', 'Time in sec for which it is ok to be outside the center port before a violation occurs.');
        ToggleParam(obj, 'LED_during_legal_cbreak', 1, x, y, 'OnString', 'LED ON LcB', 'OffString', 'LED off LcB', ...
            'position', [x+180 y 20 20], 'TooltipString', 'If 1 (black), turn center port LED back on during legal_cbreak');
        next_row(y);
        NumeditParam(obj, 'SettlingIn_time', 0.2, x, y, 'position', [x, y, 175 20], 'TooltipString', 'Initial settling period during which breaks are tolerated');
        ToggleParam(obj, 'LED_during_settling_legal_cbreak', 0, x, y, 'OnString', 'LED ON SetLcB', 'OffString', 'LED OFF setLcB', ...
            'position', [x+180 y 20 20], 'TooltipString', 'If 1 (black), turn center port LED back on during settling breaks');
        next_row(y);

        % PreStim
        NumeditParam(obj, 'PreStim_time_Min', 0.20, x, y, 'label', 'Pre-Stim Min', 'TooltipString', 'Min Time in NIC before starting the stimulus');
        set_callback(PreStim_time_Min, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'PreStim_time', 0.20, x, y, 'position', [x, y, 175 20], 'label', 'Pre-Stim time', 'TooltipString', 'Actual Time in NIC before starting the stimulus');
        set_callback(PreStim_time, {mfilename, 'new_CP_duration'});
        ToggleParam(obj, 'random_PreStim_time', 1, x, y, 'position', [x+180 y 20 20], ...
            'OnString', 'random PreStim_time ON', 'OffString', 'random PreStim_time OFF', ...
            'TooltipString', 'If on (black) then it enables the random time between the user given range');
        set_callback(random_PreStim_time, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'PreStim_time_Max', 1, x, y, 'label', 'Pre-Stim Max', 'TooltipString', 'Max Time in NIC before starting the stimulus');
        set_callback(PreStim_time_Max, {mfilename, 'new_CP_duration'}); next_row(y);
        % A1 time
        NumeditParam(obj, 'A1_time_Min', 0.1, x, y, 'label', 'Min time AUD1', 'TooltipString', 'Min stimulus duration');
        set_callback(A1_time_Min, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'A1_time', 0.4, x, y, 'position', [x, y, 175 20], 'label', 'AUD1 Time', 'TooltipString', 'Actual stimulus duration');
        set_callback(A1_time, {mfilename, 'new_CP_duration'});
        ToggleParam(obj, 'random_A1_time', 1, x, y, 'position', [x+180 y 20 20], ...
            'OnString', 'random A1_time ON', 'OffString', 'random A1_time OFF', ...
            'TooltipString', 'If on (black) then it enables the random sampling of A1_time');
        set_callback(random_A1_time, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'A1_time_Max', 0.4, x, y, 'label', 'Max time AUD1', 'TooltipString', 'Max stimulus duration');
        set_callback(A1_time_Max, {mfilename, 'new_CP_duration'}); next_row(y);
        % Time between stimulus and go cue
        NumeditParam(obj, 'time_bet_aud1_gocue_Min', 0.2, x, y, 'label', 'Min A1-Go time', 'TooltipString', 'Min time between stimulus end and go cue');
        set_callback(time_bet_aud1_gocue_Min, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'time_bet_aud1_gocue', 0.4, x, y, 'position', [x, y, 175 20], 'label', 'A1-GoCue time', 'TooltipString', 'Actual time between stimulus end and go cue');
        set_callback(time_bet_aud1_gocue, {mfilename, 'new_CP_duration'});
        ToggleParam(obj, 'random_prego_time', 1, x, y, 'position', [x+180 y 20 20], ...
            'OnString', 'random prego_time ON', 'OffString', 'random prego_time OFF', ...
            'TooltipString', 'If on (black) then it enables the random sampling of the stimulus-go cue time');
        set_callback(random_prego_time, {mfilename, 'new_CP_duration'}); next_row(y);
        NumeditParam(obj, 'time_bet_aud1_gocue_Max', 1, x, y, 'label', 'Max A1-Go time', 'TooltipString', 'Max time between stimulus end and go cue');
        set_callback(time_bet_aud1_gocue_Max, {mfilename, 'new_CP_duration'}); next_row(y);

        DispParam(obj, 'init_CP_duration', 0.01, x, y, 'label', 'init_CP duration', 'TooltipString', 'CP duration on the first trial of a session when warmup is on'); next_row(y);
        DispParam(obj, 'CP_duration', PreStim_time + A1_time + time_bet_aud1_gocue, x, y, 'label', 'CP duration', 'TooltipString', 'Nose-in-centre time before the go cue'); next_row(y);
        NumeditParam(obj, 'time_go_cue', 0.2, x, y, 'label', 'Go Cue Duration', 'TooltipString', 'duration of go cue');
        set_callback(time_go_cue, {mfilename, 'new_time_go_cue'}); next_row(y);
        DispParam(obj, 'Total_CP_duration', CP_duration + time_go_cue, x, y, 'TooltipString', 'CP_duration + go cue duration'); %#ok<*NODEF>
        next_row(y, 1.5);

        MenuParam(obj, 'Stimuli_State', {'Full', 'Discrete', 'Fixed Stimuli', 'No Sound'}, 'Full', x, y, ...
            'label', 'Stimuli State', 'labelfraction', 0.35, 'TooltipString', sprintf(['\nFull: continuous distribution\n' ...
            'Discrete: n levels per category\nFixed Stimuli: one sound (control)\nNo Sound: control / shaping']));
        set_callback(Stimuli_State, {mfilename, 'stim_state_change'});
        next_row(y);
        SubheaderParam(obj, 'timing_title', 'Trial timing & sound', x, y);

        SoloFunctionAddVars('StimulusSection', 'ro_args', ...
            {'ThisTrial'; 'ThisCategory'; 'Stimuli_State'; 'A1_time'; 'time_bet_aud1_gocue'; 'PreStim_time'});

        [x, y] = SoundSection(obj, 'init', x_now, y_now);
        [x, y] = StimulusSection(obj, 'init', x, y); next_row(y, 0.5);
        x_col2 = x; y_col2 = y;     % returned: the main file continues column 2 here

        SoloFunctionAddVars('PsychometricSection', 'ro_args', {'Stimuli_State'});
        SoloFunctionAddVars('StimulatorSection', 'ro_args', ...
            {'A1_time'; 'time_bet_aud1_gocue'; 'time_go_cue'; 'PreStim_time'; 'CP_duration'; 'Total_CP_duration'});
        feval(mfilename, obj, 'new_reward_type');
        x = x_col2; y = y_col2;

    % ------------------------------------------------------------------
    %   INIT_CONTROLS: column 4 of the main window (names unchanged,
    %   only where they are drawn moved)
    % ------------------------------------------------------------------
    case 'init_controls'
        % ---- Centre poke (hold) ----
        % No CP growth in the experiment (fixed values for the shared code)
        SoloParamHandle(obj, 'increase_CP_training', 'value', 0);
        SoloParamHandle(obj, 'cp_start', 'value', 1.5);
        SoloParamHandle(obj, 'cp_end', 'value', 2.2);
        SoloParamHandle(obj, 'fraction_increase', 'value', 0);
        NumeditParam(obj, 'cp_reached', 1.5, x, y, 'label', 'CP reached', 'TooltipString', 'CP reached at the end of the last session (updated automatically at end of session)'); next_row(y);
        NumeditParam(obj, 'cp_rand_min', 1.5, x, y, 'position', [x y 100 20], 'label', 'CP min');
        NumeditParam(obj, 'cp_rand_max', 2.2, x, y, 'position', [x+100 y 100 20], 'label', 'CP max'); next_row(y);
        ToggleParam(obj, 'random_CP', 1, x, y, 'OnString', 'Random hold ON', 'OffString', 'Random hold OFF', ...
            'TooltipString', 'If on, the hold is drawn every trial uniformly in [CP min, CP max]; if off, it is the sum of the PreStim / A1 / A1-GoCue times'); next_row(y);
        ToggleParam(obj, 'warmup_on', 1, x, y, 'OnString', 'Warmup ON', 'OffString', 'Warmup OFF', ...
            'TooltipString', 'At session start CP_duration starts small and grows to cp_reached over 10 trials'); next_row(y);
        SubheaderParam(obj, 'cp_title', 'Centre poke (hold)', x, y); next_row(y, 1.2);

        % ---- Trial structure ----
        MenuParam(obj, 'CueRule', {'Loud->Lit', 'Loud->Dark'}, 'Loud->Lit', x, y, 'label', 'Cue rule', ...
            'labelfraction', 0.35, 'TooltipString', sprintf(['\nLoud->Lit: loud = go to the lit port, quiet = go to the dark port.\n' ...
            'Loud->Dark: loud = go to the dark port, quiet = go to the lit port.'])); next_row(y);
        MenuParam(obj, 'CueMode', {'Light/Dark', 'Color'}, 'Light/Dark', x, y, 'label', 'Cue mode', ...
            'labelfraction', 0.35, 'TooltipString', sprintf(['\nLight/Dark: target side LED on, other off.\n' ...
            'Color: lit side shows the port LED, other side shows the alternative colour\n' ...
            '(needs DIOLINES left1led_alt / right1led_alt in Settings_Custom.conf; untested).'])); next_row(y);
        SubheaderParam(obj, 'trial_title', 'Trial structure', x, y); next_row(y, 1.2);

        SoloFunctionAddVars('Arpit2StepTaskSMA', 'ro_args', ...
            {'CP_duration'; 'CenterLed_duration'; 'RewardCollection_duration'; ...
            'legal_cbreak'; 'LED_during_legal_cbreak'; 'SettlingIn_time'; 'LED_during_settling_legal_cbreak'; ...
            'time_go_cue'; 'timeout_iti'; 'Stimuli_State'; 'A1_time'; 'time_bet_aud1_gocue'; 'PreStim_time'; ...
            'drink_time'; 'reward_delay'; 'reward_type'; 'secondhit_delay'; 'error_iti'; 'violation_iti'; 'CueMode'; ...
            'go_sound_on'});

        % (the main file calls 'init_lock' and then 'User_Control')

    case 'init_lock'
        ToggleParam(obj, 'control_active', 0, x, y, 'OnString', 'Unlocked: click to lock', ...
            'OffString', 'Locked: click to edit', 'TooltipString', ...
            'Unlock to change the cue rule, the CP settings or the experiment group. Prevents accidental clicks.');
        set_callback(control_active, {mfilename, 'User_Control'}); next_row(y, 1.2);

    % ------------------------------------------------------------------
    %              CALLBACKS
    % ------------------------------------------------------------------
    case 'stim_state_change'
        StimulusSection(obj, 'Stimuli_State_change');
        PsychometricSection(obj, 'Stimuli_State_changed');

    case 'User_Control'
        h = {CueRule, CueMode, random_PreStim_time, random_A1_time, random_prego_time, warmup_on, ...
            cp_reached, MaxSame, MaxSameCat, random_CP, cp_rand_min, cp_rand_max};
        for i = 1:numel(h)
            if value(control_active) == 1, enable(h{i}); else, disable(h{i}); end
        end
        ExperimentGroupSection(obj, 'enable_controls', value(control_active));

    case 'new_CP_duration'
        if random_PreStim_time == 1, make_visible(PreStim_time_Min); make_visible(PreStim_time_Max);
        else,                        make_invisible(PreStim_time_Min); make_invisible(PreStim_time_Max); end
        if random_A1_time == 1, make_visible(A1_time_Min); make_visible(A1_time_Max);
        else,                   make_invisible(A1_time_Min); make_invisible(A1_time_Max); end
        if random_prego_time == 1, make_visible(time_bet_aud1_gocue_Min); make_visible(time_bet_aud1_gocue_Max);
        else,                      make_invisible(time_bet_aud1_gocue_Min); make_invisible(time_bet_aud1_gocue_Max); end

        if random_PreStim_time == 1 && (value(PreStim_time) < value(PreStim_time_Min) || value(PreStim_time) > value(PreStim_time_Max))
            PreStim_time.value = value(PreStim_time_Min);
        end
        if random_A1_time == 1 && (value(A1_time) < value(A1_time_Min) || value(A1_time) > value(A1_time_Max))
            A1_time.value = value(A1_time_Min);
        end
        if random_prego_time == 1 && (value(time_bet_aud1_gocue) < value(time_bet_aud1_gocue_Min) || value(time_bet_aud1_gocue) > value(time_bet_aud1_gocue_Max))
            time_bet_aud1_gocue.value = value(time_bet_aud1_gocue_Min);
        end
        CP_duration.value = value(SettlingIn_time) + value(PreStim_time) + value(A1_time) + value(time_bet_aud1_gocue);
        Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU>


    case 'new_time_go_cue'
        Total_CP_duration.value = value(CP_duration) + value(time_go_cue);
        SoundInterface(obj, 'set', 'GoSound', 'Dur1', value(time_go_cue));

    case 'new_reward_type'
        if strcmp(reward_type, 'DelayedReward')
            enable(secondhit_delay);
        else
            secondhit_delay.value = 0;
            disable(secondhit_delay);
        end


    % ------------------------------------------------------------------
    %              PREPARE NEXT TRIAL
    % ------------------------------------------------------------------
    case 'prepare_next_trial'

        % Apply the lock state after the settings have loaded
        if n_done_trials == 0
            feval(mfilename, obj, 'User_Control');
        end

        % 1. Score the trial that just finished (trial n_done_trials)
        if n_done_trials > 0
            feval(mfilename, obj, 'score_last_trial');
        end

        % 2. Stage logic (may change TrialMode, CP training, stimuli, antibias)
        ExperimentGroupSection(obj, 'prepare_next_trial');   % distribution schedule

        % 3. Centre poke duration (warm-up and CP growth)
        feval(mfilename, obj, 'update_cp_duration');

        % 4. Draw the next trial
        if strcmp(value(TrialMode), 'Shaping')
            feval(mfilename, obj, 'draw_shaping_trial');
        else
            feval(mfilename, obj, 'draw_twostep_trial');
        end

    % ------------------------------------------------------------------
    case 'score_last_trial'
        n = n_done_trials;
        was_viol = false; was_timeout_state = false; choice = 'n';
        if ~isempty(parsed_events) && isfield(parsed_events, 'states')
            st = parsed_events.states;
            if isfield(st, 'violation_state'), was_viol = rows(st.violation_state) > 0; end
            if isfield(st, 'timeout_state'),   was_timeout_state = rows(st.timeout_state) > 0; end
            % Only one of choice_left / choice_right is entered per trial
            % (second-chance pokes go straight to the hit states).
            t_l = Inf; t_r = Inf;
            if isfield(st, 'choice_left')  && rows(st.choice_left)  > 0, t_l = st.choice_left(1,1);  end
            if isfield(st, 'choice_right') && rows(st.choice_right) > 0, t_r = st.choice_right(1,1); end
            if t_l < t_r, choice = 'l'; elseif t_r < t_l, choice = 'r'; end
        end
        % A timeout counts only if the rat never chose a side
        was_timeout = was_timeout_state && choice == 'n' && ~was_viol;

        reward_side = feval(mfilename, obj, 'get_current_side');   % still describes trial n
        if was_viol || was_timeout || choice == 'n'
            was_hit = NaN;
        elseif reward_side == 'e'
            was_hit = 1;
        else
            was_hit = double(choice == reward_side);
        end

        vh = value(violation_history); vh(n) = was_viol;    violation_history.value = vh;
        th = value(timeout_history);   th(n) = was_timeout; timeout_history.value   = th;
        hh = value(hit_history);       hh(n) = was_hit;     hit_history.value       = hh;

        ps = value(previous_sides); ps(n) = reward_side; previous_sides.value = ps;
        ch = value(choice_history); ch(n) = choice;      choice_history.value = ch;
        lh = value(light_history);
        switch value(ThisLight)
            case 'LEFT',  lh(n) = 'l';
            case 'RIGHT', lh(n) = 'r';
            case 'BOTH',  lh(n) = 'b';
            otherwise,    lh(n) = 'n';
        end
        light_history.value = lh;
        cat_h = value(category_history);
        switch value(ThisCategory)
            case 'LOUD',  cat_h(n) = 1;
            case 'QUIET', cat_h(n) = 0;
            otherwise,    cat_h(n) = NaN;
        end
        category_history.value = cat_h;
        ce = value(cell_history); ce(n) = value(this_cell); cell_history.value = ce;
        bh = value(block_history); bh(n, :) = value(this_block); block_history.value = bh;
        tb = value(this_block);
        if ~isnan(tb(1)) && ~isnan(was_hit)
            block_pos.value = value(block_pos) + 1;
        end

    % ------------------------------------------------------------------
    case 'update_cp_duration'
        % Hold (CP_duration) for the next trial:
        %   warm-up (first 10 trials of a session, if warmup_on)
        %   random_CP:            uniform in [cp_rand_min, cp_rand_max]   (stages 6-7)
        %   increase_CP_training: grows by fraction_increase per valid trial up to cp_end
        %   otherwise:            sum of the PreStim / A1 / A1-GoCue settings
        % TwoStep trials split the hold with a FIXED stimulus length A1_time:
        %   CP = SettlingIn + PreStim + A1 + A1-GoCue,  PreStim random in
        %   [PreStim_time_Min, available - A1-GoCue Min] if random_PreStim_time,
        %   A1-GoCue = the remainder.
        two_step = strcmp(value(TrialMode), 'TwoStep');
        min_two_step = value(SettlingIn_time) + value(PreStim_time_Min) + value(A1_time) + value(time_bet_aud1_gocue_Min);
        if random_CP == 1, target = value(cp_rand_min); else, target = value(cp_reached); end
        have_cp = true;
        if warmup_on == 1 && n_done_trials <= 10
            cp_min = max(0.5, value(SettlingIn_time) + value(legal_cbreak));
            if n_done_trials == 0
                CP_duration.value = value(init_CP_duration);
            else
                cp_delta = (target - value(init_CP_duration)) / 10;
                CP_duration.value = max(cp_min, value(init_CP_duration) + cp_delta * n_done_trials);
            end
        elseif random_CP == 1
            CP_duration.value = value(cp_rand_min) + rand(1) * (value(cp_rand_max) - value(cp_rand_min));
        elseif increase_CP_training == 1
            if n_done_trials > 0 && ~violation_history(end) && ~timeout_history(end) && value(CP_duration) < value(cp_end)
                CP_duration.value = value(CP_duration) * (1 + value(fraction_increase));
            end
            CP_duration.value = min(max(value(CP_duration), value(cp_start)), value(cp_end));
        else
            have_cp = false;
        end

        if two_step
            % the sound must fit in the hold
            if have_cp
                CP_duration.value = max(value(CP_duration), min_two_step);
            end
            feval(mfilename, obj, 'split_two_step_hold', have_cp);
        else
            if have_cp
                fixed_CP_length = 1;
                cp_length = value(CP_duration) - value(SettlingIn_time);
            else
                fixed_CP_length = 0;
                cp_length = 3;   % not used when fixed_CP_length == 0
            end
            if cp_length >= 0.3
                [PreStim_time.value, A1_time.value, time_bet_aud1_gocue.value] = Calculate_CentrePoke_Params(fixed_CP_length, ...
                    cp_length, value(PreStim_time_Min), value(PreStim_time_Max), random_PreStim_time, value(PreStim_time), ...
                    value(A1_time_Min), value(A1_time_Max), random_A1_time, value(A1_time), value(time_bet_aud1_gocue_Min), ...
                    value(time_bet_aud1_gocue_Max), random_prego_time, value(time_bet_aud1_gocue));
                CP_duration.value = value(SettlingIn_time) + value(PreStim_time) + value(A1_time) + value(time_bet_aud1_gocue);
            end
        end
        Total_CP_duration.value = value(CP_duration) + value(time_go_cue);

    case 'split_two_step_hold'
        % x = true: CP_duration is given, split it. false: build CP from the settings.
        if ~x
            CP_duration.value = value(SettlingIn_time) + value(PreStim_time) + value(A1_time) + value(time_bet_aud1_gocue);
            return;
        end
        avail = value(CP_duration) - value(SettlingIn_time) - value(A1_time);   % PreStim + A1-GoCue
        lo = value(PreStim_time_Min);
        hi = avail - value(time_bet_aud1_gocue_Min);
        if random_PreStim_time == 1 && hi > lo
            hi = min(hi, max(lo, value(PreStim_time_Max)));
            pre = lo + rand(1) * (hi - lo);
        else
            pre = min(max(value(PreStim_time), lo), max(lo, hi));
        end
        PreStim_time.value = pre;
        time_bet_aud1_gocue.value = max(0, avail - pre);
        CP_duration.value = value(SettlingIn_time) + value(PreStim_time) + value(A1_time) + value(time_bet_aud1_gocue);

    % ------------------------------------------------------------------
    case 'draw_shaping_trial'
        this_cell.value = NaN;
        this_block.value = NaN(1, 5);
        this_cell_probs.value = NaN(1,4);
        this_beta.value = NaN;
        ThisCategory.value = 'NONE';

        switch value(ShapingLights)
            case 'Both lit',  ThisLight.value = 'BOTH';
            case 'Both dark', ThisLight.value = 'NONE';
            otherwise
                if rand(1) < 0.5, ThisLight.value = 'BOTH'; else, ThisLight.value = 'NONE'; end
        end

        % Side-bias guard: if the last MaxSame rewarded pokes were all on one
        % side, only the other side pays on this trial.
        ThisTrial.value = 'EITHER';
        ms = value(MaxSame);
        if ~isinf(ms) && n_done_trials > 0
            hh = value(hit_history); ch = value(choice_history);
            rewarded = find(hh(:)' == 1 & (ch(:)' == 'l' | ch(:)' == 'r'));
            if numel(rewarded) >= ms
                last = ch(rewarded(end-ms+1:end));
                if all(last == 'l'),     ThisTrial.value = 'RIGHT';
                elseif all(last == 'r'), ThisTrial.value = 'LEFT';
                end
            end
        end

    % ------------------------------------------------------------------
    case 'draw_twostep_trial'
        % Cell probabilities: antibias only in the sound modes Full / Discrete
        if ismember(value(Stimuli_State), {'Full', 'Discrete'})
            AntibiasSection(obj, 'update', value(hit_history), value(cell_history));
            p = AntibiasSection(obj, 'get_probs');
            this_beta.value = AntibiasSection(obj, 'get_beta');
        else
            p = [0.25 0.25 0.25 0.25];
            this_beta.value = 0;
        end

        % Blocks: fix the category for the whole block
        in_block = value(block_len) > 0;
        if in_block
            if value(block_id) == 0 || value(block_pos) >= value(block_cur_len)
                block_id.value = value(block_id) + 1;
                if value(block_id) == 1 || isnan(value(block_cat))
                    block_cat.value = double(rand(1) < 0.5);
                else
                    block_cat.value = 1 - value(block_cat);       % alternate loud / quiet
                end
                L = value(block_len); j = min(max(value(block_jitter), 0), 0.9);
                block_cur_len.value = max(2, round(L * (1 - j + 2 * j * rand(1))));
                block_pos.value = 0;
            end
            is_switch = double(value(block_pos) == 0 && value(block_id) > 1);
            this_block.value = [value(block_id), value(block_pos) + 1, value(block_cur_len), value(block_cat), is_switch];
            cat_cells = [1 3] + value(block_cat);   % quiet: cells 1,3   loud: cells 2,4
        else
            this_block.value = NaN(1, 5);
        end

        % MaxSame on reward side and MaxSameCat on category, over the
        % generated sequence of 2-step trials (valid or not).
        % (MaxSameCat is not applied in blocks.)
        ce = value(cell_history); ce = ce(~isnan(ce));
        ms = value(MaxSame);
        if ~isinf(ms) && numel(ce) >= ms
            last = ce(end-ms+1:end);
            if all(last <= 2), p([1 2]) = 0; elseif all(last >= 3), p([3 4]) = 0; end
        end
        mc = value(MaxSameCat);
        if ~in_block && ~isinf(mc) && numel(ce) >= mc
            last = ce(end-mc+1:end);
            if all(mod(last, 2) == 0), p([2 4]) = 0; elseif all(mod(last, 2) == 1), p([1 3]) = 0; end
        end
        if in_block
            q = zeros(1, 4); q(cat_cells) = p(cat_cells);
            if sum(q) <= 0, q(cat_cells) = 0.5; end   % MaxSame removed both: keep the block category
            p = q;
        end
        if sum(p) <= 0, p = [0.25 0.25 0.25 0.25]; end
        p = p / sum(p);
        this_cell_probs.value = p;
        c = find(rand(1) <= cumsum(p), 1, 'first');
        if isempty(c), c = 4; end
        this_cell.value = c;

        if c <= 2, reward_side = 'l'; else, reward_side = 'r'; end
        is_loud = (mod(c, 2) == 0);
        if is_loud, ThisCategory.value = 'LOUD'; else, ThisCategory.value = 'QUIET'; end
        if reward_side == 'l', ThisTrial.value = 'LEFT'; else, ThisTrial.value = 'RIGHT'; end

        % Does this category point to the lit port?
        goes_to_lit = (is_loud && strcmp(value(CueRule), 'Loud->Lit')) || ...
                      (~is_loud && strcmp(value(CueRule), 'Loud->Dark'));
        if goes_to_lit
            lit = reward_side;
        elseif reward_side == 'l'
            lit = 'r';
        else
            lit = 'l';
        end
        if lit == 'l', ThisLight.value = 'LEFT'; else, ThisLight.value = 'RIGHT'; end

    % ------------------------------------------------------------------
    %              GETTERS
    % ------------------------------------------------------------------
    case 'get_trial_info'
        ti.reward_side = feval(mfilename, obj, 'get_current_side');
        ti.category    = value(ThisCategory);
        switch value(ThisLight)
            case 'LEFT',  ti.light = 'l';
            case 'RIGHT', ti.light = 'r';
            case 'BOTH',  ti.light = 'b';
            otherwise,    ti.light = 'n';
        end
        ti.trial_mode      = value(TrialMode);
        ti.centre_required = value(CentrePokeRequired);
        ti.choice_limited  = value(ChoiceTimeLimited);
        x = ti;

    case 'get_current_side'
        switch value(ThisTrial)
            case 'LEFT',  x = 'l';
            case 'RIGHT', x = 'r';
            otherwise,    x = 'e';
        end

    case 'get_left_prob'
        x = 0.5;   % category probability, used by StimulusSection plotting

    case 'get_cp'
        x = value(CP_duration);

    case 'get_cp_reached'
        x = value(cp_reached);

    case 'get_settle_max'
        % Longest hold that still uses the short (no-violation) state machine
        x = value(SettlingIn_time) + value(legal_cbreak);

    case 'get_rcoll'
        x = value(RewardCollection_duration);

    case 'get_cue_rule'
        x = value(CueRule);

    case 'get_water_mult'
        x = value(left_wtr_mult);
        y = value(right_wtr_mult);

    case 'get_water_amount'
        try
            trials_use = max(1, numel(find(~isnan(value(hit_history)))));
        catch
            trials_use = n_done_trials;
        end
        WaterAmount = maxasymp + (minasymp./(1+(trials_use/inflp).^slp).^assym); % valid trials only
        WValveTimes = GetValveTimes(WaterAmount, [2 3]);
        x = WValveTimes(1) * value(left_wtr_mult);
        y = WValveTimes(2) * value(right_wtr_mult);
        this_water.value = [WaterAmount x y];

    case 'get_previous_sides'
        x = value(previous_sides);

    case 'get_cp_history'
        x = cell2mat(get_history(CP_duration));

    case 'get_stimdur_history'
        x = cell2mat(get_history(A1_time));

    case 'push_trial_history'
        % One entry per trial, aligned with the GUI-parameter history that
        % dispatcher pushes when the trial's state machine is sent.
        push_history(this_cell); push_history(this_cell_probs);
        push_history(this_beta); push_history(this_water); push_history(this_block);

    case 'end_of_session'
        % Carry the CP reached today into tomorrow's settings (warm-up target)
        cp_reached.value = value(CP_duration);

    case 'close'
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);

    case 'reinit'
        currfig = double(gcf);
        x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);
        [x, y] = feval(mfilename, obj, 'init', x, y);
        figure(currfig);

    otherwise
        warning('SideSection:action', 'Unknown action %s', action);
end
