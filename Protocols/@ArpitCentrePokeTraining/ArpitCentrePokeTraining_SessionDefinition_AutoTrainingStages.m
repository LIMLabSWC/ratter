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
CreateHelperVar(obj,'stage_start_completed_trial','value',n_done_trials,'force_init',true);
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
    ParamsSection(obj, 'Changed_Training_Stage');
end

% Introduce Go/Reward Sound intensity after the rat did some trials and also increase
% it gradually until the max sound played at around 0.05. We will start
% with 0.001
if value(PerformanceSummarySection_stage_1_TrialsValid) < value(TrainingStageParamsSection_Go_Sound_Start)
    ParamsSection_Go_Sound.value = 0;
elseif  value(PerformanceSummarySection_stage_1_TrialsValid) == value(TrainingStageParamsSection_Go_Sound_Start)% start gradual increase
    ParamsSection_Go_Sound.value = 1;
    SoundInterface_GoSoundVol.value = 0.001;
else
    ParamsSection_Go_Sound.value = 1;
    SoundInterface_GoSoundVol.value = value(SoundInterface_GoSoundVol) + ((0.05 - 0.001) / (value(TrainingStageParamsSection_total_trials) - value(TrainingStageParamsSection_Go_Sound_Start)));
end
callback(SoundInterface_GoSoundVol);
callback(ParamsSection_Go_Sound);

% Update TrainingStageParamsSection
if n_done_trials >= 2
    if previous_sides(end) ~= previous_sides(end-1) % last and present trials should also be a valid trial
        TrainingStageParamsSection_trial_oppSide.value = value(TrainingStageParamsSection_trial_oppSide) + 1;  % updating value for variable in TrainingParams_Section
        callback(TrainingStageParamsSection_trial_oppSide);
    end
end

% Updating Disp Values for Training_Peformance_Summary
% FIX: all performance updates guarded by n_done_trials > 0 to avoid divide-by-zero
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_1_Trials.value = value(PerformanceSummarySection_stage_1_Trials) + 1;
    PerformanceSummarySection_stage_1_TrialsToday.value = value(PerformanceSummarySection_stage_1_TrialsToday) + 1;
    PerformanceSummarySection_stage_1_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_1_ViolationRate) * (value(PerformanceSummarySection_stage_1_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_1_Trials);
    PerformanceSummarySection_stage_1_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_1_TimeoutRate) * (value(PerformanceSummarySection_stage_1_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_1_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_1_TrialsValid.value = value(PerformanceSummarySection_stage_1_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_1_Trials);
    callback(PerformanceSummarySection_stage_1_TrialsToday);
    callback(PerformanceSummarySection_stage_1_ViolationRate);
    callback(PerformanceSummarySection_stage_1_TimeoutRate);
    callback(PerformanceSummarySection_stage_1_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_1_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_1_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_1_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_1_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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

    if value(PerformanceSummarySection_stage_1_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
            value(TrainingStageParamsSection_trial_oppSide) > value(TrainingStageParamsSection_total_trials_opp)
        ParamsSection_training_stage.value = stage_no + 1;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Timeout Rewarded Side Pokes');
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
if value(PerformanceSummarySection_stage_1_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
        value(TrainingStageParamsSection_trial_oppSide) > value(TrainingStageParamsSection_total_trials_opp)
    ParamsSection_training_stage.value = stage_no + 1;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
    SessionDefinition(obj, 'jump_to_stage', 'Timeout Rewarded Side Pokes');
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
    ParamsSection(obj, 'Changed_Training_Stage');
end
% Update the reward collection time based upon behav
if length(timeout_history) > 5
    if all(timeout_history(end-1:end)) && value(this_stage_opp_side_trials) >= 2
        ParamsSection_RewardCollection_duration.value = min([value(ParamsSection_RewardCollection_duration) + 1,...
            value(TrainingStageParamsSection_max_rColl_dur)]);
        callback(ParamsSection_RewardCollection_duration);
        this_stage_opp_side_trials.value = 0;
    end
    if ~any(timeout_history(end-1:end))  && value(this_stage_opp_side_trials) >= 2
        ParamsSection_RewardCollection_duration.value = max([value(ParamsSection_RewardCollection_duration) - 1,...
            value(TrainingStageParamsSection_min_rColl_dur)]);
        callback(ParamsSection_RewardCollection_duration);
        this_stage_opp_side_trials.value = 0;
    end
end
if length(timeout_history) > 20
    if all(timeout_history(end-19:end))
        ParamsSection_RewardCollection_duration.value = 120;
        callback(ParamsSection_RewardCollection_duration);
    end
end

% Update TrainingStageParamsSection
if n_done_trials >= 2
    if previous_sides(end) ~= previous_sides(end-1) && all(~isnan(hit_history(end-1:end)))% last and present trials should also be a valid trial
        TrainingStageParamsSection_trial_oppSide.value = value(TrainingStageParamsSection_trial_oppSide) + 1;  % updating value for variable in TrainingParams_Section
        this_stage_opp_side_trials.value = value(this_stage_opp_side_trials) + 1; % updating value to change the reward_Collection_Dur
        callback(TrainingStageParamsSection_trial_oppSide);
    end
end


% Performance section updates
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_2_Trials.value = value(PerformanceSummarySection_stage_2_Trials) + 1;
    PerformanceSummarySection_stage_2_TrialsToday.value = value(PerformanceSummarySection_stage_2_TrialsToday) + 1;
    PerformanceSummarySection_stage_2_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_2_ViolationRate) * (value(PerformanceSummarySection_stage_2_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_2_Trials);
    PerformanceSummarySection_stage_2_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_2_TimeoutRate) * (value(PerformanceSummarySection_stage_2_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_2_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_2_TrialsValid.value = value(PerformanceSummarySection_stage_2_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_2_Trials);
    callback(PerformanceSummarySection_stage_2_TrialsToday);
    callback(PerformanceSummarySection_stage_2_ViolationRate);
    callback(PerformanceSummarySection_stage_2_TimeoutRate);
    callback(PerformanceSummarySection_stage_2_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_2_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_2_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_2_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_2_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
    if n_done_trials > 50
        if value(PerformanceSummarySection_stage_2_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
        value(TrainingStageParamsSection_trial_oppSide) > value(TrainingStageParamsSection_total_trials_opp)
            ParamsSection_RewardCollection_duration.value = 40;
            callback(ParamsSection_RewardCollection_duration);
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
% Maximum & Minimum duration of center poke, in secs.
% max_CP here is SettlingIn + legal_cbreak (the ceiling for this stage
% before violation is introduced).
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
    ParamsSection(obj, 'Changed_Training_Stage');
end

% FIX: guard against last_session_CP being 0 (default) on a fresh animal.
% Use max() so CP never starts below init_CP_duration.
if n_done_trials < 1
    ParamsSection_CP_duration.value = cp_min;
elseif n_done_trials == 1
    last_cp = value(TrainingStageParamsSection_last_session_CP);
    ParamsSection_CP_duration.value = max(last_cp, cp_min);
else
    if ~timeout_history(end) && value(ParamsSection_CP_duration) < cp_max
        increment = value(ParamsSection_CP_duration) * value(TrainingStageParamsSection_CPfraction_inc);
        if increment < cp_minimum_increment
            increment = cp_minimum_increment;
        end
        ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
    end	
end
% Never exceed stage ceiling
if value(ParamsSection_CP_duration) > cp_max
    ParamsSection_CP_duration.value = cp_max;
end
callback(ParamsSection_CP_duration);

% Performance section updates
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_3_Trials.value = value(PerformanceSummarySection_stage_3_Trials) + 1;
    PerformanceSummarySection_stage_3_TrialsToday.value = value(PerformanceSummarySection_stage_3_TrialsToday) + 1;
    PerformanceSummarySection_stage_3_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_3_ViolationRate) * (value(PerformanceSummarySection_stage_3_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_3_Trials);
    PerformanceSummarySection_stage_3_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_3_TimeoutRate) * (value(PerformanceSummarySection_stage_3_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_3_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_3_TrialsValid.value = value(PerformanceSummarySection_stage_3_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_3_Trials);
    callback(PerformanceSummarySection_stage_3_TrialsToday);
    callback(PerformanceSummarySection_stage_3_ViolationRate);
    callback(PerformanceSummarySection_stage_3_TimeoutRate);
    callback(PerformanceSummarySection_stage_3_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_3_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_3_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_3_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_3_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
        TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        ParamsSection_RewardCollection_duration.value = 8;
        callback(ParamsSection_RewardCollection_duration);
        callback(TrainingStageParamsSection_last_session_CP);
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
TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(TrainingStageParamsSection_last_session_CP);
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

% Maximum & Minimum duration of center poke, in secs.
% cp_min is where Stage 3 left off (its ceiling becomes Stage 4's floor).
cp_min = value(ParamsSection_SettlingIn_time) + value(ParamsSection_legal_cbreak);
cp_max = value(TrainingStageParamsSection_max_CP);
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction = value(TrainingStageParamsSection_CPfraction_inc);
% Minimum increment (in secs):
cp_minimum_increment = 0.001;

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
end

% FIX: guard against last_session_CP being 0 (default) on a fresh animal.
% Use max() so CP never starts below cp_min for this stage.
if n_done_trials == 0
    ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
elseif n_done_trials == 1
    last_cp = value(TrainingStageParamsSection_last_session_CP);
    ParamsSection_CP_duration.value = max(last_cp, cp_min);
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

% Performance section updates
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_4_Trials.value = value(PerformanceSummarySection_stage_4_Trials) + 1;
    PerformanceSummarySection_stage_4_TrialsToday.value = value(PerformanceSummarySection_stage_4_TrialsToday) + 1;
    PerformanceSummarySection_stage_4_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_4_ViolationRate) * (value(PerformanceSummarySection_stage_4_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_4_Trials);
    PerformanceSummarySection_stage_4_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_4_TimeoutRate) * (value(PerformanceSummarySection_stage_4_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_4_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_4_TrialsValid.value = value(PerformanceSummarySection_stage_4_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_4_Trials);
    callback(PerformanceSummarySection_stage_4_TrialsToday);
    callback(PerformanceSummarySection_stage_4_ViolationRate);
    callback(PerformanceSummarySection_stage_4_TimeoutRate);
    callback(PerformanceSummarySection_stage_4_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_4_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_4_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_4_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_4_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
    cp_max = value(TrainingStageParamsSection_max_CP);
    if value(ParamsSection_CP_duration) >= cp_max  && n_done_trials > 100 && ...
            value(SessionPerformanceSection_violation_recent) < value(TrainingStageParamsSection_recent_violation) && ...
            value(SessionPerformanceSection_timeout_recent) < value(TrainingStageParamsSection_recent_timeout) && ...
            value(SessionPerformanceSection_violation_stage) < value(TrainingStageParamsSection_stage_violation)

        ParamsSection_training_stage.value = 5;
        callback(ParamsSection_training_stage);
        ParamsSection_RewardCollection_duration.value = 8; % Although done in previous stage as well but still to be sure
        callback(ParamsSection_RewardCollection_duration);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Introduce Stimuli Sound during Centre Poke');
        TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        callback(TrainingStageParamsSection_last_session_CP);
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
TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(TrainingStageParamsSection_last_session_CP);
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
% Read all timing parameters from TrainingStageParamsSection (single source of truth)
cp_max          = value(TrainingStageParamsSection_max_CP);
cp_min          = value(TrainingStageParamsSection_min_CP);
cp_fraction     = value(TrainingStageParamsSection_CPfraction_inc);
cp_minimum_increment = 0.001;
starting_cp     = value(TrainingStageParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
n_trial_warmup  = value(TrainingStageParamsSection_warm_up_trials);
stim_dur        = value(TrainingStageParamsSection_stim_dur);
settling_in     = value(ParamsSection_SettlingIn_time);
% Minimum buffer between go cue onset and end of CP window (safety margin)
min_prego_buffer = 0.05;

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
end

% --- CP duration logic (warmup ramp then fractional increase) ---
init_CP_duration = value(ParamsSection_init_CP_duration);
last_CP  = value(TrainingStageParamsSection_last_session_CP);
curr_CP  = value(ParamsSection_CP_duration);

if n_done_trials == 0
    new_CP = init_CP_duration;
elseif n_done_trials <= n_trial_warmup
    % Linear ramp from init_CP up to last_CP (where Stage 4 ended)
    cp_delta = (last_CP - init_CP_duration) / n_trial_warmup;
    new_CP = init_CP_duration + cp_delta * n_done_trials;
    new_CP = max(new_CP, starting_cp);
else
    % Fractional increment only on clean (non-violation, non-timeout) trials
    if ~violation_history(end) && ~timeout_history(end)
        increment = curr_CP * cp_fraction;
        if increment < cp_minimum_increment
            increment = cp_minimum_increment;
        end
        new_CP = curr_CP + increment;
    else
        new_CP = curr_CP;
    end
end
new_CP = min(new_CP, cp_max);
ParamsSection_CP_duration.value = new_CP;
callback(ParamsSection_CP_duration);

% --- Timing sub-components: single authoritative calculation ---
% Priority: SettlingIn (fixed) > A1/stim (fixed at stim_dur) >
%           PreStim (scales with CP) > prego (fills remainder, >= min_prego_buffer)
%
% FIX: Removed the duplicated/overwriting block that was present in the
% original. All timing is computed once here and clamped so nothing
% goes negative regardless of what max_CP or stim_dur are set to.
if new_CP >= starting_cp

    % PreStim scales linearly from 0.1s (at cp_min) to 0.3s (at cp_max),
    % but is capped so that A1 + PreStim + SettlingIn + min_prego_buffer
    % always fits inside the actual CP window.
    cp_available = new_CP - settling_in;
    raw_scale    = (new_CP - cp_min) / max(cp_max - cp_min, 1e-6);
    raw_scale    = min(max(raw_scale, 0), 1);
    prestim      = 0.1 + raw_scale * (0.3 - 0.1);  % 0.1 → 0.3 s

    % Clamp: if stim + prestim already eat into the safety buffer, reduce prestim first
    if (prestim + stim_dur + min_prego_buffer) > cp_available
        prestim = max(0, cp_available - stim_dur - min_prego_buffer);
    end

    prego = cp_available - prestim - stim_dur;
    prego = max(prego, min_prego_buffer);  % never let prego go below safety buffer

    ParamsSection_SettlingIn_time.value = settling_in;
    ParamsSection_PreStim_time.value    = prestim;
    ParamsSection_A1_time.value         = stim_dur;
    ParamsSection_time_bet_aud1_gocue.value = prego;

    callback(ParamsSection_SettlingIn_time);
    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
end

% Performance section updates
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_5_Trials.value = value(PerformanceSummarySection_stage_5_Trials) + 1;
    PerformanceSummarySection_stage_5_TrialsToday.value = value(PerformanceSummarySection_stage_5_TrialsToday) + 1;
    PerformanceSummarySection_stage_5_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_5_ViolationRate) * (value(PerformanceSummarySection_stage_5_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_5_Trials);
    PerformanceSummarySection_stage_5_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_5_TimeoutRate) * (value(PerformanceSummarySection_stage_5_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_5_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_5_TrialsValid.value = value(PerformanceSummarySection_stage_5_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_5_Trials);
    callback(PerformanceSummarySection_stage_5_TrialsToday);
    callback(PerformanceSummarySection_stage_5_ViolationRate);
    callback(PerformanceSummarySection_stage_5_TimeoutRate);
    callback(PerformanceSummarySection_stage_5_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_5_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_5_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_5_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_5_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
    if value(ParamsSection_CP_duration) >= value(TrainingStageParamsSection_max_CP) && ...
            value(PerformanceSummarySection_stage_5_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
            value(SessionPerformanceSection_violation_recent) < value(TrainingStageParamsSection_recent_violation) && ...
            value(SessionPerformanceSection_timeout_recent) < value(TrainingStageParamsSection_recent_timeout) && ...
            value(SessionPerformanceSection_violation_stage) < value(TrainingStageParamsSection_stage_violation) && ...
            n_done_trials > 100
        ParamsSection_training_stage.value = stage_no + 1;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Vary Stimuli location during Centre Poke');
        TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
        callback(TrainingStageParamsSection_last_session_CP);
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
TrainingStageParamsSection_last_session_CP.value = value(ParamsSection_CP_duration);
callback(TrainingStageParamsSection_last_session_CP);
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
% Read all timing parameters from TrainingStageParamsSection
cp_max          = value(TrainingStageParamsSection_max_CP);
starting_cp     = value(TrainingStageParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
n_trial_warmup  = value(TrainingStageParamsSection_warm_up_trials);
prestim_min     = value(TrainingStageParamsSection_min_prestim);
prestim_max     = value(TrainingStageParamsSection_max_prestim);
stim_dur        = value(TrainingStageParamsSection_stim_dur);
settling_in     = value(ParamsSection_SettlingIn_time);
init_CP_duration = value(ParamsSection_init_CP_duration);
min_prego_buffer = 0.05;

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
end

% --- CP warmup ramp then hold at max ---
if n_done_trials == 0
    new_CP = init_CP_duration;
elseif n_done_trials <= n_trial_warmup
    cp_delta = (cp_max - init_CP_duration) / n_trial_warmup;
    new_CP = init_CP_duration + cp_delta * n_done_trials;
    new_CP = min(max(new_CP, starting_cp), cp_max);
else
    new_CP = cp_max;
end

ParamsSection_CP_duration.value = new_CP;
callback(ParamsSection_CP_duration);

% --- Timing sub-components ---
% FIX: compute available time first, then clamp prestim so prego is
% always >= min_prego_buffer, regardless of what min/max_prestim are set to.
if new_CP >= starting_cp
    ParamsSection_SettlingIn_time.value = settling_in;
    callback(ParamsSection_SettlingIn_time);

    cp_available = new_CP - settling_in;

    if n_done_trials <= n_trial_warmup
        % During warmup: use small fixed values so animal can succeed
        prestim = 0.1;
        A1      = 0.1;
    else
        % Steady state: randomise prestim within [prestim_min, prestim_max]
        % but clamp so stim + prestim + safety buffer fit in the window
        max_allowed_prestim = cp_available - stim_dur - min_prego_buffer;
        effective_prestim_max = min(prestim_max, max_allowed_prestim);
        effective_prestim_max = max(effective_prestim_max, prestim_min); % never below min
        time_range = prestim_min : 0.01 : effective_prestim_max;
        if isempty(time_range)
            time_range = prestim_min;
        end
        prestim = time_range(randi([1, numel(time_range)], 1, 1));
        A1 = stim_dur;
    end

    prego = cp_available - prestim - A1;
    prego = max(prego, min_prego_buffer); % safety clamp

    ParamsSection_PreStim_time.value            = prestim;
    ParamsSection_A1_time.value                 = A1;
    ParamsSection_time_bet_aud1_gocue.value     = prego;

    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
end

% --- Performance Logging ---
if n_done_trials > 0
    if n_done_trials == 1
        for i = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', i));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', i));
        end
    end

    PerformanceSummarySection_stage_6_Trials.value = value(PerformanceSummarySection_stage_6_Trials) + 1;
    PerformanceSummarySection_stage_6_TrialsToday.value = value(PerformanceSummarySection_stage_6_TrialsToday) + 1;
    PerformanceSummarySection_stage_6_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_6_ViolationRate) * (value(PerformanceSummarySection_stage_6_Trials) - 1)) + ...
        double(violation_history(end))) / value(PerformanceSummarySection_stage_6_Trials);
    PerformanceSummarySection_stage_6_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_6_TimeoutRate) * (value(PerformanceSummarySection_stage_6_Trials) - 1)) + ...
        double(timeout_history(end))) / value(PerformanceSummarySection_stage_6_Trials);

    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_6_TrialsValid.value = value(PerformanceSummarySection_stage_6_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_6_Trials);
    callback(PerformanceSummarySection_stage_6_TrialsToday);
    callback(PerformanceSummarySection_stage_6_ViolationRate);
    callback(PerformanceSummarySection_stage_6_TimeoutRate);
    callback(PerformanceSummarySection_stage_6_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = mean(violation_history);
    SessionPerformanceSection_timeout_percent.value = mean(timeout_history);

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = mean(violation_history(end-19:end));
        SessionPerformanceSection_timeout_recent.value = mean(timeout_history(end-19:end));
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_6_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_6_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_6_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_6_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
    if value(PerformanceSummarySection_stage_6_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
            value(SessionPerformanceSection_violation_recent) < value(TrainingStageParamsSection_recent_violation) && ...
            value(SessionPerformanceSection_timeout_recent) < value(TrainingStageParamsSection_recent_timeout) && ...
            value(SessionPerformanceSection_violation_stage) < value(TrainingStageParamsSection_stage_violation) && ...
            n_done_trials > 100
        ParamsSection_training_stage.value = stage_no + 1;
        callback(ParamsSection_training_stage);
        ParamsSection(obj, 'Changed_Training_Stage');
        SessionDefinition(obj, 'jump_to_stage', 'Variable Stimuli Go Cue location during Centre Poke');
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
% Read all timing parameters from TrainingStageParamsSection
cp_max          = value(TrainingStageParamsSection_max_CP);
starting_cp     = value(TrainingStageParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
n_trial_warmup  = value(TrainingStageParamsSection_warm_up_trials);
prestim_min     = value(TrainingStageParamsSection_min_prestim);
prestim_max     = value(TrainingStageParamsSection_max_prestim);
% FIX: was value(TrainingStageParamsSection_stim_dur + 0.1) — invalid value() call
a1_time         = value(TrainingStageParamsSection_stim_dur);
a1_time_min     = value(TrainingStageParamsSection_stim_dur);
a1_time_max     = value(TrainingStageParamsSection_stim_dur) + 0.1;
prego_min       = value(TrainingStageParamsSection_min_prego);
prego_max       = value(TrainingStageParamsSection_max_prego);
settling_in     = value(ParamsSection_SettlingIn_time);
init_CP_duration = value(ParamsSection_init_CP_duration);
min_prego_buffer = 0.05;

% Randomisation flags
warmup_completed = 0;
warm_up_on    = 1;
random_prestim = 1;
random_prego  = 1;
random_A1     = 0;  % A1 duration is fixed, only its location varies

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
end

% --- CP warmup ramp ---
if warm_up_on == 1
    if n_done_trials == 0
        ParamsSection_CP_duration.value = init_CP_duration;
        warmup_completed = 0;
    elseif n_done_trials == 1
        ParamsSection_CP_duration.value = starting_cp;
    else
        if value(ParamsSection_CP_duration) < cp_max
            if ~violation_history(end) && ~timeout_history(end)
                increment = (cp_max - init_CP_duration) / (n_trial_warmup - 1);
                ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
                ParamsSection_CP_duration.value = max(value(ParamsSection_CP_duration), starting_cp);
                if value(ParamsSection_CP_duration) >= cp_max
                    ParamsSection_CP_duration.value = cp_max;
                    warmup_completed = 1;
                end
            end
        else
            warmup_completed = 1;
        end
    end
else
    warmup_completed = 1;
end

% --- Timing sub-components via param_time_within_range ---
% CP is recalculated from the drawn components so that it exactly equals
% SettlingIn + PreStim + A1 + prego (trial length genuinely varies).
if n_done_trials >= 1
    cp_available = value(ParamsSection_CP_duration) - settling_in;

    [prestim, A1, prego] = param_time_within_range(warmup_completed, ...
        cp_available, ...
        prestim_min, prestim_max, random_prestim, value(TrainingStageParamsSection_min_prestim), ...
        a1_time_min, a1_time_max, random_A1, a1_time, ...
        prego_min, prego_max, random_prego, value(TrainingStageParamsSection_min_prego));

    % Safety clamp: ensure nothing is negative
    prestim = max(prestim, 0);
    A1      = max(A1, 0);
    prego   = max(prego, min_prego_buffer);

    % Recompute CP to be exactly consistent with drawn components
    ParamsSection_PreStim_time.value            = prestim;
    ParamsSection_A1_time.value                 = A1;
    ParamsSection_time_bet_aud1_gocue.value     = prego;
    ParamsSection_CP_duration.value             = settling_in + prestim + A1 + prego;

    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
end
callback(ParamsSection_CP_duration);

% Performance section updates
if n_done_trials > 0
    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    PerformanceSummarySection_stage_7_Trials.value = value(PerformanceSummarySection_stage_7_Trials) + 1;
    PerformanceSummarySection_stage_7_TrialsToday.value = value(PerformanceSummarySection_stage_7_TrialsToday) + 1;
    PerformanceSummarySection_stage_7_ViolationRate.value = ...
        ((value(PerformanceSummarySection_stage_7_ViolationRate) * (value(PerformanceSummarySection_stage_7_Trials) - 1)) + double(violation_history(end))) ...
        / value(PerformanceSummarySection_stage_7_Trials);
    PerformanceSummarySection_stage_7_TimeoutRate.value = ...
        ((value(PerformanceSummarySection_stage_7_TimeoutRate) * (value(PerformanceSummarySection_stage_7_Trials) - 1)) + double(timeout_history(end))) ...
        / value(PerformanceSummarySection_stage_7_Trials);
    
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_7_TrialsValid.value = value(PerformanceSummarySection_stage_7_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_7_Trials);
    callback(PerformanceSummarySection_stage_7_TrialsToday);
    callback(PerformanceSummarySection_stage_7_ViolationRate);
    callback(PerformanceSummarySection_stage_7_TimeoutRate);
    callback(PerformanceSummarySection_stage_7_TrialsValid);

    % Session-wide stats
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;

    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_violation_recent.value = nan;
        SessionPerformanceSection_timeout_recent.value = nan;
    end

    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_7_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_7_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_7_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_7_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
% FIX: was missing ParamsSection_use_auto_train guard — stage would
% auto-advance even when the user had manual control enabled.
if ParamsSection_use_auto_train
    stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
    if value(PerformanceSummarySection_stage_7_TrialsValid) > value(TrainingStageParamsSection_total_trials) && ...
            value(SessionPerformanceSection_violation_recent) < value(TrainingStageParamsSection_recent_violation) && ...
            value(SessionPerformanceSection_timeout_recent) < value(TrainingStageParamsSection_recent_timeout) && ...
            value(SessionPerformanceSection_violation_stage) < value(TrainingStageParamsSection_stage_violation)
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
% FIX: All warmup envelope parameters now read from TrainingStageParamsSection
% case 8 (no hardcoded values). Timing sub-components read from ParamsSection
% user knobs, exactly as before — this stage is fully user-controlled.
cp_max          = value(TrainingStageParamsSection_max_CP);
n_trial_warmup  = value(TrainingStageParamsSection_warm_up_trials);
starting_cp     = value(TrainingStageParamsSection_starting_CP) + value(ParamsSection_SettlingIn_time);
settling_in     = value(ParamsSection_SettlingIn_time);
min_prego_buffer = 0.05;

% All timing sub-component parameters come from user-editable ParamsSection knobs
warm_up_on      = value(ParamsSection_warmup_on);
random_prestim  = value(ParamsSection_random_PreStim_time);
random_prego    = value(ParamsSection_random_prego_time);
random_A1       = value(ParamsSection_random_A1_time);
prestim_min     = value(ParamsSection_PreStim_time_Min);
prestim_max     = value(ParamsSection_PreStim_time_Max);
prestim_time    = value(ParamsSection_PreStim_time);
prego_min       = value(ParamsSection_time_bet_aud1_gocue_Min);
prego_max       = value(ParamsSection_time_bet_aud1_gocue_Max);
prego_time      = value(ParamsSection_time_bet_aud1_gocue);
a1_time         = value(ParamsSection_A1_time);
a1_time_min     = value(ParamsSection_A1_time_Min);
a1_time_max     = value(ParamsSection_A1_time_Max);

stage_no = value(SessionDefinition_CURRENT_ACTIVE_STAGE);
if stage_no ~= value(ParamsSection_training_stage)
    ParamsSection_training_stage.value = stage_no;
    callback(ParamsSection_training_stage);
    ParamsSection(obj, 'Changed_Training_Stage');
end

% --- Optional warmup ramp at session open ---
warmup_completed = 0;
if warm_up_on == 1
    if n_done_trials == 0
        ParamsSection_CP_duration.value = value(ParamsSection_init_CP_duration);
        warmup_completed = 0;
    elseif n_done_trials == 1
        ParamsSection_CP_duration.value = starting_cp;
    else
        if value(ParamsSection_CP_duration) < cp_max
            if ~violation_history(end) && ~timeout_history(end)
                increment = (cp_max - value(ParamsSection_init_CP_duration)) / (n_trial_warmup - 1);
                ParamsSection_CP_duration.value = value(ParamsSection_CP_duration) + increment;
                ParamsSection_CP_duration.value = max(value(ParamsSection_CP_duration), starting_cp);
                if value(ParamsSection_CP_duration) >= cp_max
                    ParamsSection_CP_duration.value = cp_max;
                    warmup_completed = 1;
                end
            end
        else
            warmup_completed = 1;
        end
    end
else
    warmup_completed = 1;
end

% --- Timing sub-components via param_time_within_range ---
if n_done_trials >= 1
    cp_available = value(ParamsSection_CP_duration) - settling_in;

    [prestim, A1, prego] = param_time_within_range(warmup_completed, ...
        cp_available, ...
        prestim_min, prestim_max, random_prestim, prestim_time, ...
        a1_time_min, a1_time_max, random_A1, a1_time, ...
        prego_min, prego_max, random_prego, prego_time);

    % Safety clamp: nothing negative, prego has a floor
    prestim = max(prestim, 0);
    A1      = max(A1, 0);
    prego   = max(prego, min_prego_buffer);

    ParamsSection_PreStim_time.value            = prestim;
    ParamsSection_A1_time.value                 = A1;
    ParamsSection_time_bet_aud1_gocue.value     = prego;
    % Recompute CP to be exactly consistent with drawn components
    ParamsSection_CP_duration.value             = settling_in + prestim + A1 + prego;

    callback(ParamsSection_PreStim_time);
    callback(ParamsSection_A1_time);
    callback(ParamsSection_time_bet_aud1_gocue);
end
callback(ParamsSection_CP_duration);

if n_done_trials > 0

    if n_done_trials == 1
        for k = 1:8
            eval(sprintf('PerformanceSummarySection_stage_%d_TrialsToday.value = 0;', k));
            eval(sprintf('callback(PerformanceSummarySection_stage_%d_TrialsToday);', k));
        end
    end

    % Updating Disp Values for Training_Peformance_Summary
    PerformanceSummarySection_stage_8_Trials.value = value(PerformanceSummarySection_stage_8_Trials) + 1;
    PerformanceSummarySection_stage_8_TrialsToday.value = value(PerformanceSummarySection_stage_8_TrialsToday) + 1;
    PerformanceSummarySection_stage_8_ViolationRate.value = ((value(PerformanceSummarySection_stage_8_ViolationRate) * (value(PerformanceSummarySection_stage_8_Trials) - 1)) + double(violation_history(end))) / value(PerformanceSummarySection_stage_8_Trials);
    PerformanceSummarySection_stage_8_TimeoutRate.value = ((value(PerformanceSummarySection_stage_8_TimeoutRate) * (value(PerformanceSummarySection_stage_8_Trials) - 1)) + double(timeout_history(end))) / value(PerformanceSummarySection_stage_8_Trials);
    if ~isnan(hit_history(end))
        PerformanceSummarySection_stage_8_TrialsValid.value = value(PerformanceSummarySection_stage_8_TrialsValid) + 1;
    end

    callback(PerformanceSummarySection_stage_8_Trials);
    callback(PerformanceSummarySection_stage_8_TrialsToday);
    callback(PerformanceSummarySection_stage_8_ViolationRate);
    callback(PerformanceSummarySection_stage_8_TimeoutRate);
    callback(PerformanceSummarySection_stage_8_TrialsValid);
  
    % Updating Disp Values for SessionPerformanceSection
    SessionPerformanceSection_ntrials.value = n_done_trials;
    SessionPerformanceSection_violation_percent.value = numel(find(violation_history)) / n_done_trials;
    SessionPerformanceSection_timeout_percent.value = numel(find(timeout_history)) / n_done_trials;
    if n_done_trials >= 20
        SessionPerformanceSection_violation_recent.value = numel(find(violation_history(end-19:end))) / 20;
        SessionPerformanceSection_timeout_recent.value = numel(find(timeout_history(end-19:end))) / 20;
    else
        SessionPerformanceSection_timeout_recent.value = nan;
        SessionPerformanceSection_violation_recent.value = nan;
    end
    SessionPerformanceSection_violation_stage.value = value(PerformanceSummarySection_stage_8_ViolationRate);
    SessionPerformanceSection_ntrials_stage.value = value(PerformanceSummarySection_stage_8_Trials);
    SessionPerformanceSection_ntrials_stage_today.value = value(PerformanceSummarySection_stage_8_TrialsToday);
    SessionPerformanceSection_timeout_stage.value = value(PerformanceSummarySection_stage_8_TimeoutRate);

    callback(SessionPerformanceSection_ntrials);
    callback(SessionPerformanceSection_ntrials_stage);
    callback(SessionPerformanceSection_ntrials_stage_today);
    callback(SessionPerformanceSection_violation_percent);
    callback(SessionPerformanceSection_timeout_percent);
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
% No auto-completion for User Setting stage (intentional)
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

    
end

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%<HELPER_FUNCTIONS>

function [prestim, A1, prego] = param_time_within_range(not_fixed_length, cp_length, ...
    range_min_prestim, range_max_prestim, is_random_prestim, provided_time_prestim, ...
    range_min_A1, range_max_A1, is_random_A1, provided_time_A1, ...
    range_min_prego, range_max_prego, is_random_prego, provided_time_prego)
%PARAM_TIME_WITHIN_RANGE  Draw prestim / A1 / prego times that fit inside cp_length.
%
%   The hard constraint is:  prestim + A1 + prego == cp_length
%   with each component >= its minimum.  prego is always computed last
%   as the remainder so the three values always sum correctly and are
%   never negative.
%
%   not_fixed_length == 0  →  warmup phase (CP is still short and growing)
%   not_fixed_length == 1  →  steady-state phase (full user-specified ranges)

MIN_COMPONENT = 0.01;   % absolute floor for any single component (s)
MIN_PREGO     = 0.05;   % safety buffer before go-cue (s)

if not_fixed_length == 0
    % ---- Warmup: CP is short; use conservative proportional values ----
    if cp_length <= 0.3
        prestim = MIN_COMPONENT;
        A1      = MIN_COMPONENT;
        prego   = max(cp_length - prestim - A1, MIN_PREGO);
        % If even that is too tight, compress prestim and A1 equally
        if prego < MIN_PREGO
            share   = (cp_length - MIN_PREGO) / 2;
            prestim = max(share, 0);
            A1      = max(share, 0);
            prego   = MIN_PREGO;
        end
    else
        range_size = round(0.3 * cp_length, 1);
        step_size  = 0.01 + 0.09 * (range_size > 0.4);  % 0.01 or 0.1
        timerange  = MIN_COMPONENT : step_size : range_size;
        if isempty(timerange); timerange = MIN_COMPONENT; end

        if is_random_prestim
            prestim = timerange(randi([1, numel(timerange)], 1, 1));
        else
            prestim = min(provided_time_prestim, range_size);
            prestim = max(prestim, MIN_COMPONENT);
        end

        if is_random_A1
            A1 = timerange(randi([1, numel(timerange)], 1, 1));
        else
            A1 = min(provided_time_A1, range_size);
            A1 = max(A1, MIN_COMPONENT);
        end

        % FIX: prego is the remainder; clamp so it never goes negative
        prego = cp_length - prestim - A1;
        if prego < MIN_PREGO
            % Trim prestim first, then A1, to recover the headroom
            deficit = MIN_PREGO - prego;
            trim    = min(prestim - MIN_COMPONENT, deficit);
            prestim = prestim - trim;
            deficit = deficit - trim;
            if deficit > 0
                trim = min(A1 - MIN_COMPONENT, deficit);
                A1   = A1 - trim;
            end
            prego = max(cp_length - prestim - A1, MIN_PREGO);
        end
    end

else
    % ---- Steady-state: draw from full user-specified ranges ----

    if is_random_prestim
        step  = 0.01 + 0.09 * ((range_max_prestim - range_min_prestim) > 0.4);
        trange = range_min_prestim : step : range_max_prestim;
        if isempty(trange); trange = range_min_prestim; end
        prestim = trange(randi([1, numel(trange)], 1, 1));
    else
        prestim = provided_time_prestim;
    end
    prestim = max(prestim, MIN_COMPONENT);

    if is_random_A1
        step  = 0.01 + 0.09 * ((range_max_A1 - range_min_A1) > 0.4);
        trange = range_min_A1 : step : range_max_A1;
        if isempty(trange); trange = range_min_A1; end
        A1 = trange(randi([1, numel(trange)], 1, 1));
    else
        A1 = provided_time_A1;
    end
    A1 = max(A1, MIN_COMPONENT);

    if is_random_prego
        step  = 0.01 + 0.09 * ((range_max_prego - range_min_prego) > 0.4);
        trange = range_min_prego : step : range_max_prego;
        if isempty(trange); trange = range_min_prego; end
        prego = trange(randi([1, numel(trange)], 1, 1));
    else
        prego = provided_time_prego;
    end
    prego = max(prego, MIN_PREGO);

    % FIX: if the drawn combination exceeds cp_length, trim prego first,
    % then prestim, so the mandatory A1 duration is always preserved.
    total = prestim + A1 + prego;
    if total > cp_length
        prego   = max(cp_length - prestim - A1, MIN_PREGO);
        total   = prestim + A1 + prego;
        if total > cp_length
            prestim = max(cp_length - A1 - prego, MIN_COMPONENT);
        end
    end
end

end


%</HELPER_FUNCTIONS>

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
