
function  [varargout] =  SoundCatSMA(obj, action)

GetSoloFunctionArgs;


switch action
	
	case 'init'
		
		srate=SoundManagerSection(obj,'get_sample_rate');
		freq1=5;
		dur1=1.5*1000;
		Vol=0.01;
		tw=Vol*(MakeBupperSwoop(srate,0, freq1 , freq1 , dur1/2 , dur1/2,0,0.1));
		SoundManagerSection(obj, 'declare_new_sound', 'LRewardSound', [tw ; zeros(1, length(tw))])
		SoundManagerSection(obj, 'declare_new_sound', 'RRewardSound', [zeros(1, length(tw));tw])
		SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
		
	case 'prepare_next_trial',
		
		%% Setup water
		min_time= 2.5E-4;  % This is less than the minumum time allowed for a state transition.
		
		left1led           = bSettings('get', 'DIOLINES', 'left1led');
		center1led         = bSettings('get', 'DIOLINES', 'center1led');
		right1led          = bSettings('get', 'DIOLINES', 'right1led');
		left1water         = bSettings('get', 'DIOLINES', 'left1water');
		right1water        = bSettings('get', 'DIOLINES', 'right1water');
		
				
		%% Setup sounds
		sone_sound_id     = SoundManagerSection(obj, 'get_sound_id', 'SOneSound');
		go_sound_id       = SoundManagerSection(obj, 'get_sound_id', 'GoSound');
		go_cue_duration   = value(time_go_cue); %SoundManagerSection(obj, 'get_sound_duration', 'GoSound');
		RLreward_sound_id = SoundManagerSection(obj, 'get_sound_id', 'RewardSound');
		err_sound_id      = SoundManagerSection(obj, 'get_sound_id', 'ErrorSound');
		viol_sound_id     = SoundManagerSection(obj, 'get_sound_id', 'ViolationSound');
		viol_snd_duration = SoundManagerSection(obj, 'get_sound_duration', 'ViolationSound');
		to_sound_id       = SoundManagerSection(obj, 'get_sound_id', 'TimeoutSound');
		timeout_duration  = SoundManagerSection(obj, 'get_sound_duration', 'TimeoutSound');
		Lreward_sound_id  = SoundManagerSection(obj, 'get_sound_id', 'LRewardSound');
		Rreward_sound_id  = SoundManagerSection(obj, 'get_sound_id', 'RRewardSound');
		
		
        A1_sound_id  = SoundManagerSection(obj, 'get_sound_id', 'StimAUD1');

		%% Declare variables
		% These will get moved to other functions as SoloParamHandles.
					
        WaterAmount=maxasymp + (minasymp./(1+(n_done_trials/inflp).^slp).^assym);
%         WaterValvesSection(obj, 'set_water_amounts', WaterAmount, WaterAmount);
%         [LeftWValveTime RightWValveTime] = WaterValvesSection(obj, 'get_water_times');
        WValveTimes = GetValveTimes(WaterAmount, [2 3]);
        LeftWValveTime = WValveTimes(1);
        RightWValveTime = WValveTimes(2);
		[LeftWMult RightWMult] = SideSection(obj, 'get_water_mult');
		LeftWValveTime=LeftWValveTime*LeftWMult;
		RightWValveTime=RightWValveTime*RightWMult;
        
		side = SideSection(obj, 'get_current_side');
		if side == 'l'
			HitEvent = 'Lin';      ErrorEvent = 'Rin'; 
			HitState = 'lefthit';  SideLight  = left1led; 
            SecondHitState = 'secondlefthit';
			
		else
			HitEvent = 'Rin';      ErrorEvent = 'Lin'; 
			HitState = 'righthit'; SideLight  = right1led; 
            SecondHitState = 'secondrighthit';
		end;
		
		
        if strcmp(reward_type, 'Always')
            LEDOn=1;
            AnyReward=1;
            wait_for_second_hit=30000;
            error_iti=0;
        else
            LEDOn=0;
            if strcmp(reward_type, 'NoReward')
                AnyReward=0;
                wait_for_second_hit=error_iti;
            else
                AnyReward=1;
                wait_for_second_hit=30000;
                error_iti=0;
            end
        end;
        
            
		sma = StateMachineAssembler('full_trial_structure','use_happenings', 1);
				
		sma = add_scheduled_wave(sma, 'name', 'center_poke', 'preamble', CP_duration, ...
			'sustain', go_cue_duration, 'sound_trig', go_sound_id);
		
        sma = add_scheduled_wave(sma, 'name', 'settling_period', 'preamble', SettlingIn_time);
        
        
        % to modify it for widefield imagine
        if value(imaging)==1 && ~isnan(bSettings('get', 'DIOLINES', 'scope'));
            trigscope = bSettings('get', 'DIOLINES', 'scope');
        else
            trigscope = nan;
        end
        
        if value(imaging)==1
            sma = add_scheduled_wave(sma, 'name', 'TrigScope', 'preamble', 0, 'sustain', ...
                0.5, 'DOut', trigscope, 'loop', 0); %for Miniscope Camera
                %0.5, 'DOut', trigscope, 'loop', 0); for Ephys
        else
            sma = add_scheduled_wave(sma, 'name', 'TrigScope', 'preamble', 0, 'sustain', 0); %dummy wave.
        end
        
		% ---BEGIN: for training stage 0 only---
		if side=='l',
			sma = add_scheduled_wave(sma, 'name', 'reward_delivery', 'preamble', reward_delay, ...
				'sustain', LeftWValveTime, 'DOut', left1water);
            reward_sound_id=Lreward_sound_id;
		else
			sma = add_scheduled_wave(sma, 'name', 'reward_delivery', 'preamble', reward_delay, ...
				'sustain', RightWValveTime, 'DOut', right1water);
            reward_sound_id=Rreward_sound_id;
		end;
		% ---END: for training stage 0 only---

        sma = add_scheduled_wave(sma, 'name', 'stimA1', 'preamble', PreStim_time, ...
		        'sustain', A1_time, 'sound_trig', A1_sound_id);
		
		
		
		switch value(training_stage)
			
			case 0  %% learning the reward sound association -left or right led on -> poke -> sound+reward
				sma = add_state(sma, 'name', 'sideled_on', 'self_timer', SideLed_duration, ...
					'output_actions', {'DOut', SideLight}, ...
					'input_to_statechange',{'Tup','wait_for_collecting_reward'});
				
				sma = add_state(sma, 'name', 'wait_for_collecting_reward', 'self_timer', RewardCollection_duration, ...
					'output_actions', {'DOut', SideLight}, ...
					'input_to_statechange',{HitEvent,'hit_state','Tup','wait_for_collecting_reward',ErrorEvent,'second_hit_state'});
				
				sma = add_state(sma,'name','second_hit_state','self_timer',RewardCollection_duration,...
					'output_actions',{'DOut', SideLight},...
					'input_to_statechange',{'Tup','second_hit_state',HitEvent,'hit_state'});
				
				sma = add_state(sma,'name','hit_state','self_timer',0.01,...
					'output_actions', {'DOut', SideLight,'SchedWaveTrig','reward_delivery','SoundOut',reward_sound_id},...
					'input_to_statechange',{'Tup','drink_state'});
				
				
			case 1  %%  center led on -> poke in the center -> go cue -> reward light and sound -- waiting time grows slowlly -stimuli can be present
				
				sma = add_state(sma,'name','wait_for_cpoke','self_timer',CenterLed_duration, ...
					'output_actions', {'DOut', center1led, 'SchedWaveTrig','+TrigScope'}, ...
					'input_to_statechange', {'Cin','cp';'Tup','timeout_state'});
				
                if stimuli_on ==0 || n_done_trials <1
                % center poke starts: trigger center_poke scheduled wave,
				% and when that ends go to side_led_on
				sma = add_state(sma,'name','cp','self_timer', SettlingIn_time, ...
					'output_actions', {'SchedWaveTrig', 'center_poke + settling_period'}, ...
					'input_to_statechange', {'Tup', 'cp_legal_cbreak_period', ...
					    'Cout','current_state+1', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
                else
                    
				% center poke starts: trigger center_poke scheduled wave,
				% and when that ends go to side_led_on
				sma = add_state(sma,'name','cp','self_timer', SettlingIn_time+0.00001, ...
					'output_actions', {'SchedWaveTrig', 'center_poke + settling_period +stimA1'}, ...
					'input_to_statechange', {'Tup', 'cp_legal_cbreak_period', ...
					    'Cout','current_state+1', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
                end
               
              
               % nose is out and we're in "SettlingIn_time":
               % if settling_legal_cbreak time elapses, go to violation state,
               % if nose is put back in, go to copy of cp start 
               % when SettlingIn_time elapses (settling_period_In) "legal cbreaks" changes to usueal legal_cbreaks 
				sma = add_state(sma, 'self_timer', settling_legal_cbreak+0.00001, ...
					'output_actions', {'DOut', center1led*LED_during_settling_legal_cbreak}, ...
					'input_to_statechange', {'Tup', 'violation_state', ...
					    'Cin', 'current_state+1', ...
					    'settling_period_In', 'cp_legal_cbreak_period', ...
                        'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
                
                % center poke:
				% A copy of two states above, but without triggering the
				% start of the center_poke scheduled wave. 
				sma = add_state(sma, 'self_timer', 10000, ...
					'input_to_statechange', {'Cout', 'current_state-1', ...
                        'settling_period_In','cp_legal_cbreak_period', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
                    
                % SettlingIn_time elapsed and from now on cbreaks are treated given legal_cbreaks    
                sma = add_state(sma,'name','cp_legal_cbreak_period', 'self_timer', 10000, ...
					'input_to_statechange', {'Cout', 'current_state+1', ...
					    'Clo', 'current_state+1', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
                    
                % nose is out and we're still in legal_cbreak:
				% if legal_cbreak time elapses, go to violation_state, 
				% if nose is put back in, go to copy of cp start
				sma = add_state(sma, 'self_timer', legal_cbreak+0.00001, ...
					'output_actions', {'DOut', center1led*LED_during_legal_cbreak}, ...
					'input_to_statechange', {'Tup', 'violation_state', ...
					    'Cin', 'current_state+1', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
				
				% center poke:
				% A copy of two states above, but without triggering the
				% start of the center_poke scheduled wave. 
				sma = add_state(sma, 'self_timer', 10000, ...
					'input_to_statechange', {'Cout', 'current_state-1', ...
					    'center_poke_Out', 'wait_for_collecting_reward', ...
						'Rin',  'violation_state', ...
						'Rout', 'violation_state', ...
						'Lin', 'violation_state', ...
						'Lout', 'violation_state'});
					
				
				sma = add_state(sma, 'name', 'wait_for_collecting_reward', 'self_timer', 30000, ...
					'output_actions', {'DOut', LEDOn*SideLight}, ...
					'input_to_statechange',{HitEvent, HitState, ErrorEvent, 'second_hit_state'});
                
                % The two states that make a LeftHit:
                %with reward sound
                
				sma = add_state(sma,'name', 'lefthit','self_timer', reward_delay, ...
					'output_actions', {'DOut', SideLight', 'SoundOut', Lreward_sound_id}, ...					
					'input_to_statechange', {'Tup', 'current_state+1'});
               
                % without reward sound
%                 sma = add_state(sma,'name', 'lefthit','self_timer', reward_delay, ...
% 					'output_actions', {'DOut', SideLight'}, ...					
% 					'input_to_statechange', {'Tup', 'current_state+1'});
%                 
				sma = add_state(sma, 'self_timer', LeftWValveTime, ...
					'output_actions', {'DOut', SideLight+left1water,},...
					'input_to_statechange',{'Tup','hit_state'});

				% The two states that make a RightHit:
                
                %with reward sound
				sma = add_state(sma,'name', 'righthit','self_timer', reward_delay, ...
					'output_actions', {'DOut', SideLight', 'SoundOut', Rreward_sound_id}, ...					
					'input_to_statechange', {'Tup', 'current_state+1'});
				
                % without reward sound
%                 sma = add_state(sma,'name', 'righthit','self_timer', reward_delay, ...
% 					'output_actions', {'DOut', SideLight'}, ...					
% 					'input_to_statechange', {'Tup', 'current_state+1'});
%                 
				sma = add_state(sma, 'self_timer', RightWValveTime, ...
					'output_actions', {'DOut', SideLight+right1water,},...
					'input_to_statechange',{'Tup','hit_state'});
                
				
				sma = add_state(sma,'name','second_hit_state','self_timer', wait_for_second_hit,...
					'output_actions',{'DOut', LEDOn*SideLight},...
					'input_to_statechange',{HitEvent, SecondHitState,'Tup','check_next_trial_ready'});
				

                % The two states that make a SecondLeftHit:
				sma = add_state(sma,'name', 'secondlefthit','self_timer', secondhit_delay, ...	
                    'input_to_statechange', {'Tup', 'current_state+1'});	
                sma = add_state(sma, 'self_timer', reward_delay, ...
					'output_actions', {'DOut', AnyReward*SideLight', 'SoundOut', AnyReward*Lreward_sound_id}, ...	
                    'input_to_statechange', {'Tup', 'current_state+1'});
				sma = add_state(sma, 'self_timer', LeftWValveTime, ...
					'output_actions', {'DOut', AnyReward*(SideLight+left1water)},...
					'input_to_statechange',{'Tup','hit_state'});

				% The two states that make a SecondRightHit:
				sma = add_state(sma,'name', 'secondrighthit','self_timer', secondhit_delay, ...	
                    'input_to_statechange', {'Tup', 'current_state+1'});	
                sma = add_state(sma, 'self_timer', reward_delay, ...
					'output_actions', {'DOut', AnyReward*SideLight', 'SoundOut', AnyReward*Rreward_sound_id}, ...	
                    'input_to_statechange', {'Tup', 'current_state+1'});
				sma = add_state(sma, 'self_timer', RightWValveTime, ...
					'output_actions', {'DOut', AnyReward*(SideLight+right1water)},...
					'input_to_statechange',{'Tup','hit_state'});
                
				% and a common hit_state that we flick through
				sma = add_state(sma, 'name', 'hit_state', 'self_timer', 0.0001, ...
					'input_to_statechange', {'Tup', 'drink_state'});
				
				
		end %end of swith for different training_stages
		
		
% 		sma = add_state(sma,'name','drink_state','self_timer',AnyReward*drink_time+error_iti,...
% 			'input_to_statechange',{'Tup','check_next_trial_ready'});
		
        sma = add_state(sma,'name','drink_state','self_timer',AnyReward*drink_time+error_iti,...
			'input_to_statechange',{'Tup','preclean_up_state'});
        
        if stimuli_on ==0
        sma = add_state(sma,'name','violation_state','self_timer',viol_snd_duration,...
			'output_actions',{'SchedWaveTrig', '-center_poke', ...
			    'SoundOut',viol_sound_id, 'DOut', center1led},...
			'input_to_statechange', {'Tup', 'current_state+1'});   
        else
            
		sma = add_state(sma,'name','violation_state','self_timer',viol_snd_duration,...
			'output_actions',{'SchedWaveTrig', '-center_poke-stimA1', ...
			    'SoundOut',viol_sound_id, 'DOut', center1led},...
			'input_to_statechange', {'Tup', 'current_state+1'});
        end

		sma = add_state(sma, 'self_timer', max(0.001, violation_iti-viol_snd_duration), ...
			'input_to_statechange',{'Tup','preclean_up_state'});
		
		sma = add_state(sma,'name','timeout_state','self_timer', timeout_duration,...
			'output_actions',{'SoundOut',to_sound_id},...
			'input_to_statechange',{'Tup','preclean_up_state'});
		
		        
       sma = add_state(sma,'name','preclean_up_state','self_timer',0.5,...
           'output_actions',{ 'SchedWaveTrig','-TrigScope'},...
            'input_to_statechange',{'Tup','check_next_trial_ready'});
        
		varargout{2} = {'check_next_trial_ready'};
		
		varargout{1} = sma;
		
		% Not all 'prepare_next_trial_states' are defined in all training
		% stages. So we send to dispatcher only those states that are
		% defined.
		state_names = get_labels(sma); state_names = state_names(:,1);
		prepare_next_trial_states = {'lefthit', 'righthit', 'hit_state','second_hit_state', 'error_state', 'violation_state','timeout_state'};
		
        sma = StimulatorSection(obj,'prepare_next_trial',sma);
        dispatcher('send_assembler', sma, intersect(state_names, prepare_next_trial_states));
		
	case 'get_state_colors',
		varargout{1} = struct( ...
			'wait_for_cpoke',             [0.68  1   0.63], ...
			'cp',                       [0.63  1   0.94], ...
			'cp_legal_cbreak_period',   [0.63  1   0.94]*0.8, ...
			'sideled_on',     [1   0.79  0.63], ...
			'wait_for_collecting_reward', [0.53 0.78 1.00],...
		    'righthit',              [0.3   0.9     0], ...
			'lefthit',               [0     0.9   0.3], ...
		    'hit_state',             [0.77 0.60 0.48], ...
			'second_hit_state',      [0.25 0.45 0.48], ...
			'drink_state',           [0    1    0],    ...
			'error_state',  [1    0.54 0.54], ...
			'violation_state',            [0.31 0.48 0.30], ...
			'timeout_state', 0.8*[0.31 0.48 0.30]);
		%            'go_cue_on',                [0.63  1   0.94]*0.6, ...
		%            'prerw_postcs',      [0.25 0.45 0.48], ...
		%             'lefthit',           [0.53 0.78 1.00], ...
		%             'lefthit_pasound',   [0.53 0.78 1.00]*0.7, ...
		%             'righthit',          [0.52 1.0  0.60], ...
		%             'righthit_pasound',  [0.52 1.0  0.60]*0.7, ...
		%             'warning',           [0.3  0    0],    ...
		%             'danger',            [0.5  0.05 0.05], ...
		%             'hit',               [0    1    0]
		
		
		
		
	case 'reinit',
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