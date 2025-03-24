%Training stage file.
%Please use the session automator window exclusively
%to edit this file.

function varargout = pipeline_Arpit_CentrePokeTraining_experimenter_ratname_250319c(obj, action, varargin)

GetSoloFunctionArgs('func_owner', ['@' class(obj)], 'func_name', 'SessionModel');

pairs = {'helper_vars_eval', true;
    'stage_algorithm_eval', true;
    'completion_test_eval', false;
    'eod_logic_eval', false};
parseargs(varargin, pairs);

switch action
    

%% Familiarize with Reward Side Pokes

%<TRAINING_STAGE>
case 'Familiarize with Reward Side Pokes'
    if helper_vars_eval
        GetSoloFunctionArgs(obj);
        ClearHelperVarsNotOwned(obj);
        %<HELPER_VARS>
        stage1_trial_counter = 0;
        stage1_trial_counter_today = 0;
        stage1_trial_counter_oppSide = 0;
        %</HELPER_VARS>
    end
    if stage_algorithm_eval
        GetSoloFunctionArgs(obj);
        ClearHelperVarsNotOwned(obj);
        %<STAGE_ALGORITHM>
        ParamsSection_MaxSame.value = 4;
        ParamsSection_training_stage.value = 1;
        stage1_trial_counter = stage1_trial_counter + 1;
        stage1_trial_counter_today = stage1_trial_counter_today + 1;
        if value(previous_sides(end)) ~= value(ParamsSection_ThisTrial)
            stage1_trial_counter_oppSide = stage1_trial_counter_oppSide + 1;
        end
        %</STAGE_ALGORITHM>
    end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
% only run it if its the start of the day, so number of trials the rat did
% is less
if n_completed_trial < 100
    if stage1_trial_counter > 300 && stage1_trial_counter_oppSide > 150
        sm = value(SessionDefinition_my_session_model);
        SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
    end
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
stage1_trial_counter_today = 0;
if stage1_trial_counter > 300 && stage1_trial_counter_oppSide > 150
    sm = value(SessionDefinition_my_session_model);
    SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
end
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Timeout Rewarded Side Pokes

%<TRAINING_STAGE>
case 'Timeout Rewarded Side Pokes'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>
        stage2_trial_counter = 0;
        stage2_trial_counter_today = 0;
        stage2_trial_counter_oppSide = 0;
        opp_side_trials = 0;
        stage2_timeout_percent = 0;
        max_reward_collection_dur = 15; % this is the max I will allow
        min_reward_collection_dur = 5; % this is the max I will allow
%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
ParamsSection_MaxSame.value = 4;
ParamsSection_training_stage.value = 2;
stage2_trial_counter = stage2_trial_counter + 1;
stage2_trial_counter_today = stage2_trial_counter_today + 1;
if value(previous_sides(end)) ~= value(ParamsSection_ThisTrial)
    stage2_trial_counter_oppSide = stage2_trial_counter_oppSide + 1;
    opp_side_trials = opp_side_trials + 1;
end
% Update the reward collection time based upon behav
if size(timeout_history) > 5
    if all(value(timeout_history(end-1:end))) && opp_side_trials >= 2
        ParamsSection_RewardCollection_duration.value = min([value(ParamsSection_RewardCollection_duration) + 1,...
            max_reward_collection_dur]);
        opp_side_trials = 0;
    end

    if ~any(value(timeout_history(end-1:end)))  && opp_side_trials >= 2
        ParamsSection_RewardCollection_duration.value = max([value(ParamsSection_RewardCollection_duration) - 1,...
            min_reward_collection_dur]);
        opp_side_trials = 0;
    end
end

if size(timeout_history) > 20
    if all(value(timeout_history(end-19:end)))
        ParamsSection_RewardCollection_duration.value = 30;
    end
end

stage2_timeout_percent = ((stage2_timeout_percent * stage2_trial_counter) + double(timeout_history(end)))/(stage2_trial_counter + 1);

%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if n_completed_trial > 50
    if stage2_trial_counter > 1000 && stage2_trial_counter_oppSide > 200
        sm = value(SessionDefinition_my_session_model);
        SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
    end
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>

%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Introduce Centre Poke

%<TRAINING_STAGE>
case 'Introduce Centre Poke'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>
% Maximum & Minimum duration of center poke, in secs:
cp_max = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
cp_min = value(ParamsSection_init_CP_duration);
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = 0.001;
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;

stage3_trial_counter = 0;
stage3_trial_counter_today = 0;
stage3_timeout_percent = 0;

last_session_cp = 0;
%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>

ParamsSection_training_stage.value = 3;
stage3_trial_counter = stage3_trial_counter + 1;
stage3_trial_counter_today = stage3_trial_counter_today + 1;
stage3_timeout_percent = ((stage3_timeout_percent * stage3_trial_counter) + double(timeout_history(end)))/(stage3_trial_counter + 1);

% Change the value of CP Duration
if n_completed_trials < 1
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
else
    if ~timeout_history(end) && value(ParamsSection_CP_duration) < cp_max
        increment = value(ParamsSection_CP_duration)*cp_fraction;
        if increment < cp_minimum_increment
            increment = value(cp_minimum_increment);
        end
        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
    end	
end
%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if value(ParamsSection_CP_duration) >= cp_max
    sm = value(SessionDefinition_my_session_model);
    SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
stage3_trial_counter_today = 0;
last_session_cp = value(ParamsSection_CP_duration);
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Introduce Violation for Centre Poke

%<TRAINING_STAGE>
case 'Introduce Violation for Centre Poke'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>

% Maximum & Minimum duration of center poke, in secs:
cp_min = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
cp_max = 1.5;
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = 0.001;
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;
last_session_cp = 0;
stage4_trial_counter = 0;
stage4_trial_counter_today = 0;
stage4_timeout_percent = 0;
stage4_violation_percent = 0;

%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
ParamsSection_training_stage.value = 4;
stage4_trial_counter = stage4_trial_counter + 1;
stage4_trial_counter_today = stage4_trial_counter_today + 1;
stage4_timeout_percent = ((stage4_timeout_percent * stage4_trial_counter) + double(timeout_history(end)))/(stage4_trial_counter + 1);
stage4_violation_percent = ((stage4_violation_percent * stage4_trial_counter) + double(violation_history(end)))/(stage4_trial_counter + 1);

% Change the value of CP Duration
if n_completed_trials < 1
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
else
    if ~violation_history(end) && ~timeout_history(end) && value(ParamsSection_CP_duration) < cp_max
        increment = value(ParamsSection_CP_duration)*cp_fraction;
        if increment < cp_minimum_increment
            increment = value(cp_minimum_increment);
        end
        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
    end	
end
if value(ParamsSection_CP_duration) > cp_max
    ParamsSection_CP_duration.value = cp_max;
end
%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if value(ParamsSection_CP_duration) >= cp_max  && n_completed_trials > 100
if SessionPerformanceSection_violation_recent < 0.1 && SessionPerformanceSection_timeout_recent < 0.1 && stage4_violation_percent < 0.35
    sm = value(SessionDefinition_my_session_model);
    SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
    last_session_cp = value(ParamsSection_CP_duration);
end
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
% Store the value of the total cp duration reached:
stage4_trial_counter_today = 0;
last_session_cp = value(ParamsSection_CP_duration);
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Introduce Stimuli Sound during Centre Poke

%<TRAINING_STAGE>
case 'Introduce Stimuli Sound during Centre Poke'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>
cp_max = 5;
cp_min = 1.5;
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = 0.002;
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;
% cp value for last session
last_session_cp = 0;
% Starting total center poke duration:
starting_total_cp = 0.5;
% number of warm-up trials
n_trial_warmup = 10;
stage5_trial_counter = 0;
stage5_trial_counter_today = 0;
stage5_timeout_percent = 0;
stage5_violation_percent = 0;
%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>

ParamsSection_training_stage.value = 5;
stage5_trial_counter = stage5_trial_counter + 1;
stage5_trial_counter_today = stage5_trial_counter_today + 1;
stage5_timeout_percent = ((stage5_timeout_percent * stage5_trial_counter) + double(timeout_history(end)))/(stage5_trial_counter + 1);
stage5_violation_percent = ((stage5_violation_percent * stage5_trial_counter) + double(violation_history(end)))/(stage5_trial_counter + 1);

% Change the value of CP Duration

% Since starting a new session then do a pre warm up to last saved cp
% duration else continue with learning with increased poke time
if n_completed_trials == 0
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
elseif n_completed_trials == 1
    ParamsSection_CP_duration.value = starting_total_cp;
else
    if ~violation_history(end) && ~timeout_history(end)
        if value(ParamsSection_CP_duration) < max([cp_min,last_session_cp]) % warm up stage
            increment = (max([cp_min,last_session_cp]) - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
        else
            if value(ParamsSection_CP_duration) >= last_session_cp && value(ParamsSection_CP_duration) <= cp_max % no warm up stage
                increment = value(ParamsSection_CP_duration)*cp_fraction;
                if increment < cp_minimum_increment
                    increment = value(cp_minimum_increment);
                end
            end
        end

        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
        
        % Check if the values are within the required range
        if value(ParamsSection_CP_duration) < starting_total_cp
            ParamsSection_CP_duration.value = starting_total_cp;
        end
        if value(ParamsSection_CP_duration) > cp_max
            ParamsSection_CP_duration.value = cp_max;
        end

    end
end

if value(ParamsSection_CP_duration) >= 1
    ParamsSection_PreStim_time.value = 0.4;
    if value(ParamsSection_CP_duration) < 2
        ParamsSection_A1_time.value = 0.1;
    elseif value(ParamsSection_CP_duration) < 2.5 && value(ParamsSection_CP_duration) >= 2
        ParamsSection_A1_time.value = 0.2;
    elseif value(ParamsSection_CP_duration) < 3 && value(ParamsSection_CP_duration) >= 2.5
        ParamsSection_A1_time.value = 0.3;
    else
        ParamsSection_A1_time.value = 0.4;
    end
elseif value(ParamsSection_CP_duration) < 1 && value(ParamsSection_CP_duration) >= starting_total_cp
    ParamsSection_SettlingIn_time.value = 0.2;
    ParamsSection_PreStim_time.value = 0.1;
    ParamsSection_A1_time.value = 0.1;
end

%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if value(ParamsSection_CP_duration) >= cp_max && stage5_trial_counter > 1000
    if SessionPerformanceSection_violation_recent < 0.1 && SessionPerformanceSection_timeout_recent < 0.1 && stage5_violation_percent < 0.3 && n_completed_trials > 100
        sm = value(SessionDefinition_my_session_model);
        SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
        last_session_cp = value(ParamsSection_CP_duration);
    end
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
stage5_trial_counter_today = 0;
last_session_cp = value(ParamsSection_CP_duration);
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Vary Stimuli location during Centre Poke

%<TRAINING_STAGE>
case 'Vary Stimuli location during Centre Poke'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>
stage6_trial_counter = 0;
stage6_trial_counter_today = 0;
stage6_timeout_percent = 0;
stage6_violation_percent = 0;
cp_max = 5;
n_trial_warmup = 20;
starting_total_cp = 0.5;
prestim_min = 0.5;
prestim_max = 2;

%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
ParamsSection_training_stage.value = 6;
stage6_trial_counter = stage6_trial_counter + 1;
stage6_trial_counter_today = stage6_trial_counter_today + 1;
stage6_timeout_percent = ((stage6_timeout_percent * stage6_trial_counter) + double(timeout_history(end)))/(stage6_trial_counter + 1);
stage6_violation_percent = ((stage6_violation_percent * stage6_trial_counter) + double(violation_history(end)))/(stage6_trial_counter + 1);

% Warm Up If starting a new session
if n_completed_trials == 0
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
elseif n_completed_trials == 1
    ParamsSection_CP_duration.value = starting_total_cp;
else
    if value(ParamsSection_CP_duration) < cp_max  % warm up stage
        if ~violation_history(end) && ~timeout_history(end)
            increment = (cp_max - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
            ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
            % Check if the values are within the required range
            if value(ParamsSection_CP_duration) < starting_total_cp
                ParamsSection_CP_duration.value = starting_total_cp;
            end
            if value(ParamsSection_CP_duration) > cp_max
                ParamsSection_CP_duration.value = cp_max;
            end
        end
    end
end

if value(ParamsSection_CP_duration) < 3 % during the warm up phase
    ParamsSection_SettlingIn_time.value = 0.2;
    ParamsSection_PreStim_time.value = 0.1;
    ParamsSection_A1_time.value = 0.1;
else
    ParamsSection_A1_time.value = 0.4; % actual training stage
    time_range_PreStim_time = prestim_min : 0.01 : prestim_max;
    ParamsSection_PreStim_time.value = time_range_PreStim_time(randi([1, numel(time_range_PreStim_time)],1,1));
end

%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if stage6_trial_counter > 1500
    if SessionPerformanceSection_violation_recent < 0.15 && SessionPerformanceSection_timeout_recent < 0.15 && stage6_violation_percent < 0.25
        sm = value(SessionDefinition_my_session_model);
        SessionDefinition_my_session_model.value = jump(sm, 'offset',+1);
    end
end
%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
stage6_trial_counter_today = 0;
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% Variable Stimuli Go Cue location during Centre Poke

%<TRAINING_STAGE>
case 'Variable Stimuli Go Cue location during Centre Poke'
if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>
stage7_trial_counter = 0;
stage7_trial_counter_today = 0;
stage7_timeout_percent = 0;
stage7_violation_percent = 0;

% Variables for warmup stage
cp_max = 5;
n_trial_warmup = 20;
starting_total_cp = 0.5;
warmup_completed = 0;
%</HELPER_VARS>
end
if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
ParamsSection_training_stage.value = 7;
stage7_trial_counter = stage7_trial_counter + 1;
stage7_trial_counter_today = stage7_trial_counter_today + 1;
stage7_timeout_percent = ((stage7_timeout_percent * stage7_trial_counter) + double(timeout_history(end)))/(stage7_trial_counter + 1);
stage7_violation_percent = ((stage7_violation_percent * stage7_trial_counter) + double(violation_history(end)))/(stage7_trial_counter + 1);

if stage7_trial_counter < 2000
    % the rat has been not been trained for good amount of sessions wait for the user
    % to play around with the settings
    ParamsSection_warmup_on.value = 1;
    ParamsSection_random_PreStim_time.value = 1;
    ParamsSection_random_prego_time.value = 1;
    ParamsSection_random_A1_time.value = 0;
    ParamsSection_PreStim_time_Min.value = 0.2;
    ParamsSection_PreStim_time_Max.value = 2;
    ParamsSection_time_bet_aud1_gocue_Min.value = 0.2;
    ParamsSection_time_bet_aud1_gocue_Min.value = 2;
    ParamsSection_A1_time.value = 0.4;
end

% Warm Up If starting a new session
if ParamsSection_warmup_on == 1
    if n_completed_trials == 0
        ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
        warmup_completed = 0;
    elseif n_completed_trials == 1
        ParamsSection_CP_duration.value = starting_total_cp;
    else
        if value(ParamsSection_CP_duration) <= cp_max  % warm up stage
            if ~violation_history(end) && ~timeout_history(end)
                increment = (cp_max - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
                ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
                % Check if the values are within the required range
                if value(ParamsSection_CP_duration) < starting_total_cp
                    ParamsSection_CP_duration.value = starting_total_cp;
                end
                if value(ParamsSection_CP_duration) >= cp_max
                    ParamsSection_CP_duration.value = cp_max;
                    warmup_completed = 1;
                end
            end
        end
    end
else
    warmup_completed = 1;
end

if warmup_completed == 1
    if value(ParamsSection_random_A1_time)
        time_range_A1_time = ParamsSection_A1_time_Min : 0.1 : ParamsSection_A1_time_Max;
        ParamsSection_A1_time.value = time_range_A1_time(randi([1, numel(time_range_A1_time)],1,1));
    end
    if value(ParamsSection_random_PreStim_time)
        time_range_PreStim_time = ParamsSection_PreStim_time_Min : 0.1 : ParamsSection_PreStim_time_Max;
        ParamsSection_PreStim_time.value = time_range_PreStim_time(randi([1, numel(time_range_PreStim_time)],1,1));
    end
    if value(ParamsSection_random_prego_time)
        time_range_prego_time = ParamsSection_time_bet_aud1_gocue_Min : 0.1 : ParamsSection_time_bet_aud1_gocue_Min;
        ParamsSection_time_bet_aud1_gocue.value = time_range_prego_time(randi([1, numel(time_range_prego_time)],1,1));
    end
end
%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>

%</COMPLETION_TEST>
if exist('ans', 'var')
varargout{1}=logical(ans); clear('ans');
else
varargout{1}=false;
end
end
if eod_logic_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<END_OF_DAY_LOGIC>
stage7_trial_counter_today = 0;
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

    
end

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%<HELPER_FUNCTIONS>

%</HELPER_FUNCTIONS>

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
