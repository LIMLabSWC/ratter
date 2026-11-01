% [sma, prepare_next_trial_states] = Arpit2StepTaskSMA(obj, action)
%
% State machine for Arpit2StepTask (experiment). Same as Arpit2StepTraining's,
% plus the ephys trial-number TTL / EphysTrig wave and opto stimulation
% (StimulatorSection, StimLine = 'Ephys' or 'Opto').
%
% Trial structure
%   centre part   (only if CentrePokeRequired):
%       wait_for_cpoke -> settling / fixation (copied from ArpitSoundCategorization)
%       The stimulus (stimplay wave) plays during fixation in TwoStep trials.
%   side_choice   side LEDs show the cue for this trial (light comes on at
%                 the go cue). The go cue is played on entry for centre trials.
%       Lin -> choice_left, Rin -> choice_right   (FIRST side poke, used for scoring)
%   choice_left / choice_right -> hit_left / hit_right if that side pays,
%                                 otherwise second_hit_state (wrong first poke)
%   second_hit_state            behaviour set by reward_type (Always / DelayedReward / NoReward)
%   hit_left / hit_right -> drink_state -> preclean_up_state -> check_next_trial_ready
%   timeout_state, violation_state -> preclean_up_state
%
% In trials without a centre poke (shaping stages 1-2) the go cue is
% played together with the reward, so the go sound becomes associated with
% water before it is used as the go signal (same as ArpitCentrePokeTraining).
%
% prepare_next_trial_states are states reached only once the outcome of the
% FIRST choice is known (hit_left, hit_right, second_hit_state) or the trial
% failed (timeout_state, violation_state). Every path to
% check_next_trial_ready goes through one of them.

function [varargout] = Arpit2StepTaskSMA(obj, action)

GetSoloFunctionArgs;

switch action

    case 'init'

    case 'prepare_next_trial'

        %% Lines
        left1led    = bSettings('get', 'DIOLINES', 'left1led');
        center1led  = bSettings('get', 'DIOLINES', 'center1led');
        right1led   = bSettings('get', 'DIOLINES', 'right1led');
        left1water  = bSettings('get', 'DIOLINES', 'left1water');
        right1water = bSettings('get', 'DIOLINES', 'right1water');

        %% Sounds
        A1_sound_id          = SoundManagerSection(obj, 'get_sound_id', 'StimAUD1');
        sound_duration       = value(A1_time);
        go_sound_id          = SoundManagerSection(obj, 'get_sound_id', 'GoSound');
        go_cue_duration      = value(time_go_cue);
        viol_sound_id        = SoundManagerSection(obj, 'get_sound_id', 'ViolationSound');
        viol_snd_duration    = SoundManagerSection(obj, 'get_sound_duration', 'ViolationSound');
        to_sound_id          = SoundManagerSection(obj, 'get_sound_id', 'TimeoutSound');
        timeout_snd_duration = SoundManagerSection(obj, 'get_sound_duration', 'TimeoutSound');

        %% Trial info
        [LeftWValveTime, RightWValveTime] = SideSection(obj, 'get_water_amount');
        ti = SideSection(obj, 'get_trial_info');

        ChoiceLights = cue_dout(ti.light, value(CueMode), left1led, right1led);

        left_pays  = any(ti.reward_side == 'el');
        right_pays = any(ti.reward_side == 'er');
        if ti.reward_side == 'l'
            HitEvent = 'Lin'; HitState = 'hit_left';
        elseif ti.reward_side == 'r'
            HitEvent = 'Rin'; HitState = 'hit_right';
        else
            HitEvent = 'Lin'; HitState = 'hit_left';   % not used: both sides pay
        end
        if left_pays,  left_next  = 'hit_left';  else, left_next  = 'second_hit_state'; end
        if right_pays, right_next = 'hit_right'; else, right_next = 'second_hit_state'; end

        if ti.choice_limited
            choice_timer = value(RewardCollection_duration);
            choice_tup   = 'timeout_state';
        else
            choice_timer = 10000;          % effectively unlimited
            choice_tup   = 'side_choice';
        end

        play_sound = ti.centre_required && ~strcmpi(value(Stimuli_State), 'No Sound') && ...
                     ~strcmpi(ti.category, 'NONE');

        sma = StateMachineAssembler('full_trial_structure', 'use_happenings', 1);

        %%%%%%%%%%%%%%%% SCHEDULED WAVES %%%%%%%%%%%%%%%%%%%%%%%
        if play_sound
            sma = add_scheduled_wave(sma, 'name', 'stimplay', 'preamble', PreStim_time, ...
                'sustain', sound_duration, 'sound_trig', A1_sound_id);
        else
            sma = add_scheduled_wave(sma, 'name', 'stimplay', 'preamble', PreStim_time, ...
                'sustain', sound_duration);   % silent, keeps timing identical
        end

        if value(go_sound_on) == 1
            sma = add_scheduled_wave(sma, 'name', 'Go_Cue', 'preamble', 0.001, ...
                'sustain', go_cue_duration, 'sound_trig', go_sound_id);
        else   % stage 1 before the go-sound ramp starts: silent, same timing
            sma = add_scheduled_wave(sma, 'name', 'Go_Cue', 'preamble', 0.001, ...
                'sustain', go_cue_duration);
        end

        if CP_duration <= (SettlingIn_time + legal_cbreak)
            sma = add_scheduled_wave(sma, 'name', 'CP_Duration_wave', 'preamble', CP_duration);
        else
            sma = add_scheduled_wave(sma, 'name', 'settling_period', 'preamble', SettlingIn_time);
            sma = add_scheduled_wave(sma, 'name', 'CP_Duration_wave', 'preamble', CP_duration - SettlingIn_time);
        end

        sma = add_scheduled_wave(sma, 'name', 'reward_left', 'preamble', 0.01, ...
            'sustain', LeftWValveTime, 'DOut', left1water);
        sma = add_scheduled_wave(sma, 'name', 'reward_right', 'preamble', 0.01, ...
            'sustain', RightWValveTime, 'DOut', right1water);

        % Ephys trial indicator (trial-number barcode + EphysTrig pulse)
        if ~isnan(bSettings('get', 'DIOLINES', 'trialnum_indicator'))
            trigephys = bSettings('get', 'DIOLINES', 'trialnum_indicator');
        else
            trigephys = nan;
        end
        if strcmpi(value(StimLine), 'Ephys') && ~isnan(trigephys)
            sma = add_scheduled_wave(sma, 'name', 'EphysTrig', 'preamble', 0, 'sustain', ...
                0.4, 'DOut', trigephys, 'loop', 0);
            sma = add_ephys_trial_indicator(sma, n_done_trials+1, 'time_per_state', 5e-3, 'DIOLINE', trigephys);
        else
            sma = add_scheduled_wave(sma, 'name', 'EphysTrig', 'preamble', 0, 'sustain', 0); % dummy wave
        end

        %%%%%%%%%%%%%%%% CENTRE PART %%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ti.centre_required

            sma = add_state(sma, 'name', 'wait_for_cpoke', 'self_timer', CenterLed_duration, ...
                'output_actions', {'DOut', center1led}, ...
                'input_to_statechange', {'Cin', 'settling_in_state'; 'Tup', 'timeout_state'});

            if CP_duration <= SettlingIn_time + legal_cbreak
                % Short hold (stage 3): no violations, breaks are tolerated
                sma = add_state(sma, 'name', 'settling_in_state', 'self_timer', CP_duration, ...
                    'output_actions', {'SchedWaveTrig', 'CP_Duration_wave'}, ...
                    'input_to_statechange', {'Cout', 'current_state + 1'; 'Tup', 'side_choice'});
                sma = add_state(sma, 'self_timer', CP_duration, 'output_actions', {'DOut', center1led * LED_during_settling_legal_cbreak}, ...
                    'input_to_statechange', {'CP_Duration_wave_In', 'side_choice'; 'Cin', 'current_state + 1'; 'Tup', 'side_choice'});
                sma = add_state(sma, 'self_timer', CP_duration, ...
                    'input_to_statechange', {'CP_Duration_wave_In', 'side_choice'; 'Cout', 'current_state - 1'; 'Tup', 'side_choice'});
                % Padding so the number of states matches the other branch
                for i = 1:5
                    sma = add_state(sma, 'self_timer', 0.001, 'input_to_statechange', {'Tup', 'side_choice'});
                end
            else
                % Full hold with violations
                sma = add_state(sma, 'name', 'settling_in_state', 'self_timer', SettlingIn_time, ...
                    'output_actions', {'SchedWaveTrig', 'settling_period'}, ...
                    'input_to_statechange', {'Cout', 'current_state + 1'; 'Tup', 'soft_cp'});
                sma = add_state(sma, 'self_timer', SettlingIn_time, 'output_actions', {'DOut', center1led * LED_during_settling_legal_cbreak}, ...
                    'input_to_statechange', {'settling_period_In', 'legal_poke_start_state'; 'Cin', 'current_state + 1'; 'Tup', 'legal_poke_start_state'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'self_timer', SettlingIn_time, ...
                    'input_to_statechange', {'settling_period_In', 'soft_cp'; 'Cout', 'current_state - 1'; 'Tup', 'soft_cp'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'name', 'legal_poke_start_state', 'self_timer', legal_cbreak/2, ...
                    'output_actions', {'DOut', center1led * LED_during_legal_cbreak}, ...
                    'input_to_statechange', {'Cin', 'soft_cp'; 'Tup', 'violation_state'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'name', 'soft_cp', 'self_timer', CP_duration - SettlingIn_time, ...
                    'output_actions', {'SchedWaveTrig', 'CP_Duration_wave+stimplay'}, ...
                    'input_to_statechange', {'Cout', 'current_state + 1'; 'Tup', 'side_choice'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'self_timer', legal_cbreak, 'output_actions', {'DOut', center1led * LED_during_legal_cbreak}, ...
                    'input_to_statechange', {'CP_Duration_wave_In', 'legal_poke_end_state'; 'Cin', 'current_state + 1'; 'Tup', 'violation_state'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'self_timer', CP_duration - SettlingIn_time, ...
                    'input_to_statechange', {'CP_Duration_wave_In', 'side_choice'; 'Cout', 'current_state - 1'; 'Tup', 'side_choice'; ...
                    'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});
                sma = add_state(sma, 'name', 'legal_poke_end_state', 'self_timer', legal_cbreak/2, ...
                    'output_actions', {'DOut', center1led * LED_during_legal_cbreak}, ...
                    'input_to_statechange', {'Cin', 'side_choice'; 'Tup', 'violation_state'});
            end
            side_entry_waves = 'Go_Cue';
            hit_waves_extra  = '';
        else
            side_entry_waves = '';
            hit_waves_extra  = '+Go_Cue';   % go sound paired with water during shaping
        end

        %%%%%%%%%%%%%%%% SIDE CHOICE %%%%%%%%%%%%%%%%%%%%%%%%%%%
        if isempty(side_entry_waves)
            side_out = {'DOut', ChoiceLights};
        else
            side_out = {'DOut', ChoiceLights; 'SchedWaveTrig', side_entry_waves};
        end
        sma = add_state(sma, 'name', 'side_choice', 'self_timer', choice_timer, ...
            'output_actions', side_out, ...
            'input_to_statechange', {'Lin', 'choice_left'; 'Rin', 'choice_right'; 'Tup', choice_tup});

        sma = add_state(sma, 'name', 'choice_left', 'self_timer', 0.001, ...
            'output_actions', {'DOut', ChoiceLights}, ...
            'input_to_statechange', {'Tup', left_next});
        sma = add_state(sma, 'name', 'choice_right', 'self_timer', 0.001, ...
            'output_actions', {'DOut', ChoiceLights}, ...
            'input_to_statechange', {'Tup', right_next});

        %%%%%%%%%%%%%%%% WRONG FIRST POKE %%%%%%%%%%%%%%%%%%%%%%
        % No error feedback: a wrong first poke just gets no water (scored as
        % an error). What follows depends on reward_type.
        if ti.choice_limited, second_timer = value(RewardCollection_duration); else, second_timer = 10000; end
        if strcmp(reward_type, 'Always')
            % second chance at the correct port
            sma = add_state(sma, 'name', 'second_hit_state', 'self_timer', second_timer, ...
                'output_actions', {'DOut', ChoiceLights}, ...
                'input_to_statechange', {HitEvent, HitState; 'Tup', 'preclean_up_state'});
        elseif strcmp(reward_type, 'DelayedReward')
            sma = add_state(sma, 'name', 'second_hit_state', 'self_timer', max(0.001, secondhit_delay), ...
                'input_to_statechange', {'Tup', 'current_state + 1'});
            sma = add_state(sma, 'self_timer', second_timer, ...
                'output_actions', {'DOut', ChoiceLights}, ...
                'input_to_statechange', {HitEvent, HitState; 'Tup', 'preclean_up_state'});
        else % NoReward: error time-out
            sma = add_state(sma, 'name', 'second_hit_state', 'self_timer', max(0.001, error_iti), ...
                'input_to_statechange', {'Tup', 'preclean_up_state'});
        end

        %%%%%%%%%%%%%%%% REWARD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sma = add_state(sma, 'name', 'hit_left', 'self_timer', reward_delay, ...
            'output_actions', {'DOut', ChoiceLights; 'SchedWaveTrig', ['reward_left' hit_waves_extra]}, ...
            'input_to_statechange', {'Tup', 'drink_state'});
        sma = add_state(sma, 'name', 'hit_right', 'self_timer', reward_delay, ...
            'output_actions', {'DOut', ChoiceLights; 'SchedWaveTrig', ['reward_right' hit_waves_extra]}, ...
            'input_to_statechange', {'Tup', 'drink_state'});
        sma = add_state(sma, 'name', 'drink_state', 'self_timer', drink_time, ...
            'input_to_statechange', {'Tup', 'preclean_up_state'});

        %%%%%%%%%%%%%%%% TIMEOUT / VIOLATION %%%%%%%%%%%%%%%%%%%
        sma = add_state(sma, 'name', 'timeout_state', 'self_timer', timeout_snd_duration, ...
            'output_actions', {'SoundOut', to_sound_id; 'SchedWaveTrig', '-Go_Cue'}, ...
            'input_to_statechange', {'Tup', 'current_state+1'});
        sma = add_state(sma, 'self_timer', max(0.001, timeout_iti - timeout_snd_duration), ...
            'input_to_statechange', {'Tup', 'preclean_up_state'});

        sma = add_state(sma, 'name', 'violation_state', 'self_timer', viol_snd_duration, ...
            'output_actions', {'SoundOut', viol_sound_id; 'DOut', center1led; 'SchedWaveTrig', '-Go_Cue-stimplay-CP_Duration_wave'}, ...
            'input_to_statechange', {'Tup', 'current_state+1'});
        sma = add_state(sma, 'self_timer', max(0.001, violation_iti - viol_snd_duration), ...
            'input_to_statechange', {'Tup', 'preclean_up_state'});

        sma = add_state(sma, 'name', 'preclean_up_state', 'self_timer', 0.8, ...
            'output_actions', {'SchedWaveTrig', 'EphysTrig'}, ...
            'input_to_statechange', {'Tup', 'check_next_trial_ready'});

        % Opto stimulation states (StimulatorSection)
        if strcmpi(value(StimLine), 'Opto')
            sma = StimulatorSection(obj, 'prepare_next_trial', sma);
        end

        state_names = get_labels(sma); state_names = state_names(:, 1);
        prepare_next_trial_states = {'hit_left', 'hit_right', 'second_hit_state', 'timeout_state', 'violation_state'};
        prepare_next_trial_states = intersect(state_names, prepare_next_trial_states);

        dispatcher('send_assembler', sma, prepare_next_trial_states);

        varargout{1} = sma;
        varargout{2} = prepare_next_trial_states;

    case 'get_state_colors'
        varargout{1} = struct( ...
            'wait_for_cpoke',         [0.68 1    0.63], ...
            'settling_in_state',      [0.63 1    0.94], ...
            'legal_poke_start_state', [0.63 1    0.94]*0.8, ...
            'legal_poke_end_state',   [1    0.79 0.63], ...
            'soft_cp',                [0.3  0.9  0   ], ...
            'side_choice',            [0.53 0.78 1.00], ...
            'choice_left',            [0.4  0.6  1.00], ...
            'choice_right',           [0.4  0.6  1.00], ...
            'hit_left',               [0.77 0.60 0.48], ...
            'hit_right',              [0.77 0.60 0.48], ...
            'second_hit_state',       [0.25 0.45 0.48], ...
            'drink_state',            [0    1    0   ], ...
            'violation_state',        [0.31 0.48 0.30], ...
            'timeout_state',          0.8*[0.31 0.48 0.30]);

    case 'close'

    case 'reinit'
        currfig = double(gcf);
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', ['^' mfilename]);
        feval(mfilename, obj, 'init');
        figure(currfig);

    otherwise
        warning('do not know how to do %s', action);
end

end


% ----------------------------------------------------------------------
% Side LED outputs for a light configuration.
%   light: 'l' lit left, 'r' lit right, 'b' both lit, 'n' none lit
%   Light/Dark: lit side LED on, other side off.
%   Color:      lit side = port LED, other side = alternative-colour LED
%               (DIOLINES left1led_alt / right1led_alt). Untested: needs the
%               extra LEDs wired and sendSM2Bpod to route those lines.
% ----------------------------------------------------------------------
function out = cue_dout(light, cue_mode, left1led, right1led)
if strcmpi(cue_mode, 'Color')
    left_alt  = bSettings('get', 'DIOLINES', 'left1led_alt');
    right_alt = bSettings('get', 'DIOLINES', 'right1led_alt');
    if any(isnan([left_alt right_alt]))
        error('Arpit2StepTaskSMA:Color', ...
            'CueMode = Color needs DIOLINES left1led_alt and right1led_alt in Settings_Custom.conf');
    end
    switch light
        case 'l', out = left1led + right_alt;
        case 'r', out = right1led + left_alt;
        case 'b', out = left1led + right1led;
        otherwise, out = left_alt + right_alt;
    end
else
    switch light
        case 'l', out = left1led;
        case 'r', out = right1led;
        case 'b', out = left1led + right1led;
        otherwise, out = 0;
    end
end
end
