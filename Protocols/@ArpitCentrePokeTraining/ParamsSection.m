function [x, y] = ParamsSection(obj, action, x,y)

GetSoloFunctionArgs(obj);

switch action
	
	% ------------------------------------------------------------------
	%              INIT
	% ------------------------------------------------------------------
	
	case 'init'
		
		SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);
		y0 = y;
 
		next_row(y);
		NumeditParam(obj, 'LeftProb', 0.5, x, y); next_row(y);
		MenuParam(obj, 'MaxSame', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, Inf}, Inf, x, y, ...
			'TooltipString', sprintf(['\nMaximum number of consecutive trials where correct\n' ...
			'response is on the same side. Overrides antibias. Thus, for\n' ...
			'example, if MaxSame=5 and there have been 5 Left trials, the\n' ...
			'next trial is guaranteed to be Right'])); next_row(y);
		
		DispParam(obj, 'ThisTrial', 'LEFT', x, y); next_row(y);
		SoloParamHandle(obj, 'previous_sides', 'value', []);
		DeclareGlobals(obj, 'ro_args', 'previous_sides');


		SubheaderParam(obj, 'title', 'Params Section', x, y);
		next_row(y, 1.5);
		next_column(x); y = 5;
        next_row(y);
        NumeditParam(obj, 'reward_delay', 0.01, x,y,'label','Reward Delay','TooltipString','Delay between side poke and reward delivery');
		next_row(y);
		NumeditParam(obj, 'drink_time', 1, x,y,'label','Drink Time','TooltipString','waits to finish water delivery');
		next_row(y);
		NumeditParam(obj, 'timeout_iti', 5, x,y,'label','No Choice Timeout','TooltipString','ITI on timeout trials');
		next_row(y);
		NumeditParam(obj, 'violation_iti', 1, x,y,'label','Violation Timeout','TooltipString','Center poke violation duration');
        % Reward Collection
        next_row(y);
		NumeditParam(obj, 'RewardCollection_duration', 6, x,y,'label','RewardCollection_dur','TooltipString','Wait until rat collects the reward else a timeout');
		next_row(y);
		NumeditParam(obj, 'SideLed_duration', 1, x,y,'label','Side LED duration','TooltipString','Duration of SideLed');
        next_row(y);
        % Centre Poke
		next_row(y);
        NumeditParam(obj, 'cp_timeout', 120, x,y, 'TooltipString','Time from trial start for rat to centre poke else timeout');
        next_row(y);
		NumeditParam(obj, 'legal_cbreak', 0.1, x,y, 'TooltipString','Time in sec for which it is ok to be outside the center port before a violation occurs.');
        next_row(y);
		NumeditParam(obj, 'SettlingIn_time', 0.2, x,y, 'TooltipString','Initial settling period during which there is no violation');
        next_row(y);
        % PreStim
        NumeditParam(obj, 'PreStim_time_Min', 0.20, x,y,'label','Pre-Stim Min','TooltipString','Min Time in NIC before starting the stimulus');
        set_callback(PreStim_time_Min, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'PreStim_time', 0.20, x,y,'label','Pre-Stim time','TooltipString','Actual Time in NIC before starting the stimulus');
        set_callback(PreStim_time, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'PreStim_time_Max', 0.40, x,y,'label','Pre-Stim Max','TooltipString','Max Time in NIC before starting the stimulus');
        set_callback(PreStim_time_Max, {mfilename, 'new_CP_duration'});
        next_row(y);
        % A1 Time
        NumeditParam(obj, 'A1_time_Min', 0.1, x,y,'label','Min time AUD1','TooltipString','Min value to select the Duration of fixed stimulus');
        set_callback(A1_time_Min, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'A1_time', 0.4, x,y,'label','AUD1 Time','TooltipString','Actual Duration of fixed stimulus');
        set_callback(A1_time, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'A1_time_Max', 0.4, x,y,'label','Max time AUD1','TooltipString','Max value to select the Duration of fixed stimulus');
        set_callback(A1_time_Max, {mfilename, 'new_CP_duration'});
        next_row(y);
        % Time b/w stim and Go Cue
        NumeditParam(obj, 'time_bet_aud1_gocue_Min', 0.2, x,y,'label','Min A1-GoCue time','TooltipString','Min time between the end of the stimulus and the go cue ');
        set_callback(time_bet_aud1_gocue_Min, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'time_bet_aud1_gocue', 0.2, x,y,'label','A1-GoCue time','TooltipString','Actual time between the end of the stimulus and the go cue ');
        set_callback(time_bet_aud1_gocue, {mfilename, 'new_CP_duration'});
        next_row(y);
        NumeditParam(obj, 'time_bet_aud1_gocue_Max', 2, x,y,'label','Max A1-GoCue time','TooltipString','Max time between the end of the stimulus and the go cue ');
        set_callback(time_bet_aud1_gocue_Max, {mfilename, 'new_CP_duration'});
        next_row(y);
        DispParam(obj, 'init_CP_duration', 0.01, x,y,'label','init_CP duration','TooltipString','Duration of Nose in Central Poke before Go cue starts (see Total_CP_duration)');
    	next_row(y);
        DispParam(obj, 'CP_duration', PreStim_time+A1_time+time_bet_aud1_gocue, x,y,'label','CP duration','TooltipString','Duration of Nose in Central Poke before Go cue starts (see Total_CP_duration)');
		% set_callback(CP_duration, {mfilename, 'new_CP_duration'});
		next_row(y);
		NumeditParam(obj, 'time_go_cue' ,0.2, x,y,'label','Go Cue Duration','TooltipString','duration of go cue (see Total_CP_duration)');
		set_callback(time_go_cue, {mfilename, 'new_time_go_cue'});
		next_row(y);
		DispParam(obj, 'Total_CP_duration', CP_duration+time_go_cue, x, y, 'TooltipString', 'Total expected(rat can poke out anytime after Go cue onset) nose in center port time, in secs. Sum of CP_duration and Go Cue duration'); %#ok<*NODEF>
		
        next_row(y);
        ToggleParam(obj, 'stimuli_on', 0, x,y,...
        'OnString', 'Use Stimuli',...
        'OffString', 'Fixed Sound',...
        'TooltipString', sprintf('If on (black) then it enables training with stimuli else using a fixed sound from Stage 5'));
        next_row(y);
        ToggleParam(obj, 'warmup_on', 1, x,y,...
			'OnString', 'Warmup ON',...
			'OffString', 'Warmup OFF',...
			'TooltipString', sprintf(['If on (Yellow) then it applies the initial warming up phase, during which the\n',...
            'CP_duration starts small and gradually grows to last_session_max_cp_duration']));
        next_row(y);
        ToggleParam(obj, 'random_PreStim_time', 0, x,y,...
        'OnString', 'random PreStim_time ON',...
        'OffString', 'random PreStim_time OFF',...
        'TooltipString', sprintf('If on (black) then it enables the random time between the user given range'));
        set_callback(random_PreStim_time, {mfilename, 'new_CP_duration'});
        next_row(y);
        ToggleParam(obj, 'random_A1_time', 0, x,y,...
        'OnString', 'random A1_time ON',...
        'OffString', 'random A1_time OFF',...
        'TooltipString', sprintf('If on (black) then it enables the random sampling of A1_time'));
        set_callback(random_A1_time, {mfilename, 'new_CP_duration'});
        next_row(y);
        ToggleParam(obj, 'random_prego_time', 0, x,y,...
        'OnString', 'random prego_time ON',...
        'OffString', 'random prego_time OFF',...
        'TooltipString', sprintf('If on (black) then it enables the random sampling of time between the end of the stimulus and the go cue'));
        set_callback(random_prego_time, {mfilename, 'new_CP_duration'});
    
        next_column(x);
		y=5;
        MenuParam(obj, 'training_stage', {'1'; '2'; '3';...
            '4'; '5'; '6'; '7';'8'}, 1, x, y, ...
            'label', 'Active Stage', 'TooltipString', 'the current training stage');
		% NumeditParam(obj,'training_stage',1,x,y,'label','Training Stage');
        set_callback(training_stage, {mfilename, 'Changed_Training_Stage'});
        disable(training_stage);
		next_row(y);
		ToggleParam(obj,'use_auto_train',1,x,y,'OnString','Using Autotrain','OffString','Manual Settings');
		set_callback(use_auto_train, {mfilename, 'Changed_Training_Stage'});

        next_row(y);
		NumeditParam(obj, 'ntrial_correct_bias', 0, x, y, ...
			'TooltipString', 'antibias starts from trial=ntrial_correct_bias');
		next_row(y);
		NumeditParam(obj, 'right_left_diff', .12, x, y, ...
			'TooltipString', 'antibias applies if difference between right and left sides is bigger than this number');
        next_row(y);
		NumeditParam(obj, 'max_wtr_mult', 4, x, y, ...
			'TooltipString', 'wtr_mult will be min(max_wtr_mult,right_hit/left_hit)');
		next_row(y);
		NumeditParam(obj, 'left_wtr_mult', 1, x, y, ...
			'TooltipString', 'all left reward times are multiplied by this number');
		next_row(y);
		NumeditParam(obj, 'right_wtr_mult', 1, x, y, ...
			'TooltipString', 'all right reward times are multiplied by this number');
		next_row(y);
		ToggleParam(obj, 'antibias_wtr_mult', 0, x,y,...
			'OnString', 'AntiBias Water ON',...
			'OffString', 'AntiBias Water OFF',...
			'TooltipString', sprintf(['If on (black) then it disables the wtr_mult entries\n'...
			'and uses hitfrac to adjust the water times']));
		
		next_row(y);
		SoloFunctionAddVars('ArpitCentrePokeTrainingSMA', 'ro_args', ...
			{'CP_duration';'SideLed_duration'; 'stimuli_on';...
			'RewardCollection_duration';'training_stage'; ...
			'legal_cbreak' ; 'SettlingIn_time'; 'time_go_cue'; ...
            'A1_time';'time_bet_aud1_gocue' ; 'PreStim_time';
			'drink_time';'reward_delay';'antibias_wtr_mult';...
			'cp_timeout';'timeout_iti';'violation_iti'});
        
        
		SoloFunctionAddVars('SessionPerformanceSection', 'ro_args', ...
			{'training_stage'});

        SoloFunctionAddVars('StimulusSection', 'ro_args', ...
			{'training_stage';'stimuli_on';'ThisTrial';'A1_time';...
            'time_bet_aud1_gocue' ;'PreStim_time'});
        
        SoloFunctionAddVars('Training_ParamsSection', 'ro_args', ...
			{'training_stage'});
		
		SoloParamHandle(obj, 'previous_parameters', 'value', []);
		


 %%%%%%%%% Switch b/w Actions within ParamSection %%%%%%%%%%%%%

	case 'new_CP_duration' 

        if random_PreStim_time == 1 && (value(PreStim_time) < value(PreStim_time_Min) || value(PreStim_time) > value(PreStim_time_Max))
            PreStim_time.value = value(PreStim_time_Min);
        else
            PreStim_time.value = value(PreStim_time);
        end

        if random_A1_time == 1 && (value(A1_time) < value(A1_time_Min) || value(A1_time) > value(A1_time_Max))
            A1_time.value = value(A1_time_Min);
        else
            A1_time.value = value(A1_time);
        end

        if random_prego_time == 1 && (value(time_bet_aud1_gocue) < value(time_bet_aud1_gocue_Min) || value(time_bet_aud1_gocue) > value(time_bet_aud1_gocue_Max))
            time_bet_aud1_gocue.value = value(time_bet_aud1_gocue_Min);
        else
            time_bet_aud1_gocue.value = value(time_bet_aud1_gocue);
        end

        CP_duration.value= value(SettlingIn_time) + value(PreStim_time) + value(A1_time) + value(time_bet_aud1_gocue);
		Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU> 

	case 'new_time_go_cue'
		Total_CP_duration.value = value(CP_duration) + value(time_go_cue);
        
    case 'Changed_Training_Stage'
        
        if value(use_auto_train) == 1
            disable(training_stage); % user cannot change the training stages    
        else
            enable(training_stage); % user can change the training stages
            SessionDefinition(obj, 'jump_to_stage',value(training_stage));
        end

            [stage_fig_x,stage_fig_y] = Training_ParamsSection(obj, 'reinit', value(stage_fig_x),value(stage_fig_y)); % update the training params as well
            ArpitCentrePokeTrainingSMA(obj,'reinit');
            SessionPerformanceSection(obj, 'evaluate');
           
            switch value(training_stage)

                case {1,2}                  %% learning the reward sound association -left or right led on -> poke -> sound+reward

                    make_invisible(SettlingIn_time); make_invisible(legal_cbreak); make_invisible(cp_timeout);
                    make_invisible(PreStim_time); make_invisible(PreStim_time_Min); make_invisible(PreStim_time_Max);
                    make_invisible(A1_time); make_invisible(A1_time_Min); make_invisible(A1_time_Max);
                    make_invisible(time_bet_aud1_gocue);make_invisible(time_bet_aud1_gocue_Min);make_invisible(time_bet_aud1_gocue_Max);
                    make_invisible(CP_duration); make_invisible(Total_CP_duration); make_invisible(init_CP_duration);

                case {3,4} % Centre poke without the A1_Stim but has violation in 4

                    make_visible(SettlingIn_time); make_visible(legal_cbreak); make_visible(cp_timeout);
                    make_invisible(PreStim_time); make_invisible(PreStim_time_Min); make_invisible(PreStim_time_Max);
                    make_invisible(A1_time); make_invisible(A1_time_Min); make_invisible(A1_time_Max);
                    make_invisible(time_bet_aud1_gocue);make_invisible(time_bet_aud1_gocue_Min);make_invisible(time_bet_aud1_gocue_Max);
                    make_visible(CP_duration); make_visible(Total_CP_duration); make_visible(init_CP_duration);

                    if n_done_trials <1 && value(warmup_on) ==1
                        CP_duration.value = value(init_CP_duration);
                    end

                    Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU>

                case {5,6,7} %

                    make_visible(SettlingIn_time); make_visible(legal_cbreak); make_visible(cp_timeout);
                    make_visible(PreStim_time); make_invisible(PreStim_time_Min); make_invisible(PreStim_time_Max);
                    make_visible(A1_time); make_invisible(A1_time_Min); make_invisible(A1_time_Max);
                    make_visible(time_bet_aud1_gocue);make_invisible(time_bet_aud1_gocue_Min);make_invisible(time_bet_aud1_gocue_Max);
                    make_visible(CP_duration); make_visible(Total_CP_duration); make_visible(init_CP_duration);

                    if n_done_trials <1 && warmup_on ==1
                        CP_duration.value = value(init_CP_duration);
                    end

                    Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU>

                case 8

                    make_visible(SettlingIn_time); make_visible(legal_cbreak); make_visible(cp_timeout);
                    make_visible(PreStim_time); make_visible(PreStim_time_Min); make_visible(PreStim_time_Max);
                    make_visible(A1_time); make_visible(A1_time_Min); make_visible(A1_time_Max);
                    make_visible(time_bet_aud1_gocue);make_visible(time_bet_aud1_gocue_Min);make_visible(time_bet_aud1_gocue_Max);
                    make_visible(CP_duration); make_visible(Total_CP_duration); make_visible(init_CP_duration);

                    if random_prego_time == 1
                        time_range_go_cue = value(time_bet_aud1_gocue_Min):0.01:value(time_bet_aud1_gocue_Max);
                        time_bet_aud1_gocue.value = time_range_go_cue(randi([1, numel(time_range_go_cue)],1,1));
                    end

                    if random_A1_time == 1
                        time_range_A1_time = value(A1_time_Min): 0.01 : value(A1_time_Max);
                        A1_time.value = time_range_A1_time(randi([1, numel(time_range_A1_time)],1,1));
                    end

                    if random_PreStim_time == 1
                        time_range_PreStim_time = value(PreStim_time_Min) : 0.01 : value(PreStim_time_Max);
                        PreStim_time.value = time_range_PreStim_time(randi([1, numel(time_range_PreStim_time)],1,1));
                    end

                    if n_done_trials <1 && warmup_on ==1
                        CP_duration.value = value(init_CP_duration);
                    else
                        CP_duration.value = value(SettlingIn_time) + value(A1_time) + value(PreStim_time) + value(time_bet_aud1_gocue);
                    end
                    Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU>

            end

	case 'prepare_next_trial'
		            
        if value(training_stage) ==  8 % user setting

            make_visible(SettlingIn_time);
            make_visible(PreStim_time); make_visible(PreStim_time_Min); make_visible(PreStim_time_Max);
            make_visible(A1_time); make_visible(A1_time_Min); make_visible(A1_time_Max);
            make_visible(time_bet_aud1_gocue);make_visible(time_bet_aud1_gocue_Min);make_visible(time_bet_aud1_gocue_Max);
            make_visible(CP_duration); make_visible(Total_CP_duration); make_visible(init_CP_duration);

            if random_prego_time == 1
                time_range_go_cue = value(time_bet_aud1_gocue_Min):0.01:value(time_bet_aud1_gocue_Max);
                time_bet_aud1_gocue.value = time_range_go_cue(randi([1, numel(time_range_go_cue)],1,1));
            end

            if random_A1_time == 1
                time_range_A1_time = value(A1_time_Min): 0.01 : value(A1_time_Max);
                A1_time.value = time_range_A1_time(randi([1, numel(time_range_A1_time)],1,1));
            end

            if random_PreStim_time == 1
                time_range_PreStim_time = value(PreStim_time_Min) : 0.01 : value(PreStim_time_Max);
                PreStim_time.value = time_range_PreStim_time(randi([1, numel(time_range_PreStim_time)],1,1));
            end

            if n_done_trials <1 && warmup_on ==1
                CP_duration.value = value(init_CP_duration);
            else
                CP_duration.value = value(SettlingIn_time) + value(A1_time) + value(PreStim_time) + value(time_bet_aud1_gocue);
            end

            Total_CP_duration.value = value(CP_duration) + value(time_go_cue); %#ok<*NASGU>

        end
		
		%% update violation, timeout, previous_sides, etc
        was_viol=false;
        was_timeout=false;
        was_hit=false;
        if n_done_trials>0
            if ~isempty(parsed_events)
                if isfield(parsed_events,'states')
                    if isfield(parsed_events.states,'timeout_state')
                        was_timeout=rows(parsed_events.states.timeout_state)>0;
                    end
                    if isfield(parsed_events.states,'violation_state')
                        was_viol=rows(parsed_events.states.violation_state)>0;
                    end
                end

            end

            violation_history.value=[violation_history(:); was_viol];
            timeout_history.value=[timeout_history(:); was_timeout];

            ParamsSection(obj,'update_side_history');
            % Update Hit History
            if ~was_viol && ~was_timeout
                was_hit=rows(parsed_events.states.second_hit_state)==0;
				hit_history.value=[hit_history(:); was_hit];
				
			else
				% There was a violation or timeout
				hit_history.value=[hit_history(:); nan];
            end
        end

        %% Choose Side for the Next Trial
        
        if ~isinf(MaxSame) && length(previous_sides) > MaxSame && ...
                all(previous_sides(n_done_trials-MaxSame+1:n_done_trials) == previous_sides(n_done_trials)) %#ok<NODEF>
            if previous_sides(end)=='l'
                ThisTrial.value = 'RIGHT';
            else
                ThisTrial.value = 'LEFT';
            end

            if previous_sides(end)=='r'
                ThisTrial.value = 'LEFT';
            else
                ThisTrial.value = 'RIGHT';
            end

        else

            if (rand(1)<=LeftProb)
                ThisTrial.value='LEFT';

            else
                ThisTrial.value='RIGHT';
            end

        end
        
       				
% 		%% Do the anti-bias with changing reward delivery
% 		% reset anti-bias
% 		left_wtr_mult.value=1;
% 		right_wtr_mult.value=1;
% 		if n_done_trials>ntrial_correct_bias && antibias_wtr_mult==1
% 			hh=hit_history(n_done_trials-ntrial_correct_bias:n_done_trials);
% 			ps=previous_sides(n_done_trials-ntrial_correct_bias:n_done_trials);
% 			
% 			right_hit=nanmean(hh(ps=='r'));
% 			left_hit=nanmean(hh(ps=='l'));
% 			
% 			if abs(right_hit-left_hit)<right_left_diff
% 				left_wtr_mult.value=1;
% 				right_wtr_mult.value=1;
% 			else
% 				
% 				left_wtr_mult.value=min(right_hit/left_hit,max_wtr_mult);
% 				right_wtr_mult.value=min(left_hit/right_hit,max_wtr_mult);
% 			end
% 		end
		
    case 'get_water_amount'

        %% Calculate the water amount for each side valve
        WaterAmount=maxasymp + (minasymp./(1+(n_done_trials/inflp).^slp).^assym);
        %         WaterValvesSection(obj, 'set_water_amounts', WaterAmount, WaterAmount);
        %         [LeftWValveTime RightWValveTime] = WaterValvesSection(obj, 'get_water_times');
        WValveTimes = GetValveTimes(WaterAmount, [2 3]);
        LeftWValveTime = WValveTimes(1);
        RightWValveTime = WValveTimes(2);
        [LeftWMult, RightWMult] = ParamsSection(obj, 'get_water_mult');
        x=LeftWValveTime*LeftWMult;
        y=RightWValveTime*RightWMult;

	case 'get_water_mult'
        
        %% Modulating Water Time
%         maxasymp=38;
%         slp=3;
%         inflp=300;
%         minasymp=-20;
%         assym=0.7;
%         left_wtr_mult.value=maxasymp + (minasymp./(1+(n_done_trials/inflp).^slp).^assym);
%         right_wtr_mult.value=maxasymp + (minasymp./(1+(n_done_trials/inflp).^slp).^assym);
		x=left_wtr_mult+0;
		y=right_wtr_mult+0;
		
	case 'get_previous_sides'
		x = value(previous_sides); %#ok<NODEF>
		
	case 'get_left_prob'
		x = value(LeftProb);
		
	case 'get_cp_history'
		x = cell2mat(get_history(CP_duration));
        
    case 'get_stimdur_history'
		x = cell2mat(get_history(A1_time));
  
	case 'update_side_history'
        if strcmp(ThisTrial, 'LEFT')
            ps=value(previous_sides);
            ps(n_done_trials)='l';
            previous_sides.value=ps;

        else
            ps=value(previous_sides);
            ps(n_done_trials)='r';
            previous_sides.value=ps;
        end
		
	case 'get_current_side'
        if strcmp(ThisTrial, 'LEFT')
            x = 'l'; %#ok<NODEF>
        else
            x = 'r';
        end
		
		
	case 'close'
		% Delete all SoloParamHandles who belong to this object and whose
		% fullname starts with the name of this mfile:
		delete_sphandle('owner', ['^@' class(obj) '$'], ...
			'fullname', ['^' mfilename]);

	case 'reinit'
		currfig = double(gcf);
		
		% Get the original GUI position and figure:
		x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));
		
		% Delete all SoloParamHandles who belong to this object and whose
		% fullname starts with the name of this mfile:
		delete_sphandle('owner', ['^@' class(obj) '$'], ...
			'fullname', ['^' mfilename]);
		
		% Reinitialise at the original GUI position and figure:
		[x, y] = feval(mfilename, obj, 'init', x, y);
		
		% Restore the current figure:
		figure(currfig);
		
end


