% Create and send state matrix.
%
% Santiago Jaramillo - 2008.04.27
%
%%% CVS version control block - do not edit manually
%%%  $Revision: 1489 $
%%%  $Date: 2008-07-28 14:57:22 -0400 (Mon, 28 Jul 2008) $
%%%  $Source$

function sma = StateMatrixSection(obj, action)

GetSoloFunctionArgs;
%%% Imported objects (see protocol constructor):
%%%  'ExtraTimeForError'
%%%  'PreStimTime'
%%%  'PreStimMean'
%%%  'PreStimHalfRange'
%%%  'RewardAvail'
%%%  'WaterDelivery' (modified by SidesSection.m)
%%%  'CurrentBlock'  (modified by SidesSection.m )
%%%  'EarlyWithdrawal'
%%%  'ExtraTimeForEarlyWithdrawal'
%%%  'CatchTrialsList'
%%%  'RewardSideList'
%%%  'SimulationMode'
%%%  'TargetDuration'
%%%  'StimulusDuration'
%%%  'DelayToTarget'
%%%  'CueToTargetDelay'
%%%  'CueDuration'
%%%  'CueMode'
%%%  'CueProb'
%%%  'TargetModIndex'
%%%  'CuedTrialsList'
%%%  'PsychCurveMode'

%%%  %%  'TargetDuration' (from SoundsSection.m)
%%%  %% 'ProbebDuration' (from SoundsSection.m)


%%% PARAMETERS NEEDED %%%
% PunishSoundDuration   **

global left1water;
global right1water;
global center1led;

switch action
case 'update',

% -- Variables for stimuli and states changes --
MinTimeInState = 0.0001;
NextRewardSide = RewardSideList.values(n_done_trials+1); % 1 (left) or 2 (right)
CatchTrial     = CatchTrialsList(n_done_trials+1)==1;
  
% -- Sound parameters --
IndPunishNoise = SoundManagerSection(obj, 'get_sound_id', 'PunishNoise');

%IndStimulusSound = SoundManagerSection(obj, 'get_sound_id', 'StimulusSound');
IndDistractorsSound = SoundManagerSection(obj, 'get_sound_id', 'DistractorsSound');
IndTargetSound = SoundManagerSection(obj, 'get_sound_id', 'TargetSound');

% -- Reward parameters --
[ValveDurationL,ValveDurationR] = WaterValvesSection(obj,'get_water_times');

% -- Set delay to target according to current block --
if(strcmp(value(CurrentBlock),'rand-delay'))
    PossibleDelayToTarget = ([3:10]-1)*0.150;
    RandIndex = ceil(length(PossibleDelayToTarget)*rand(1));
    DelayToTarget.value_callback = PossibleDelayToTarget(RandIndex); % sec
elseif(strcmp(value(CurrentBlock),'target-left') | strcmp(value(CurrentBlock),'target-right'))
    PossibleDelayToTarget = ([3:7]-1)*0.150;
    RandIndex = ceil(length(PossibleDelayToTarget)*rand(1));
    % -- For catch trials, fix target position --
    if(CatchTrial)
        RandIndex = 2; % Choose second of possible delays
    end
    DelayToTarget.value_callback = PossibleDelayToTarget(RandIndex); % sec
elseif(strcmp(value(CurrentBlock),'short-delay')&~CatchTrial | ...
       strcmp(value(CurrentBlock),'long-delay') & CatchTrial)
    if(strcmp(value(RecMode),'off'))
       PossibleDelayToTarget = [0.300, 0.450];
    else
       PossibleDelayToTarget = [0.450];
    end
    RandIndex = ceil(length(PossibleDelayToTarget)*rand(1));
    DelayToTarget.value_callback = PossibleDelayToTarget(RandIndex); % sec
elseif(strcmp(value(CurrentBlock),'long-delay')&~CatchTrial | ...
       strcmp(value(CurrentBlock),'short-delay') & CatchTrial)
    if(strcmp(value(RecMode),'off'))
       PossibleDelayToTarget = [1.350, 1.500];
    else
       PossibleDelayToTarget = [1.500];
    end
    RandIndex = ceil(length(PossibleDelayToTarget)*rand(1));
    DelayToTarget.value_callback = PossibleDelayToTarget(RandIndex); % sec
end

% -- Decide if next will be is a cued trial ---
CueNextTrial = rand(1)<value(CueProb);
CuedTrialsList(n_done_trials+1) = CueNextTrial;
% -- Randomize cue to target delay --
%if(CueNextTrial)
%    RandomCuePos = floor(2*rand(1)+1);
%    CueToTargetDelay.value_callback = RandomCuePos*0.150; % sec
%end

% -- Decide spatial source of the target --
%if(strcmp(value(CurrentBlock),'target-left') & ~CatchTrial | ...
%   strcmp(value(CurrentBlock),'target-right') & CatchTrial) 
%    TargetSource.value_callback = 'left';
%elseif(strcmp(value(CurrentBlock),'target-right') & ~CatchTrial | ...
%   strcmp(value(CurrentBlock),'target-left') & CatchTrial) 
%    TargetSource.value_callback = 'right';
%end


% -- Time parameters --
%RandDelayToStim = PreStimMin + (PreStimMax-PreStimMin)*rand(1);
RandDelayToStim = value(PreStimMean) + value(PreStimHalfRange)*(2*rand(1)-1);
PreStimTime(n_done_trials+1) = RandDelayToStim;

% -- Define next trial reward side --
if(NextRewardSide==RewardSideList.labels.left)
    CorrectPort = 'Lin';
    WrongPort = 'Rin';
    RewardValve = left1water;       % *** Reward on LEFT ***
    ValveDuration = ValveDurationL;
    TargetSource.value_callback = 'left';
else
    CorrectPort = 'Rin';
    WrongPort = 'Lin';
    RewardValve = right1water;      % *** Reward on RIGHT ***
    ValveDuration = ValveDurationR;
    TargetSource.value_callback = 'right';
end


% -- If psychometric curve mode --
if(strcmp(value(PsychCurveMode),'on'))
    PossibleModIndex = [0.0001,0.001,0.002,0.004,0.008,0.016]; % 6 values
    randval = ceil(length(PossibleModIndex)*rand(1));
    TargetModIndex.value_callback = PossibleModIndex(randval);
end
    


% -- Send sound for this trial --
%[TargetOnset,StimulusDuration] = SoundsSection(obj, 'update_sound_this_trial',...
%                                               IndTargetThisTrial);
SoundsSection(obj, 'update_sound_this_trial', NextRewardSide);




sma = StateMachineAssembler('full_trial_structure');

% ------------------------------ Simulation Mode -----------------------------
if(strcmp(value(SimulationMode),'on'))
    %%% DEFINE SIMULATION MODE %%%


else
% ------------------------------ Normal Mode -----------------------------


sma = add_state(sma, 'name', 'wait_for_cpoke', ...
                'input_to_statechange', {'Cin', 'pre_stim_delay'},...
                'output_actions',{'SoundOut',-IndPunishNoise});

sma = add_state(sma, 'name', 'pre_stim_delay', ...
                'self_timer', RandDelayToStim,...
                'input_to_statechange', {'Cout','early_withdrawal_pre','Tup', 'play_distractors'});
sma = add_state(sma, 'name', 'early_withdrawal_pre', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'wait_for_cpoke'});

% -- If DIRECT delivery --
if strcmpi(value(WaterDelivery), 'direct')
    sma = add_state(sma, 'name', 'play_distractors', ...
                    'self_timer', MinTimeInState,...
                    'input_to_statechange', {'Tup', 'play_target'});
    %sma = add_state(sma, 'name', 'play_distractors', ...
    %                    'self_timer', MinTimeInState,...
    %                    'input_to_statechange', {'Tup', 'play_target'});
    sma = add_state(sma, 'name', 'play_target', ...
                'self_timer', value(TargetDuration),...
                'input_to_statechange', {'Tup', 'direct_trial'},...
                'output_actions', {'SoundOut', IndTargetSound});
% -- Otherwise wait for answer poke --
else
    if(CueNextTrial)
        disp('***************** CUE MODE ON ****************');
        sma = add_scheduled_wave(sma, 'name', 'StartTarget', 'preamble', value(DelayToTarget));
        sma = add_scheduled_wave(sma, 'name', 'StartCue', 'preamble', value(DelayToTarget)-value(CueToTargetDelay));
        sma = add_state(sma, 'name', 'play_distractors', ...
                        'self_timer', MinTimeInState,...
                        'input_to_statechange', ...
                        {'Tup', 'start_sched_cue', 'Cout', 'stop_distractors_and_punish'},...
                        'output_actions', ...
                        {'SchedWaveTrig', 'StartTarget','SoundOut', IndDistractorsSound});
        sma = add_state(sma, 'name', 'start_sched_cue', ...
                        'self_timer', MinTimeInState,...
                        'input_to_statechange', ...
                        {'Tup', 'continue_distractors', 'Cout', 'stop_distractors_and_punish'},...
                        'output_actions', ...
                        {'SchedWaveTrig', 'StartCue'});
        sma = add_state(sma, 'name', 'continue_distractors', ...
                        'self_timer', value(DelayToTarget),...
                        'input_to_statechange', ...
                        {'Tup', 'play_target', 'Cout', 'stop_distractors_and_punish',...
                         'StartTarget_In','play_target','StartCue_In','show_cue'},...
                        'output_actions', {'DOut', 0});
        sma = add_state(sma, 'name', 'show_cue', ...
                        'self_timer', value(CueDuration),...
                        'input_to_statechange', ...
                        {'Tup', 'continue_distractors', 'Cout', 'stop_distractors_and_punish',...
                         'StartTarget_In','play_target'},...
                        'output_actions', {'DOut', center1led});
    else
        sma = add_scheduled_wave(sma, 'name', 'StartTarget', 'preamble', value(DelayToTarget));
        sma = add_state(sma, 'name', 'play_distractors', ...
                        'self_timer', MinTimeInState,...
                        'input_to_statechange', ...
                        {'Tup', 'continue_distractors', 'Cout', 'stop_distractors_and_punish'},...
                        'output_actions', ...
                        {'SchedWaveTrig', 'StartTarget','SoundOut', IndDistractorsSound});
        sma = add_state(sma, 'name', 'continue_distractors', ...
                        'self_timer', value(DelayToTarget),...
                        'input_to_statechange', ...
                        {'Tup', 'play_target', 'Cout', 'stop_distractors_and_punish',...
                         'StartTarget_In','play_target'});
    end
    sma = add_state(sma, 'name', 'play_target', ...
                    'self_timer', value(TargetDuration),...
                    'input_to_statechange', {'Tup','posttarget_distractors','Cout', 'stop_distractors_and_punish'},...
                    'output_actions', {'SoundOut', IndTargetSound,'DOut', 0});
    PostTargetDuration = value(StimulusDuration)-value(DelayToTarget)-value(TargetDuration);
    %sma = add_state(sma, 'name', 'posttarget_distractors', ...
    %                'self_timer', PostTargetDuration,...
    %                'input_to_statechange', {'Tup', 'wait_for_apoke', 'Cout', 'stop_distractors'});
    sma = add_state(sma, 'name', 'posttarget_distractors', ...
                    'self_timer', PostTargetDuration,...
                    'input_to_statechange', {'Tup', 'wait_for_apoke', 'Cout', 'stop_distractors_and_punish'});
    
    sma = add_state(sma, 'name', 'stop_target', ...
                    'self_timer', MinTimeInState,...
                    'input_to_statechange', {'Tup', 'stop_distractors'},...
                    'output_actions', {'SoundOut', -IndTargetSound});
    sma = add_state(sma, 'name', 'stop_distractors', ...
                    'self_timer', MinTimeInState,...
                    'input_to_statechange', {'Tup', 'wait_for_apoke'},...
                    'output_actions', {'SoundOut', -IndDistractorsSound});

    sma = add_state(sma, 'name', 'stop_distractors_and_punish', ...
                    'self_timer', MinTimeInState,...
                    'input_to_statechange', {'Tup', 'withdrawal_punish'},...
                    'output_actions', {'SoundOut', -IndDistractorsSound,'DOut', 0});
    
end %%% END if DIRECT

% -- If NEXT CORRECT POKE (stay in this state when mistake) --
if strcmpi(value(WaterDelivery), 'next corr poke')
    sma = add_state(sma, 'name', 'wait_for_apoke', ...
                    'self_timer', value(RewardAvail),...
                    'input_to_statechange', ...
                    {CorrectPort, 'correct_trial_nextcorr',WrongPort, 'error_trial_nextcorr',...
                     'Tup', 'timeout_trial'});
% -- If ONLY WHEN CORRECT POKE (end trial if mistake) --
else
    sma = add_state(sma, 'name', 'wait_for_apoke', ...
                    'self_timer', value(RewardAvail),...
                    'input_to_statechange', ...
                    {CorrectPort, 'correct_trial',WrongPort, 'error_trial',...
                     'Tup', 'timeout_trial'});
end %%% END if NEXT CORRECT POKE

end %%% END if SIMULATION_MODE


sma = add_state(sma, 'name', 'direct_trial', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'correct_trial_nextcorr', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'error_trial_nextcorr', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'wait_for_apoke'});
sma = add_state(sma, 'name', 'correct_trial', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'error_trial', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'punish'});
sma = add_state(sma, 'name', 'timeout_trial', ...
                'self_timer', MinTimeInState,...
                'input_to_statechange', {'Tup', 'final_state'});



sma = add_state(sma, 'name', 'reward', ...
                'self_timer', ValveDuration,...
                'input_to_statechange', {'Tup', 'final_state'},...
                'output_actions', {'DOut', RewardValve});

sma = add_state(sma, 'name', 'punish', ...
                'self_timer', value(ExtraTimeForError),...
                'input_to_statechange', {'Tup', 'final_state'},...
                'output_actions', {'SoundOut', IndPunishNoise});

sma = add_state(sma, 'name', 'withdrawal_punish', ...
                'self_timer', value(ExtraTimeForEarlyWithdrawal),...
                'input_to_statechange', {'Tup', 'wait_for_cpoke'},...
                'output_actions', {'SoundOut', IndPunishNoise});

sma = add_state(sma, 'name', 'final_state', ...
                'self_timer', MinTimeInState, 'input_to_statechange',...
                {'Tup', 'check_next_trial_ready'});

%dispatcher('send_assembler', sma, 'check_next_trial_ready');
dispatcher('send_assembler', sma, {'reward','punish','final_state'});


end %%% SWITCH action
