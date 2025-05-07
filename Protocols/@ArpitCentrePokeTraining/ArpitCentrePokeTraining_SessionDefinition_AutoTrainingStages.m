%Training stage file.
%Please use the session automator window exclusively
%to edit this file.

function varargout = ArpitCentrePokeTraining_SessionDefinition_AutoTrainingStages(obj, action, varargin)

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
CreateHelperVar(obj,'stage_start_completed_trial','value',n_completed_trials,'force_init',true);
%</HELPER_VARS>
end


if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);


%<STAGE_ALGORITHM>

% Update ParamsSection
ParamsSection_MaxSame.value = 4;
callback(ParamsSection_MaxSame);
stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end

% Update Training_ParamsSection
if value(previous_sides(end)) ~= value(previous_sides(end-1)) && all(hit_history(end-1:end)) % last and present trials should also be a valid trial
    Training_ParamsSection_trial_oppSide = value(Training_ParamsSection_trial_oppSide) + 1;  % updating value for variable in TrainingParams_Section
    callback(Training_ParamsSection_trial_oppSide);
end

% Updating Disp Values for Training_Peformance_Summary
if n_completed_trials > 0
    Training_Performance_Summary_stage_1_Trials.value = value(Training_Performance_Summary_stage_1_Trials) + 1;
    Training_Performance_Summary_stage_1_TrialsToday.value = value(Training_Performance_Summary_stage_1_TrialsToday) + 1;
    Training_Performance_Summary_stage_1_ViolationRate.value = nan;
    Training_Performance_Summary_stage_1_TimeoutRate.value = nan;
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_1_TrialsValid.value = value(Training_Performance_Summary_stage_1_TrialsValid) + 1;
    end
  callback(Training_Performance_Summary_stage_1_Trials);
  callback(Training_Performance_Summary_stage_1_TrialsToday)
  callback(Training_Performance_Summary_stage_1_ViolationRate);
  callback(Training_Performance_Summary_stage_1_TimeoutRate);
  callback(Training_Performance_Summary_stage_1_TrialsValid);
  
  %  Updating Disp Values for Training_Peformance_Summary
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = nan;
  SessionPerformanceSection_timeout_rate.value = nan;
  SessionPerformanceSection_violation_recent.value = nan;
  SessionPerformanceSection_timeout_recent.value = nan;
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_1_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_1_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = nan;
  SessionPerformanceSection_violation_stage.value = nan;
  
  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);

end
%</STAGE_ALGORITHM>
end


if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
    % only run it if its the start of the day, number of trials is small
    if n_completed_trials < 100
        if value(Training_Performance_Summary_stage_1_TrialsValid) > value(Training_ParamsSection_total_trials) && ...
                value(Training_ParamsSection_trial_oppSide) > value(Training_ParamsSection_total_trials_opp)
            ParamsSection_training_stage.value = stage_no + 1;
            callback(ParamsSection_training_stage);
            ParamsSection(obj, 'Changed_Training_Stage');
            SessionDefinition(obj, 'jump_to_stage', 'Timeout Rewarded Side Pokes');
        end
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
stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if value(Training_Performance_Summary_stage_1_TrialsValid) > value(Training_ParamsSection_total_trials) && ...
        value(Training_ParamsSection_trial_oppSide) > value(Training_ParamsSection_total_trials_opp)
    ParamsSection_training_stage.value = stage_no + 1;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
    SessionDefinition(obj, 'jump_to_stage', 'Timeout Rewarded Side Pokes');
end
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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
CreateHelperVar(obj,'this_stage_opp_side_trials', 'value', 0, 'force_init',true);
%</HELPER_VARS>
end


if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
% Change ParamsSection Vars
ParamsSection_MaxSame.value = 4;
callback(ParamsSection_MaxSame);
stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end
% Update the reward collection time based upon behav
if length(timeout_history) > 5
    if all(value(timeout_history(end-1:end))) && value(this_stage_opp_side_trials) >= 2
        ParamsSection_RewardCollection_duration.value = min([value(ParamsSection_RewardCollection_duration) + 1,...
            value(Training_ParamsSection_max_rColl_dur)]);
        callback(ParamsSection_RewardCollection_duration);
        this_stage_opp_side_trials.value = 0;
    end
    if ~any(value(timeout_history(end-1:end)))  && value(this_stage_opp_side_trials) >= 2
        ParamsSection_RewardCollection_duration.value = max([value(ParamsSection_RewardCollection_duration) - 1,...
            value(Training_ParamsSection_min_rColl_dur)]);
        callback(ParamsSection_RewardCollection_duration);
        this_stage_opp_side_trials.value = 0;
    end
end
if length(timeout_history) > 20
    if all(value(timeout_history(end-19:end)))
        ParamsSection_RewardCollection_duration.value = 120;
        callback(ParamsSection_RewardCollection_duration);
    end
end

% Update Training_ParamsSection
if value(previous_sides(end)) ~= value(previous_sides(end-1)) && all(hit_history(end-1:end)) % last and present trials should also be a valid trial
    Training_ParamsSection_trial_oppSide = value(Training_ParamsSection_trial_oppSide) + 1;  % updating value for variable in TrainingParams_Section
    callback(Training_ParamsSection_trial_oppSide);
end


% Updating Disp Values for Training_Peformance_Summary
if n_completed_trials > 0
    Training_Performance_Summary_stage_2_Trials.value = value(Training_Performance_Summary_stage_2_Trials) + 1;
    Training_Performance_Summary_stage_2_TrialsToday.value = value(Training_Performance_Summary_stage_2_TrialsToday) + 1;
    Training_Performance_Summary_stage_2_ViolationRate.value = nan;
    Training_Performance_Summary_stage_2_TimeoutRate.value = ((value(Training_Performance_Summary_stage_2_TimeoutRate) * (value(Training_Performance_Summary_stage_2_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_2_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_2_TrialsValid.value = value(Training_Performance_Summary_stage_2_TrialsValid) + 1;
    end
  
  callback(Training_Performance_Summary_stage_2_Trials);
  callback(Training_Performance_Summary_stage_2_TrialsToday)
  callback(Training_Performance_Summary_stage_2_ViolationRate);
  callback(Training_Performance_Summary_stage_2_TimeoutRate);
  callback(Training_Performance_Summary_stage_2_TrialsValid);

  %  Updating Disp Values for Training_Peformance_Summary
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = nan;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  SessionPerformanceSection_violation_recent.value = nan;  
  if n_completed_trials >= 20
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = nan;
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_2_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_2_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_2_TimeoutRate);
  
  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end

%</STAGE_ALGORITHM>
end


if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
    % only run it if its the start of the day, number of trials is small
    if n_completed_trials > 50
        if value(Training_Performance_Summary_stage_2_TrialsValid) > value(Training_ParamsSection_total_trials) && ...
        value(Training_ParamsSection_trial_oppSide) > value(Training_ParamsSection_total_trials_opp)
            ParamsSection_training_stage.value = stage_no + 1;
            callback(ParamsSection_training_stage);
            ParamsSection(obj, 'Changed_Training_Stage');
            SessionDefinition(obj, 'jump_to_stage', 'Introduce Centre Poke');
        end
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
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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

%</HELPER_VARS>
end


if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
% Maximum & Minimum duration of center poke, in secs:
cp_max = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
cp_min = value(ParamsSection_init_CP_duration);
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;
ParamsSection_MaxSame.value = Inf;
callback(ParamsSection_MaxSame);

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end
% Change the value of CP Duration
if value(Training_ParamsSection_last_session_CP) == 0 && value(Training_Performance_Summary_stage_3_Trials) < 2
    ParamsSection_CP_duration.value = cp_min; % initialize to min_CP
end

if n_completed_trials < 1 % intialize to min value at the start of each session/day
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
else
    if ~timeout_history(end) && value(ParamsSection_CP_duration) < cp_max
        increment = value(ParamsSection_CP_duration) * value(Training_ParamsSection_CPfraction_inc);
        if increment < cp_minimum_increment
            increment = cp_minimum_increment;
        end
        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
    end	
end
callback(ParamsSection_CP_duration);

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_3_Trials.value = value(Training_Performance_Summary_stage_3_Trials) + 1;
    Training_Performance_Summary_stage_3_TrialsToday.value = value(Training_Performance_Summary_stage_3_TrialsToday) + 1;
    Training_Performance_Summary_stage_3_ViolationRate.value = nan;
    Training_Performance_Summary_stage_3_TimeoutRate.value = ((value(Training_Performance_Summary_stage_3_TimeoutRate) * (value(Training_Performance_Summary_stage_3_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_3_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_3_TrialsValid.value = value(Training_Performance_Summary_stage_3_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_3_Trials);
    callback(Training_Performance_Summary_stage_3_TrialsToday)
    callback(Training_Performance_Summary_stage_3_ViolationRate);
    callback(Training_Performance_Summary_stage_3_TimeoutRate);
    callback(Training_Performance_Summary_stage_3_TrialsValid);
  
  % Updating Disp Values for Training_Peformance_Summary
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = nan;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  SessionPerformanceSection_violation_recent.value = nan;
  if n_completed_trials >= 20
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = nan;
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_3_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_3_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_3_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end

%</STAGE_ALGORITHM>
end


if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    cp_max = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
    if value(ParamsSection_CP_duration) >= cp_max
        Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        callback(Training_ParamsSection_last_session_CP);
        ParamsSection_training_stage.value = 4;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Introduce Violation for Centre Poke');
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
% Update the CP duration reached in this session
Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(Training_ParamsSection_last_session_CP);
% Reset the number of trials done today for this stage
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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

%</HELPER_VARS>
end



if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>

% Maximum & Minimum duration of center poke, in secs:
cp_min = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
cp_max = value(Training_ParamsSection_max_CP);
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = value(Training_ParamsSection_CPfraction_inc);
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end

% Change the value of CP Duration
if value(Training_Performance_Summary_stage_4_Trials) < 2
    ParamsSection_CP_duration.value = cp_min; % initialize to min_CP
end

if n_completed_trials < 1
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
else
    if ~violation_history(end) && ~timeout_history(end) && value(ParamsSection_CP_duration) < cp_max
        increment = value(ParamsSection_CP_duration) * cp_fraction;
        if increment < cp_minimum_increment
            increment = cp_minimum_increment;
        end
        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
    end	
end
if value(ParamsSection_CP_duration) > cp_max
    ParamsSection_CP_duration.value = cp_max;
end

callback(ParamsSection_CP_duration);

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_4_Trials.value = value(Training_Performance_Summary_stage_4_Trials) + 1;
    Training_Performance_Summary_stage_4_TrialsToday.value = value(Training_Performance_Summary_stage_4_TrialsToday) + 1;
    Training_Performance_Summary_stage_4_ViolationRate.value = ((value(Training_Performance_Summary_stage_4_ViolationRate) * (value(Training_Performance_Summary_stage_4_Trials) - 1)) + double(violation_history(end))) / value(Training_Performance_Summary_stage_4_Trials);
    Training_Performance_Summary_stage_4_TimeoutRate.value = ((value(Training_Performance_Summary_stage_4_TimeoutRate) * (value(Training_Performance_Summary_stage_4_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_4_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_4_TrialsValid.value = value(Training_Performance_Summary_stage_4_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_4_Trials);
    callback(Training_Performance_Summary_stage_4_TrialsToday)
    callback(Training_Performance_Summary_stage_4_ViolationRate);
    callback(Training_Performance_Summary_stage_4_TimeoutRate);
    callback(Training_Performance_Summary_stage_4_TrialsValid);
  
  % Updating Disp Values for Training_Peformance_Summary
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = numel(find(violation_history))/n_completed_trials;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  if n_completed_trials >= 20
      SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end)))/20;
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
      SessionPerformanceSection_violation_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = value(Training_Performance_Summary_stage_4_ViolationRate);
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_4_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_4_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_4_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end
%</STAGE_ALGORITHM>
end


if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    cp_max = value(Training_ParamsSection_max_CP);
    if value(ParamsSection_CP_duration) >= cp_max  && n_completed_trials > 100 && ...
            value(SessionPerformanceSection_violation_recent) < value(Training_ParamsSection_recent_violation) && ...
            value(SessionPerformanceSection_timeout_recent) < value(Training_ParamsSection_recent_timeout) && ...
            value(SessionPerformanceSection_violation_stage) < value(Training_ParamsSection_stage_violation)

        ParamsSection_training_stage.value = 5;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Introduce Stimuli Sound during Centre Poke');
        Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        callback(Training_ParamsSection_last_session_CP);
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
% Update the CP duration reached in this session
Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(Training_ParamsSection_last_session_CP);
% Reset the number of trials done today for this stage
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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

%</HELPER_VARS>
end


if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
cp_max = value(Training_ParamsSection_max_CP);
cp_min = value(Training_ParamsSection_min_CP);
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = value(Training_ParamsSection_CPfraction_inc);
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment = 0.001;
% Starting total center poke duration:
starting_cp = value(Training_ParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
% number of warm-up trials
n_trial_warmup = value(Training_ParamsSection_warm_up_trials);

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end
% Change the value of CP Duration
% Since starting a new session then do a pre warm up to last saved cp
% duration else continue with learning with increased poke time
if n_completed_trials == 0
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
elseif n_completed_trials == 1
    ParamsSection_CP_duration.value = starting_cp;
else
    if ~violation_history(end) && ~timeout_history(end)
        if value(ParamsSection_CP_duration) < max([cp_min,value(Training_ParamsSection_last_session_CP)]) % warm up stage
            increment = (max([cp_min,value(Training_ParamsSection_last_session_CP)]) - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
        else
            if value(ParamsSection_CP_duration) >= value(Training_ParamsSection_last_session_CP) && value(ParamsSection_CP_duration) <= cp_max % no warm up stage
                increment = value(ParamsSection_CP_duration)*cp_fraction;
                if increment < cp_minimum_increment
                    increment = cp_minimum_increment;
                end
            end
        end

        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
        
        % Check if the values are within the required range
        if value(ParamsSection_CP_duration) < starting_cp
            ParamsSection_CP_duration.value = starting_cp;
        end
        if value(ParamsSection_CP_duration) > cp_max
            ParamsSection_CP_duration.value = cp_max;
        end

    end
end
callback(ParamsSection_CP_duration);

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
elseif value(ParamsSection_CP_duration) < 1 && value(ParamsSection_CP_duration) >= starting_cp
    ParamsSection_SettlingIn_time.value = 0.2;
    callback(ParamsSection_SettlingIn_time);
    ParamsSection_PreStim_time.value = 0.1;
    ParamsSection_A1_time.value = 0.1;
end

if value(ParamsSection_CP_duration) >= starting_cp
    ParamsSection_time_bet_aud1_gocue.value = value(ParamsSection_CP_duration) - value(ParamsSection_SettlingIn_time) - value(ParamsSection_A1_time) - value(ParamsSection_PreStim_time);
    callback(ParamsSection_time_bet_aud1_gocue)
    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
end

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_5_Trials.value = value(Training_Performance_Summary_stage_5_Trials) + 1;
    Training_Performance_Summary_stage_5_TrialsToday.value = value(Training_Performance_Summary_stage_5_TrialsToday) + 1;
    Training_Performance_Summary_stage_5_ViolationRate.value = ((value(Training_Performance_Summary_stage_5_ViolationRate) * (value(Training_Performance_Summary_stage_5_Trials) - 1)) + double(violation_history(end))) / value(Training_Performance_Summary_stage_5_Trials);
    Training_Performance_Summary_stage_5_TimeoutRate.value = ((value(Training_Performance_Summary_stage_5_TimeoutRate) * (value(Training_Performance_Summary_stage_5_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_5_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_5_TrialsValid.value = value(Training_Performance_Summary_stage_5_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_5_Trials);
    callback(Training_Performance_Summary_stage_5_TrialsToday)
    callback(Training_Performance_Summary_stage_5_ViolationRate);
    callback(Training_Performance_Summary_stage_5_TimeoutRate);
    callback(Training_Performance_Summary_stage_5_TrialsValid);
  
  % Updating Disp Values for Training_Peformance_Summary
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = numel(find(violation_history))/n_completed_trials;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  if n_completed_trials >= 20
      SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end)))/20;
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
      SessionPerformanceSection_violation_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = value(Training_Performance_Summary_stage_5_ViolationRate);
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_5_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_5_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_5_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end

%</STAGE_ALGORITHM>
end



if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
    if value(ParamsSection_CP_duration) >= value(Training_ParamsSection_max_CP) && value(Training_Performance_Summary_stage_5_TrialsValid) > value(Training_ParamsSection_total_trials)
        if value(SessionPerformanceSection_violation_recent) < value(Training_ParamsSection_recent_violation) && value(SessionPerformanceSection_timeout_recent) < value(Training_ParamsSection_recent_timeout) && ...
                value(SessionPerformanceSection_violation_stage) < value(Training_ParamsSection_stage_violation) && n_completed_trials > 100
            ParamsSection_training_stage.value = stage_no + 1;
            callback(ParamsSection_training_stage);
            ParamsSection(obj, 'Changed_Training_Stage');
            SessionDefinition(obj, 'jump_to_stage', 'Vary Stimuli location during Centre Poke');
            Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        end
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
% Update the CP duration reached in this session
Training_ParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(Training_ParamsSection_last_session_CP);
% Reset the number of trials done today for this stage
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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

%</HELPER_VARS>
end



if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
cp_max = value(Training_ParamsSection_max_CP);
% Starting total center poke duration:
starting_cp = value(Training_ParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
% number of warm-up trials
n_trial_warmup = value(Training_ParamsSection_warm_up_trials);
prestim_min = value(Training_ParamsSection_min_prestim);
prestim_max = value(Training_ParamsSection_max_prestim);
stim_dur = value(Training_ParamsSection_stim_dur);

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end

% Warm Up If starting a new session
if n_completed_trials == 0
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
elseif n_completed_trials == 1
    ParamsSection_CP_duration.value = starting_cp;
else
    if value(ParamsSection_CP_duration) < cp_max  % warm up stage
        if ~violation_history(end) && ~timeout_history(end)
            increment = (cp_max - value(ParamsSection_CP_duration)) / (n_trial_warmup - 1);
            ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
            % Check if the values are within the required range
            if value(ParamsSection_CP_duration) < starting_cp
                ParamsSection_CP_duration.value = starting_cp;
            end
            if value(ParamsSection_CP_duration) > cp_max
                ParamsSection_CP_duration.value = cp_max;
            end
        end
    end
end

callback(ParamsSection_CP_duration);

if value(ParamsSection_CP_duration) < 3  && value(ParamsSection_CP_duration) >= starting_cp % during the warm up phase
    ParamsSection_SettlingIn_time.value = 0.2;
    callback(ParamsSection_SettlingIn_time);
    ParamsSection_PreStim_time.value = 0.1;
    ParamsSection_A1_time.value = 0.1;
else
    ParamsSection_A1_time.value = stim_dur; % actual training stage
    time_range_PreStim_time = prestim_min : 0.01 : prestim_max;
    ParamsSection_PreStim_time.value = time_range_PreStim_time(randi([1, numel(time_range_PreStim_time)],1,1));
end

if value(ParamsSection_CP_duration) >= starting_cp
    ParamsSection_time_bet_aud1_gocue.value = value(ParamsSection_CP_duration) - value(ParamsSection_SettlingIn_time) - value(ParamsSection_A1_time) - value(ParamsSection_PreStim_time);
    callback(ParamsSection_time_bet_aud1_gocue)
    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
end

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_6_Trials.value = value(Training_Performance_Summary_stage_6_Trials) + 1;
    Training_Performance_Summary_stage_6_TrialsToday.value = value(Training_Performance_Summary_stage_6_TrialsToday) + 1;
    Training_Performance_Summary_stage_6_ViolationRate.value = ((value(Training_Performance_Summary_stage_6_ViolationRate) * (value(Training_Performance_Summary_stage_6_Trials) - 1)) + double(violation_history(end))) / value(Training_Performance_Summary_stage_6_Trials);
    Training_Performance_Summary_stage_6_TimeoutRate.value = ((value(Training_Performance_Summary_stage_6_TimeoutRate) * (value(Training_Performance_Summary_stage_6_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_6_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_6_TrialsValid.value = value(Training_Performance_Summary_stage_6_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_6_Trials);
    callback(Training_Performance_Summary_stage_6_TrialsToday)
    callback(Training_Performance_Summary_stage_6_ViolationRate);
    callback(Training_Performance_Summary_stage_6_TimeoutRate);
    callback(Training_Performance_Summary_stage_6_TrialsValid);
  
  % Updating Disp Values for SessionPerformanceSection
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = numel(find(violation_history))/n_completed_trials;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  if n_completed_trials >= 20
      SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end)))/20;
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
      SessionPerformanceSection_violation_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = value(Training_Performance_Summary_stage_6_ViolationRate);
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_6_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_6_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_6_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end

%</STAGE_ALGORITHM>
end
if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
if ParamsSection_use_auto_train % do completion check if auto training
    stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
    if value(Training_Performance_Summary_stage_6_TrialsValid) > value(Training_ParamsSection_total_trials)
        if value(SessionPerformanceSection_violation_recent) < value(Training_ParamsSection_recent_violation) && value(SessionPerformanceSection_timeout_recent) < value(Training_ParamsSection_recent_timeout) && ...
                value(SessionPerformanceSection_violation_stage) < value(Training_ParamsSection_stage_violation) && n_completed_trials > 100
            ParamsSection_training_stage.value = stage_no + 1;
            callback(ParamsSection_training_stage);
            ParamsSection(obj, 'Changed_Training_Stage');
            SessionDefinition(obj, 'jump_to_stage', 'Variable Stimuli Go Cue location during Centre Poke');
        end
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
% Reset the number of trials done today for this stage
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
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

%</HELPER_VARS>
end


if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
% Variables for warmup stage
cp_max = value(Training_ParamsSection_max_CP);
% Starting total center poke duration:
starting_cp = value(Training_ParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
% number of warm-up trials
n_trial_warmup = value(Training_ParamsSection_warm_up_trials);
prestim_min = value(Training_ParamsSection_min_prestim);
prestim_max = value(Training_ParamsSection_max_prestim);
prestim_time = value(Training_ParamsSection_min_prestim);
a1_time = value(Training_ParamsSection_stim_dur);
a1_time_min = value(Training_ParamsSection_stim_dur);
a1_time_max = value(Training_ParamsSection_stim_dur + 0.1);
prego_min = value(Training_ParamsSection_min_prego);
prego_max = value(Training_ParamsSection_max_prego);
prego_time = value(Training_ParamsSection_min_prego);
warmup_completed = 0;
warm_up_on = 1;
random_prestim = 1;
random_prego = 1;
random_A1 = 0;

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end

% Warm Up If starting a new session
if warm_up_on == 1
    if n_completed_trials == 0
        ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
        warmup_completed = 0;
    elseif n_completed_trials == 1
        ParamsSection_CP_duration.value = starting_cp;
    else
        if value(ParamsSection_CP_duration) <= cp_max  % warm up stage
            if ~violation_history(end) && ~timeout_history(end)
                increment = (cp_max - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
                ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
                % Check if the values are within the required range
                if value(ParamsSection_CP_duration) < starting_cp
                    ParamsSection_CP_duration.value = starting_cp;
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

if n_completed_trials >= 1
    cp_length = value(ParamsSection_CP_duration) - value(ParamsSection_SettlingIn_time);
    [ParamsSection_PreStim_time.value ,ParamsSection_A1_time.value,ParamsSection_time_bet_aud1_gocue.value] = param_time_within_range(warmup_completed,...
        cp_length,prestim_min,prestim_max, random_prestim, prestim_time,...
        a1_time_min,a1_time_max, random_A1, a1_time,prego_min,prego_max, random_prego, prego_time);

    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
    ParamsSection_CP_duration.value = value(ParamsSection_SettlingIn_time) + value(ParamsSection_PreStim_time) + value(ParamsSection_A1_time) + value(ParamsSection_time_bet_aud1_gocue);
end
callback(ParamsSection_CP_duration);

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_7_Trials.value = value(Training_Performance_Summary_stage_7_Trials) + 1;
    Training_Performance_Summary_stage_7_TrialsToday.value = value(Training_Performance_Summary_stage_7_TrialsToday) + 1;
    Training_Performance_Summary_stage_7_ViolationRate.value = ((value(Training_Performance_Summary_stage_7_ViolationRate) * (value(Training_Performance_Summary_stage_7_Trials) - 1)) + double(violation_history(end))) / value(Training_Performance_Summary_stage_7_Trials);
    Training_Performance_Summary_stage_7_TimeoutRate.value = ((value(Training_Performance_Summary_stage_7_TimeoutRate) * (value(Training_Performance_Summary_stage_7_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_7_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_7_TrialsValid.value = value(Training_Performance_Summary_stage_7_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_7_Trials);
    callback(Training_Performance_Summary_stage_7_TrialsToday)
    callback(Training_Performance_Summary_stage_7_ViolationRate);
    callback(Training_Performance_Summary_stage_7_TimeoutRate);
    callback(Training_Performance_Summary_stage_7_TrialsValid);
  
  % Updating Disp Values for SessionPerformanceSection
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = numel(find(violation_history))/n_completed_trials;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  if n_completed_trials >= 20
      SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end)))/20;
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
      SessionPerformanceSection_violation_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = value(Training_Performance_Summary_stage_7_ViolationRate);
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_7_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_7_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_7_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
end

%</STAGE_ALGORITHM>
end



if completion_test_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
clear('ans');
%<COMPLETION_TEST>
stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);

if value(Training_Performance_Summary_stage_7_TrialsValid) > value(Training_ParamsSection_total_trials)
    if value(SessionPerformanceSection_violation_recent) < value(Training_ParamsSection_recent_violation) && value(SessionPerformanceSection_timeout_recent) < value(Training_ParamsSection_recent_timeout) && ...
        value(SessionPerformanceSection_violation_stage) < value(Training_ParamsSection_stage_violation)
        ParamsSection_training_stage.value = stage_no + 1;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'User Setting');
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
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

%% User Setting

%<TRAINING_STAGE>
    case 'User Setting'


if helper_vars_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<HELPER_VARS>

%</HELPER_VARS>
end



if stage_algorithm_eval
GetSoloFunctionArgs(obj);
ClearHelperVarsNotOwned(obj);
%<STAGE_ALGORITHM>
% Variables for warmup stage
cp_max = 5;
n_trial_warmup = 20;
starting_cp = 0.5;
warmup_completed = 0;
warm_up_on = value(ParamsSection_warmup_on);
random_prestim = value(ParamsSection_random_PreStim_time);
random_prego = value(ParamsSection_random_prego_time);
random_A1 = value(ParamsSection_random_A1_time);
prestim_min = value(ParamsSection_PreStim_time_Min);
prestim_max = value(ParamsSection_PreStim_time_Max);
prestim_time = value(ParamsSection_PreStim_time);
prego_min = value(ParamsSection_time_bet_aud1_gocue_Min);
prego_max = value(ParamsSection_time_bet_aud1_gocue_Max);
prego_time = value(ParamsSection_time_bet_aud1_gocue);
a1_time = value(ParamsSection_A1_time);
a1_time_min = value(ParamsSection_A1_time_Min);
a1_time_max = value(ParamsSection_A1_time_Max);

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
end

% Warm Up If starting a new session
if warm_up_on == 1
    if n_completed_trials == 0
        ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
        warmup_completed = 0;
    elseif n_completed_trials == 1
        ParamsSection_CP_duration.value = starting_cp;
    else
        if value(ParamsSection_CP_duration) <= cp_max  % warm up stage
            if ~violation_history(end) && ~timeout_history(end)
                increment = (cp_max - value(ParamsSection_CP_duration))/ (n_trial_warmup - 1);
                ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
                % Check if the values are within the required range
                if value(ParamsSection_CP_duration) < starting_cp
                    ParamsSection_CP_duration.value = starting_cp;
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

if n_completed_trials >= 1
    cp_length = value(ParamsSection_CP_duration) - value(ParamsSection_SettlingIn_time);
    [ParamsSection_PreStim_time.value ,ParamsSection_A1_time.value,ParamsSection_time_bet_aud1_gocue.value] = param_time_within_range(warmup_completed,...
        cp_length,prestim_min,prestim_max, random_prestim, prestim_time,...
        a1_time_min,a1_time_max, random_A1, a1_time,prego_min,prego_max, random_prego, prego_time);

    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
    ParamsSection_CP_duration.value = value(ParamsSection_SettlingIn_time) + value(ParamsSection_PreStim_time) + value(ParamsSection_A1_time) + value(ParamsSection_time_bet_aud1_gocue);
end
callback(ParamsSection_CP_duration);

if n_completed_trials > 0
    % Updating Disp Values for Training_Peformance_Summary
    Training_Performance_Summary_stage_8_Trials.value = value(Training_Performance_Summary_stage_8_Trials) + 1;
    Training_Performance_Summary_stage_8_TrialsToday.value = value(Training_Performance_Summary_stage_8_TrialsToday) + 1;
    Training_Performance_Summary_stage_8_ViolationRate.value = ((value(Training_Performance_Summary_stage_8_ViolationRate) * (value(Training_Performance_Summary_stage_8_Trials) - 1)) + double(violation_history(end))) / value(Training_Performance_Summary_stage_8_Trials);
    Training_Performance_Summary_stage_8_TimeoutRate.value = ((value(Training_Performance_Summary_stage_8_TimeoutRate) * (value(Training_Performance_Summary_stage_8_Trials) - 1)) + double(timeout_history(end))) / value(Training_Performance_Summary_stage_8_Trials);
    if ~isnan(value(hit_history(end)))
        Training_Performance_Summary_stage_8_TrialsValid.value = value(Training_Performance_Summary_stage_8_TrialsValid) + 1;
    end

    callback(Training_Performance_Summary_stage_8_Trials);
    callback(Training_Performance_Summary_stage_8_TrialsToday)
    callback(Training_Performance_Summary_stage_8_ViolationRate);
    callback(Training_Performance_Summary_stage_8_TimeoutRate);
    callback(Training_Performance_Summary_stage_8_TrialsValid);
  
  % Updating Disp Values for SessionPerformanceSection
  SessionPerformanceSection_ntrials.value = n_completed_trials;
  SessionPerformanceSection_violation_rate.value = numel(find(violation_history))/n_completed_trials;
  SessionPerformanceSection_timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
  if n_completed_trials >= 20
      SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end)))/20;
      SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
  else
      SessionPerformanceSection_timeout_recent.value = nan;
      SessionPerformanceSection_violation_recent.value = nan;
  end
  SessionPerformanceSection_violation_stage.value = value(Training_Performance_Summary_stage_8_ViolationRate);
  SessionPerformanceSection_ntrials_stage.value = value(Training_Performance_Summary_stage_8_Trials);
  SessionPerformanceSection_ntrials_stage_today.value = value(Training_Performance_Summary_stage_8_TrialsToday);
  SessionPerformanceSection_timeout_stage.value = value(Training_Performance_Summary_stage_8_TimeoutRate);

  callback(SessionPerformanceSection_ntrials);
  callback(SessionPerformanceSection_ntrials_stage);
  callback(SessionPerformanceSection_ntrials_stage_today)
  callback(SessionPerformanceSection_violation_rate);
  callback(SessionPerformanceSection_timeout_rate);
  callback(SessionPerformanceSection_violation_recent);
  callback(SessionPerformanceSection_timeout_recent);
  callback(SessionPerformanceSection_violation_stage);
  callback(SessionPerformanceSection_timeout_stage);
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
Training_Performance_Summary_stage_1_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_1_TrialsToday);
Training_Performance_Summary_stage_2_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_2_TrialsToday);
Training_Performance_Summary_stage_3_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_3_TrialsToday);
Training_Performance_Summary_stage_4_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_4_TrialsToday);
Training_Performance_Summary_stage_5_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_5_TrialsToday);
Training_Performance_Summary_stage_6_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_6_TrialsToday);
Training_Performance_Summary_stage_7_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_7_TrialsToday);
Training_Performance_Summary_stage_8_TrialsToday.value = 0;
callback(Training_Performance_Summary_stage_8_TrialsToday);
%</END_OF_DAY_LOGIC>
end
%</TRAINING_STAGE>

    
end

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%<HELPER_FUNCTIONS>

function [prestim,A1,prego] = param_time_within_range(fixed_length,cp_length,range_min_prestim,range_max_prestim, is_random_prestim, provided_time_prestim,...
    range_min_A1,range_max_A1, is_random_A1, provided_time_A1,range_min_prego,range_max_prego, is_random_prego, provided_time_prego)

if fixed_length == 1 % warm up stage where cp length is increasing
% then calculate the range/typical value
    if cp_length <= 0.3
        prestim = 0.1;
        A1 = 0.1;
        prego = 0.1;
    else
        range_size = round(0.3 * cp_length,1);
        if range_size > 0.4
            step_size = 0.1;
        else
            step_size = 0.01;
        end

        timerange = 0.1:step_size:range_size;

        if is_random_prestim == 1
            prestim = timerange(randi([1, numel(timerange)],1,1));
        else
            if provided_time_prestim <= range_size
                prestim = provided_time_prestim;
            else
                prestim = range_size;
            end

        end

        if is_random_A1 == 1
            A1 = timerange(randi([1, numel(timerange)],1,1));
        else
            if provided_time_A1 <= range_size
                A1 = provided_time_A1;
            else
                A1 = range_size;
            end
        end

        prego = cp_length - prestim - A1;

    end

else

    if is_random_prestim == 1
        range_size_prestim = range_max_prestim - range_min_prestim;
        if range_size_prestim > 0.4
            step_size_prestim = 0.1;
        else
            step_size_prestim = 0.01;
        end
        time_range_prestim = range_min_prestim:step_size_prestim:range_max_prestim;
        prestim = time_range_prestim(randi([1, numel(time_range_prestim)],1,1));
    else
        prestim = provided_time_prestim;
    end

    if is_random_A1 == 1
        range_size_A1 = range_max_A1 - range_min_A1;
        if range_size_A1 > 0.4
            step_size_A1 = 0.1;
        else
            step_size_A1 = 0.01;
        end
        time_range_A1 = range_min_A1:step_size_A1:range_max_A1;
        A1 = time_range_A1(randi([1, numel(time_range_A1)],1,1));
    else
        A1 = provided_time_A1;
    end

    if is_random_prego == 1
        range_size_prego = range_max_prego - range_min_prego;
        if range_size_prego > 0.4
            step_size_prego = 0.1;
        else
            step_size_prego = 0.01;
        end
        time_range_prego = range_min_prego:step_size_prego:range_max_prego;
        prego = time_range_prego(randi([1, numel(time_range_prego)],1,1));
    else
        prego = provided_time_prego;
    end

end
end


%</HELPER_FUNCTIONS>

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
