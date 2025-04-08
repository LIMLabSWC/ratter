function  [varargout] =  Arpit_CentrePokeTrainingSMA(obj, action)

%%%%%%%%%%%%%%%%%%% TRAINING STAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Stage 1: Light Chasing to introduce the Reward Location
% The rat learns to associate the side pokes as the reward location. The
% light is always ON on the chosen side until the rat pokes and gets a reward immediately by playing
% reward sound and water delivery. On wrong side play punishment sound.

%% Stage 2: Light Chasing continues, introducing Timeout Punishment
% The rat still gets reward on the side pokes but there is a timeout with sound and the
% rat is punished by additional time. The training continues as previous
% stage.

%% Stage 3: Introduce Centre Nose Poke and play Reward Sound as Go Cue until settling in time
% Centre Poke LED on starting with 1 ms and increment by 1 percent until it reaches the max cp time. (should take around 700-800 trials). Take into
% account when rat removes poke before go Cue and dynamically change the cp_time if rats is failing many times. Timeout is now when the rat doesn't
% centre poke within the set time. Side lights still directs towards reward location. This stage is basically the settling_In stage
% where the time period is the entire length of the cp_time. This is further subdivided based upon the centre poke time. In sub-stage
% 1 until settling in time, there is no violation as the rat is fidgety intitially when starting to poke.

%% Stage 4: Continue Centre Poke Training with increasing CP Time, and introduce violation
% Once the rat reliably holds centre poke for settling time, introduce
% violation (around after 200 ms) whereby if rat pokes out before the cp_time then its a violation. If many
% violations then continue training here till the performance in violation trial is below 20 percent for set trials.
% This stage continue till rat learns to poke for atleast CP = 1sec.

%% Stage 5: Continue Centre Poke Training with violation and increasing CP Time, and introduce a fixed Sound between cp start and Go Cue
% In substage 3, which is CP > 1 sec, play a fixed sound between the poke start and Go Cue with the goal of conditioning the rat
% to expect a sound in between a Go Cue and poke start. This could help in later training stages by reducing Violations.
% In this stage the pre stim and stim time is fixed and only the delay between stim end and go cue increases.

%% Stage 6: Continue Centre Poke Training with variable pre-stim time
% After reaching the max CP, vary the pre stim value and fixing the total CP.

%% Stage 7: Continue Centre Poke Training with variable pre-stim time and variable delay time (both within a range of [0.2 - 2 secs]).
% This variable time is introduced so that rat doesn't learn the
% time between each of the parameters

%% Stage 8: Same as previous Stage but now using user defined values.

GetSoloFunctionArgs;


switch action

    case 'init'


    case 'prepare_next_trial'

        %% Setup water
        
        left1led           = bSettings('get', 'DIOLINES', 'left1led');
        center1led         = bSettings('get', 'DIOLINES', 'center1led');
        right1led          = bSettings('get', 'DIOLINES', 'right1led');
        left1water         = bSettings('get', 'DIOLINES', 'left1water');
        right1water        = bSettings('get', 'DIOLINES', 'right1water');


        %% Setup sounds
        sone_sound_id     = SoundManagerSection(obj, 'get_sound_id', 'SOneSound');
        stwo_sound_id     = SoundManagerSection(obj, 'get_sound_id', 'STwoSound');
        A1_sound_id       = SoundManagerSection(obj, 'get_sound_id', 'StimAUD1');
        sound_duration    = value(A1_time); % SoundManagerSection(obj, 'get_sound_duration', 'SOneSound');
        go_sound_id       = SoundManagerSection(obj, 'get_sound_id', 'GoSound');
        go_cue_duration   = value(time_go_cue); % SoundManagerSection(obj, 'get_sound_duration', 'GoSound');
        viol_sound_id     = SoundManagerSection(obj, 'get_sound_id', 'ViolationSound');
        viol_snd_duration = SoundManagerSection(obj, 'get_sound_duration', 'ViolationSound');
        to_sound_id       = SoundManagerSection(obj, 'get_sound_id', 'TimeoutSound');
        timeout_snd_duration  = SoundManagerSection(obj, 'get_sound_duration', 'TimeoutSound');

        [LeftWValveTime,RightWValveTime] = ParamsSection(obj, 'get_water_amount');
        side = ParamsSection(obj, 'get_current_side');

        if side == 'l'
            HitEvent = 'Lin';
            ErrorEvent = 'Rin';
            sound_id = sone_sound_id;
            SideLight  = left1led;
            WValveTime = LeftWValveTime;
            WValveSide = left1water;
        else
            HitEvent = 'Rin';
            ErrorEvent = 'Lin';
            sound_id = stwo_sound_id;
            SideLight  = right1led;
            WValveTime = RightWValveTime;
            WValveSide = right1water;
        end


        sma = StateMachineAssembler('full_trial_structure','use_happenings', 1);

        % scheduled wave for stimuli/fixed sound, based upon side
        if stimuli_on && value(training_stage) > 5
            sma = add_scheduled_wave(sma, 'name', 'stimplay', 'preamble', PreStim_time, ...
                'sustain', sound_duration, 'sound_trig', A1_sound_id); % to play a sound before Go Cue
        else
            sma = add_scheduled_wave(sma, 'name', 'stimplay', 'preamble', PreStim_time, ...
                'sustain', sound_duration, 'sound_trig', sound_id); % to play a sound before Go Cue
        end
        % Scheduled wave for CP Duration
        if CP_duration <= (SettlingIn_time + legal_cbreak)
            sma = add_scheduled_wave(sma, 'name', 'CP_Duration_wave', 'preamble', CP_duration); % total length of centre poke to consider success
        else
            sma = add_scheduled_wave(sma, 'name', 'settling_period', 'preamble', SettlingIn_time); % intial fidgety period without violation
            sma = add_scheduled_wave(sma, 'name', 'CP_Duration_wave', 'preamble', CP_duration - SettlingIn_time); % total length of centre poke minus the inital fidgety time to consider success
        end

        sma = add_scheduled_wave(sma, 'name', 'Go_Cue', 'preamble', 0.001, ...
            'sustain', go_cue_duration, 'sound_trig', go_sound_id); % to play the Go Cue/Reward Sound

        % scheduled wave for rewarded side either of the side
        sma = add_scheduled_wave(sma, 'name', 'reward_delivery', 'preamble', reward_delay, ...
            'sustain', WValveTime, 'DOut', WValveSide); % water delivery side
        sma = add_scheduled_wave(sma, 'name', 'reward_collection_dur', 'preamble', SideLed_duration + RewardCollection_duration); % time to collect the reward

        switch value(training_stage)

            % For Training Stage 1

            case 1  % LEARNING THE REWARD SOUND ASSOCIATION -LEFT OR RIGHT LED ON -> POKE -> SOUND+REWARD GIVEN
                % INFINITE TIME AND CHANCES TO SELF CORRECT

                % sma = add_state(sma, 'name', 'side_led_wait_RewardCollection', 'self_timer', 2, ...
                %     'output_actions', {'DOut', SideLight}, ...
                %     'input_to_statechange',{'Tup','hit_state'});
                % 
                % sma = add_state(sma,'name','second_hit_state','self_timer',3,...
                %     'output_actions',{'DOut', SideLight},...
                %     'input_to_statechange',{'Tup','hit_state'});
                % 
                % sma = add_state(sma,'name','hit_state','self_timer',0.01,...
                %     'output_actions', {'SchedWaveTrig','reward_delivery+Go_Cue'},...
                %     'input_to_statechange',{'Tup','drink_state'});

                sma = add_state(sma, 'name', 'side_led_wait_RewardCollection', 'self_timer', SideLed_duration + RewardCollection_duration, ...
                    'output_actions', {'DOut', SideLight}, ...
                    'input_to_statechange',{HitEvent,'hit_state';'Tup','side_led_wait_RewardCollection'; ErrorEvent,'second_hit_state'});

                sma = add_state(sma,'name','second_hit_state','self_timer',RewardCollection_duration,...
                    'output_actions',{'DOut', SideLight},...
                    'input_to_statechange',{'Tup','second_hit_state'; HitEvent,'hit_state'});

                sma = add_state(sma,'name','hit_state','self_timer',0.01,...
                    'output_actions', {'SchedWaveTrig','reward_delivery+Go_Cue'},...
                    'input_to_statechange',{'Tup','drink_state'});

                sma = add_state(sma,'name','drink_state','self_timer',drink_time,...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                sma = add_state(sma,'name','preclean_up_state','self_timer',0.5,...
                    'input_to_statechange',{'Tup','check_next_trial_ready'});

                sma = add_state(sma, 'name', 'timeout_state');
                sma = add_state(sma, 'name', 'violation_state');

                % For Training Stage 2

            case 2  %% STILL LEARNING THE REWARD SOUND ASSOCIATION -LEFT OR RIGHT LED ON -> POKE -> SOUND+REWARD BUT
                % GIVEN LIMITED TIME TO SELF CORRECT OTHERWISE ITS A TIMEOUT AND A TIMEOUT SOUND IS PLAYED

                sma = add_state(sma, 'name', 'side_led_wait_RewardCollection', 'self_timer', SideLed_duration + RewardCollection_duration, ...
                    'output_actions', {'DOut', SideLight; 'SchedWaveTrig', 'reward_collection_dur'}, ...
                    'input_to_statechange',{HitEvent,'hit_state';'Tup','timeout_state'; ErrorEvent,'second_hit_state'});

                sma = add_state(sma,'name','second_hit_state','self_timer',RewardCollection_duration,...
                    'output_actions',{'DOut', SideLight},...
                    'input_to_statechange',{'reward_collection_dur_In', 'timeout_state'; 'Tup','timeout_state'; HitEvent,'hit_state'});

                sma = add_state(sma,'name','hit_state','self_timer',0.01,...
                    'output_actions', {'SchedWaveTrig','reward_delivery+Go_Cue'},...
                    'input_to_statechange',{'Tup','drink_state'});

                sma = add_state(sma,'name','drink_state','self_timer',drink_time,...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                % For Timeout

                sma = add_state(sma,'name','timeout_state','self_timer',timeout_snd_duration,...
                    'output_actions', {'SoundOut',to_sound_id; 'SchedWaveTrig', '-Go_Cue'},...
                    'input_to_statechange',{'Tup','current_state+1'});
                sma = add_state(sma, 'self_timer', max(0.001, timeout_iti-timeout_snd_duration), ...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                sma = add_state(sma,'name','preclean_up_state','self_timer',0.5,...
                    'input_to_statechange',{'Tup','check_next_trial_ready'});

                sma = add_state(sma, 'name', 'violation_state');

                % Training Stage 3

            case 3    % INTRODUCE CENTRE NOSE POKE AND PLAY REWARD SOUND AS GO CUE ONLY
                      % UNTIL CP_DUR <= SETTLING IN TIME (NO VIOLATIONS)

                sma = add_state(sma,'name','wait_for_cpoke','self_timer',cp_timeout, ...
                    'output_actions', {'DOut', center1led}, ...
                    'input_to_statechange', {'Cin','settling_in_state'; 'Tup','timeout_state'});

                sma = add_state(sma,'name','settling_in_state','self_timer',CP_duration, ...
                    'output_actions', {'SchedWaveTrig',  'CP_Duration_wave'}, ...
                    'input_to_statechange', {'Cout','current_state + 1';'Tup','side_led_wait_RewardCollection'});

                % Intermediate State

                 % This intermediate state is considering the poke is out before the end of settling time / at the start of this state
                sma = add_state(sma,'self_timer',CP_duration,'output_actions', {'DOut', center1led}, ...
                      'input_to_statechange', {'CP_Duration_wave_In','side_led_wait_RewardCollection';'Cin','current_state + 1';'Tup','side_led_wait_RewardCollection'});

                % The state jump to here when the nose is still in then go
                % directly to give reward
                sma = add_state(sma,'self_timer',CP_duration,...
                    'input_to_statechange', {'CP_Duration_wave_In','side_led_wait_RewardCollection'; 'Cout','current_state - 1';'Tup','side_led_wait_RewardCollection'});

                sma = add_state(sma, 'name', 'side_led_wait_RewardCollection', 'self_timer', SideLed_duration + RewardCollection_duration, ...
                    'output_actions', {'DOut', SideLight; 'SchedWaveTrig', 'reward_collection_dur+Go_Cue'}, ...
                    'input_to_statechange',{HitEvent,'hit_state';'Tup','timeout_state'; ErrorEvent,'second_hit_state'});

                sma = add_state(sma,'name','second_hit_state','self_timer',RewardCollection_duration,...
                    'output_actions',{'DOut', SideLight},...
                    'input_to_statechange',{'reward_collection_dur_In', 'timeout_state'; 'Tup','timeout_state'; HitEvent,'hit_state'});

                sma = add_state(sma,'name','hit_state','self_timer',0.01,...
                    'output_actions', {'SchedWaveTrig','reward_delivery'},...
                    'input_to_statechange',{'Tup','drink_state'});

                sma = add_state(sma,'name','drink_state','self_timer',drink_time,...
                    'input_to_statechange',{'Tup','preclean_up_state'});

               % For Timeout

                sma = add_state(sma,'name','timeout_state','self_timer',timeout_snd_duration,...
                    'output_actions', {'SoundOut',to_sound_id; 'SchedWaveTrig', '-Go_Cue'},...
                    'input_to_statechange',{'Tup','current_state+1'});
                sma = add_state(sma, 'self_timer', max(0.001, timeout_iti-timeout_snd_duration), ...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                sma = add_state(sma,'name','preclean_up_state','self_timer',0.5,...
                    'input_to_statechange',{'Tup','check_next_trial_ready'});

              
            case {4,5,6,7,8} % STAGE 4 - LEARN TO NOSE POKE BEYOND SETTLING TIME WITH THE INTRODUCTION OF VIOLATION, THIS IS UNTIL CP = 1 SEC
                % STAGE 5 ONWARDS - THE STIMULI IS INTRODUCED FROM THE STAGE 5 ONWARDS

                sma = add_state(sma,'name','wait_for_cpoke','self_timer',cp_timeout, ...
                    'output_actions', {'DOut', center1led}, ...
                    'input_to_statechange', {'Cin','settling_in_state';'Tup','timeout_state'});

                %%%%%%%%%%%%% SETTLING IN STATE START %%%%%%%%%%%%%%%%%%%%
                % Before progressing check if its still centre poking or pokes within legal c_break other wise its a violation

                if CP_duration <= SettlingIn_time + legal_cbreak % state machine during initial warm-up when starting a new session

                    sma = add_state(sma,'name','settling_in_state','self_timer',CP_duration, ...
                        'output_actions', {'SchedWaveTrig',  'CP_Duration_wave'}, ...
                        'input_to_statechange', {'Cout','current_state + 1';'Tup','side_led_wait_RewardCollection'});

                    % Intermediate State

                    % This intermediate state is considering the poke is out before the end of settling time / at the start of this state
                    sma = add_state(sma,'self_timer',CP_duration,'output_actions', {'DOut', center1led}, ...
                        'input_to_statechange', {'CP_Duration_wave_In','side_led_wait_RewardCollection';'Cin','current_state + 1';'Tup','side_led_wait_RewardCollection'});

                    % The state jump to here when the nose is still in then go
                    % directly to give reward
                    sma = add_state(sma,'self_timer',CP_duration,...
                        'input_to_statechange', {'CP_Duration_wave_In','side_led_wait_RewardCollection'; 'Cout','current_state - 1';'Tup','side_led_wait_RewardCollection'});

                else % the usual state machine

                    sma = add_state(sma,'name','settling_in_state','self_timer',SettlingIn_time, ...
                        'output_actions', {'SchedWaveTrig',  'settling_period'}, ...
                        'input_to_statechange', {'Cout','current_state + 1';'Tup','soft_cp'});

                    % Intermediate State

                    % This intermediate state is considering the poke is out before the end of settling time / at the start of this state
                    sma = add_state(sma,'self_timer',SettlingIn_time,'output_actions', {'DOut', center1led}, ...
                        'input_to_statechange', {'settling_period_In','legal_poke_start_state';'Cin','current_state + 1';'Tup','legal_poke_start_state';...
                        'Rin',  'violation_state';'Rout', 'violation_state'; 'Lin', 'violation_state';'Lout', 'violation_state'});

                    % The state jump to here when the nose is still in then go directly to soft_cp
                    sma = add_state(sma,'self_timer',SettlingIn_time,...
                        'input_to_statechange', {'settling_period_In','soft_cp'; 'Cout','current_state - 1';'Tup','soft_cp';...
                        'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'});

                    %%%%%%%%%%%%% SETTLING IN STATE END %%%%%%%%%%%%%%%%%%%%%%

                    % STATE TO CHECK BEFORE START OF LEGAL POKE PERIOD

                    sma = add_state(sma,'name','legal_poke_start_state','self_timer',legal_cbreak/2, ...
                        'output_actions', {'DOut', center1led}, ...
                        'input_to_statechange', {'Cin','soft_cp'; 'Tup','violation_state';...
                        'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'}); %more stringent by giving half the legal cp time


                    %%%%%%%%%%%% LEGAL SOFT POKE STATE START %%%%%%%%%%%%%%%%%

                    if value(training_stage) == 4

                    % Soft poke with violation

                        sma = add_state(sma,'name','soft_cp','self_timer',CP_duration - SettlingIn_time, ... CP_Duration_wave
                            'output_actions', {'SchedWaveTrig',  'CP_Duration_wave'},...
                            'input_to_statechange', {'Cout','current_state + 1'; 'Tup','side_led_wait_RewardCollection';...
                            'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'}); %more stringent by giving half the legal cp time

                    else  % Soft poke with violation. The difference between this and previous stage is introduction of
                    % sound before the go cue so a new scheduled wave

                        sma = add_state(sma,'name','soft_cp','self_timer',CP_duration - SettlingIn_time, ... CP_Duration_wave
                            'output_actions', {'SchedWaveTrig',  'CP_Duration_wave+stimplay'},...
                            'input_to_statechange', {'Cout','current_state + 1'; 'Tup','side_led_wait_RewardCollection';...
                            'Rin', 'violation_state'; 'Rout', 'violation_state'; 'Lin', 'violation_state'; 'Lout', 'violation_state'}); %more stringent by giving half the legal cp time

                    end

                    % Intermediate State

                    % This intermediate state is considering the poke is out before the end of settling time / at the start of this state
                    sma = add_state(sma,'self_timer',legal_cbreak,'output_actions', {'DOut', center1led}, ...
                    'input_to_statechange', {'CP_Duration_wave_In','legal_poke_end_state';'Cin','current_state + 1';'Tup','violation_state';...
                    'Rin',  'violation_state';'Rout', 'violation_state'; 'Lin', 'violation_state';'Lout', 'violation_state'});

                    % The state jump to here when the nose is still in then go directly to soft_cp
                    sma = add_state(sma,'self_timer',CP_duration - SettlingIn_time, ...
                    'input_to_statechange', {'CP_Duration_wave_In','side_led_wait_RewardCollection';'Cout','current_state - 1';'Tup','side_led_wait_RewardCollection';...
                    'Rin',  'violation_state';'Rout', 'violation_state'; 'Lin', 'violation_state';'Lout', 'violation_state'});

                    %%%%%%%%%%%% LEGAL SOFT POKE STATE END %%%%%%%%%%%%%%%%%

                    % Before giving the reward check if its still centre poking or pokes
                    % within legal c_break other wise its a violation

                    sma = add_state(sma,'name','legal_poke_end_state','self_timer',legal_cbreak/2, ...
                        'output_actions', {'DOut', center1led}, ...
                        'input_to_statechange', {'Cin','side_led_wait_RewardCollection'; 'Tup','violation_state'});

                end

                %%%%%%%%%%%%%%% REWARD COLLECTION STATE START %%%%%%%%%%%%%%%

                sma = add_state(sma, 'name', 'side_led_wait_RewardCollection', 'self_timer', SideLed_duration + RewardCollection_duration, ...
                    'output_actions', {'DOut', SideLight; 'SchedWaveTrig', 'reward_collection_dur+Go_Cue'}, ...
                    'input_to_statechange',{HitEvent,'hit_state'; 'Tup','timeout_state'; ErrorEvent,'second_hit_state'});

                sma = add_state(sma,'name','second_hit_state','self_timer',RewardCollection_duration,...
                    'output_actions',{'DOut', SideLight},...
                    'input_to_statechange',{'reward_collection_dur_In', 'timeout_state'; 'Tup','timeout_state'; HitEvent,'hit_state'});

                sma = add_state(sma,'name','hit_state','self_timer',0.01,...
                    'output_actions', {'SchedWaveTrig','reward_delivery'},...
                    'input_to_statechange',{'Tup','drink_state'});

                sma = add_state(sma,'name','drink_state','self_timer',drink_time,...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                % For Timeout

                sma = add_state(sma,'name','timeout_state','self_timer',timeout_snd_duration,...
                    'output_actions', {'SoundOut',to_sound_id; 'SchedWaveTrig', '-Go_Cue'},...
                    'input_to_statechange',{'Tup','current_state+1'});
                sma = add_state(sma, 'self_timer', max(0.001, timeout_iti-timeout_snd_duration), ...
                    'input_to_statechange',{'Tup','preclean_up_state'});

               % For Violations

                sma = add_state(sma,'name','violation_state','self_timer',viol_snd_duration,...
                    'output_actions',{'SoundOut',viol_sound_id; 'DOut', center1led; 'SchedWaveTrig', '-Go_Cue-stimplay-CP_Duration_wave'},...
                    'input_to_statechange', {'Tup', 'current_state+1'});
                sma = add_state(sma, 'self_timer', max(0.001, violation_iti-viol_snd_duration), ...
                    'input_to_statechange',{'Tup','preclean_up_state'});

                sma = add_state(sma,'name','preclean_up_state','self_timer',0.5,...
                    'input_to_statechange',{'Tup','check_next_trial_ready'});

        end


        varargout{2} = {'check_next_trial_ready'};

      	 varargout{1} = sma;

         % Not all 'prepare_next_trial_states' are defined in all training
         % stages. So we send to dispatcher only those states that are
         % defined.
         state_names = get_labels(sma); state_names = state_names(:,1);
         prepare_next_trial_states = {'side_led_wait_RewardCollection','hit_state','second_hit_state','drink_state', 'violation_state','timeout_state','preclean_up_state'};

         dispatcher('send_assembler', sma, intersect(state_names, prepare_next_trial_states));

    case 'get_state_colors'
        varargout{1} = struct( ...
            'wait_for_cpoke',             [0.68  1   0.63], ...
            'settling_in_state',                       [0.63  1   0.94], ...
            'legal_poke_start_state',   [0.63  1   0.94]*0.8, ...
            'legal_poke_end_state',     [1   0.79  0.63], ...
            'soft_cp',              [0.3   0.9     0], ...
            'side_led_wait_RewardCollection', [0.53 0.78 1.00],...
            'hit_state',             [0.77 0.60 0.48], ...
            'second_hit_state',      [0.25 0.45 0.48], ...
            'drink_state',           [0    1    0],    ...
            'violation_state',            [0.31 0.48 0.30], ...
            'timeout_state', 0.8*[0.31 0.48 0.30]);

            
            % 'lefthit',               [0     0.9   0.3], ...
            % 'error_state',  [1    0.54 0.54], ...
            

        %            'go_cue_on',                [0.63  1   0.94]*0.6, ...
        %            'prerw_postcs',      [0.25 0.45 0.48], ...
        %             'lefthit',           [0.53 0.78 1.00], ...
        %             'lefthit_pasound',   [0.53 0.78 1.00]*0.7, ...
        %             'righthit',          [0.52 1.0  0.60], ...
        %             'righthit_pasound',  [0.52 1.0  0.60]*0.7, ...
        %             'warning',           [0.3  0    0],    ...
        %             'danger',            [0.5  0.05 0.05], ...
        %             'hit',               [0    1    0]


    case 'close'
        

    case 'reinit'
        currfig = double(gcf);

        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);


        % Reinitialise at the original GUI position and figure:
        feval(mfilename, obj, 'init');

        % Restore the current figure:
        figure(currfig);

    otherwise
        warning('do not know how to do %s',action);
end

end



