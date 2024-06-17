% Create and send state matrix.
%
% Santiago Jaramillo - 2007.08.24
%
%%% CVS version control block - do not edit manually
%%%  $Revision: 1064 $
%%%  $Date: 2008-01-10 16:50:50 -0500 (Thu, 10 Jan 2008) $
%%%  $Source$


%%% BUGS:
%
% [2007.10.04] If the duration of sound is changed, the State Matrix is not
% updated but the sound duration is.  This is a problem if Duration is changed
% from large value to a small one, since there will still be punishment after
% the sound off-set.  Updating the matrix on update_sounds didn't work.


function sma = StateMatrixSection(obj, action)

GetSoloFunctionArgs;
%%% Imported objects (see protocol constructor):
%%%  'PunishExtraTime'
%%%  'PreStimMean'
%%%  'PreStimRange'
%%%  'RewardAvail'
%%%  'WaterDelivery' (from SidesSection.m)
%%%  'RelevantSide'  (from SidesSection.m)
%%%  'EarlyWithdrawal'
%%%  'ProbingContextTrialsList'
%%%  'RewardSideList'
%%%  'DistractorList'
%%%  'TargetDuration' (from SoundsSection.m)
%%%  'ProbeDuration' (from SoundsSection.m)
%%%  'SimulationMode'


global left1water;
global right1water;

switch action
  case 'update',
% -- Variables for stimuli and states changes --
NextRewardSide = RewardSideList(n_done_trials);
%NextDistractorType = DistractorList(n_done_trials);
ProbingContext = ProbingContextTrialsList(n_done_trials);
%%% Shouldn't it be n_done_trials+1 ?  sjara 2007.08.14

TargetDurationLocal = value(TargetDuration);                  % seconds
ProbeDurationLocal = value(ProbeDuration);                  % seconds

%ValveDuration = 0.15;               % seconds
[ValveDurationL,ValveDurationR] = WaterValvesSection(obj,'get_water_times');

%%% Random delay = PreStimMean +/- PreStimRange/2 %%%
RandDelay = (value(PreStimRange))*(rand(1)-0.5) + value(PreStimMean);          % Random delay before first stim. 

IndPunishNoise = SoundManagerSection(obj, 'get_sound_id', 'PunishNoise');

IndProbeSound = SoundManagerSection(obj, 'get_sound_id', 'ProbeSound');

IndSoundL1 = SoundManagerSection(obj, 'get_sound_id', 'L1');
IndSoundL2 = SoundManagerSection(obj, 'get_sound_id', 'L2');
IndSoundR1 = SoundManagerSection(obj, 'get_sound_id', 'R1');
IndSoundR2 = SoundManagerSection(obj, 'get_sound_id', 'R2');

if(NextRewardSide=='l')
    CorrectPort = 'Lin';
    WrongPort = 'Rin';
    RewardValve = left1water;       % *** Reward on LEFT ***
    ValveDuration = ValveDurationL;
    if(strcmp(value(RelevantSide),'left'))  % -- CONTEXT 1 (called left) --
        IndTargetThisTrial = IndSoundL1;
        if(~ProbingContext)     % Valid context
            %IndTargetThisTrial = IndSoundL1;
            GroupOfTarget = 2;
        else                    % Invalid context
            %IndTargetThisTrial = IndSoundR1;               
            GroupOfTarget = 1;
        end
    else                                    % -- CONTEXT 2 (called right) --
        IndTargetThisTrial = IndSoundL1; %%%% HIGH FREQ %%%%              
        if(~ProbingContext)     % Valid context
            %IndTargetThisTrial = IndSoundR1;               
            GroupOfTarget = 1;
        else                    % Invalid context
            %IndTargetThisTrial = IndSoundL1;
            GroupOfTarget = 2;
        end
    end
else
    CorrectPort = 'Rin';
    WrongPort = 'Lin';
    RewardValve = right1water;      % *** Reward on RIGHT ***
    ValveDuration = ValveDurationR;
    if(strcmp(value(RelevantSide),'left'))  % -- CONTEXT 1 (called left) --
        IndTargetThisTrial = IndSoundR2; %%%% LOW FREQ %%%%               
        if(~ProbingContext)     % Valid context
            %IndTargetThisTrial = IndSoundL2;               
            GroupOfTarget = 2;
        else                    % Invalid context
            %IndTargetThisTrial = IndSoundR2;
            GroupOfTarget = 1;
        end 
    else                                    % -- CONTEXT 2 (called right) --
        IndTargetThisTrial = IndSoundR2; %%%% HIGH FREQ %%%%      
        if(~ProbingContext)     % Valid context
            %IndTargetThisTrial = IndSoundR2;
            GroupOfTarget = 1;
        else                    % Invalid context
            %IndTargetThisTrial = IndSoundL2;               
            GroupOfTarget = 2;
        end
    end
end

% -- Send sound for this trial --
[TargetOnset,StimulusDuration] = SoundsSection(obj, 'update_sound_this_trial',...
                                               IndTargetThisTrial,GroupOfTarget);



sma = StateMachineAssembler('full_trial_structure');

% ------------------------------ Simulation Mode -----------------------------
if(strcmp(value(SimulationMode),'on'))
    sma = add_state(sma, 'name', 'wait_for_cpoke', ...
                    'self_timer', 0.2,...
                    'input_to_statechange', {'Tup', 'pre_cue'});
    sma = add_state(sma, 'name', 'pre_cue', ...
                    'self_timer', RandDelay,...
                    'input_to_statechange', {'Tup', 'play_probe'});
    sma = add_state(sma, 'name', 'play_probe', ...
                    'self_timer', TargetOnset,...
                    'input_to_statechange', {'Tup', 'play_cue'},...
                    'output_actions', {'SoundOut', IndProbeSound});
    sma = add_state(sma, 'name', 'play_cue', ...
                    'self_timer', TargetDurationLocal,...
                    'input_to_statechange', {'Tup', 'posttarget_probe'},...
                    'output_actions', {'SoundOut', IndTargetThisTrial});
    sma = add_state(sma, 'name', 'posttarget_probe', ...
                    'self_timer', StimulusDuration-TargetOnset-TargetDurationLocal,...
                    'input_to_statechange', {'Tup', 'wait_for_apoke', 'Cout', 'stop_probe'});
    sma = add_state(sma, 'name', 'stop_probe', ...
                    'self_timer', 0.0001,...
                    'input_to_statechange', {'Tup', 'wait_for_apoke'},...
                    'output_actions', {'SoundOut', -IndProbeSound});
    sma = add_state(sma, 'name', 'wait_for_apoke', ...
                    'self_timer', 1*rand(1)+0.5,...
                    'input_to_statechange', {'Tup', 'correcttrial'});
else
% ------------------------------ Normal Mode -----------------------------


sma = add_state(sma, 'name', 'wait_for_cpoke', ...
                'input_to_statechange', {'Cin', 'pre_cue'},...
                'output_actions',{'SoundOut',-IndPunishNoise});

sma = add_state(sma, 'name', 'pre_cue', ...
                'self_timer', RandDelay,...
                'input_to_statechange', {'Cout','wait_for_cpoke','Tup', 'play_probe'});

% -- If DIRECT delivery --
if strcmpi(value(WaterDelivery), 'direct')
    sma = add_state(sma, 'name', 'play_probe', ...
                        'self_timer', 0.001,...
                        'input_to_statechange', {'Tup', 'play_cue'});
    sma = add_state(sma, 'name', 'play_cue', ...
                'self_timer', TargetDurationLocal,...
                'input_to_statechange', {'Tup', 'directtrial'},...
                'output_actions', {'SoundOut', IndTargetThisTrial});
% -- Otherwise wait for answer poke --
else
    if(strcmp(value(EarlyWithdrawal),'punish'))
        %sma = add_scheduled_wave(sma, 'name', 'DelayToTarget', 'preamble', TargetOnset);
        sma = add_state(sma, 'name', 'play_probe', ...
                        'self_timer', TargetOnset+0.0001,...
                        'input_to_statechange', ...
                        {'Tup', 'play_cue', 'Cout', 'stop_probe_and_punish'},...
                        'output_actions', {'SoundOut', IndProbeSound});
        sma = add_state(sma, 'name', 'play_cue', ...
                        'self_timer', TargetDurationLocal,...
                        'input_to_statechange', {'Tup','posttarget_probe','Cout', 'stop_cue'},...
                        'output_actions', {'SoundOut', IndTargetThisTrial});
        sma = add_state(sma, 'name', 'stop_cue', ...
                        'self_timer', 0.0001,...
                        'input_to_statechange', {'Tup', 'stop_probe'},...
                        'output_actions', {'SoundOut', -IndTargetThisTrial});
        
        sma = add_state(sma, 'name', 'stop_probe', ...
                        'self_timer', 0.0001,...
                        'input_to_statechange', {'Tup', 'wait_for_apoke'},...
                        'output_actions', {'SoundOut', -IndProbeSound});

        sma = add_state(sma, 'name', 'posttarget_probe', ...
                        'self_timer', StimulusDuration-TargetOnset-TargetDurationLocal,...
                        'input_to_statechange', {'Tup', 'wait_for_apoke', 'Cout', 'stop_probe'});
        
        sma = add_state(sma, 'name', 'stop_probe_and_punish', ...
                        'self_timer', 0.0001,...
                        'input_to_statechange', {'Tup', 'WithdrawalPunish'},...
                        'output_actions', {'SoundOut', -IndProbeSound});
    
    
        %        sma = add_state(sma, 'name', 'play_probe', ...
        %                 'self_timer', TargetOnset,...
        %                 'input_to_statechange', {'Tup', 'play_cue', 'Cout', 'stop_cue'},...
        %                 'output_actions', {'SoundOut', IndSoundThisTrial});
        % sma = add_state(sma, 'name', 'play_cue', ...
        %                 'input_to_statechange', {'Cout', 'wait_for_apoke'});
        % sma = add_state(sma, 'name', 'stop_cue', ...
        %                 'self_timer', 0.005,...
        %                 'input_to_statechange', {'Tup', 'WithdrawalPunish'},...
        %                 'output_actions', {'SoundOut', -IndSoundThisTrial});
      
    else
        % NOTES:
        % - No probe on these type of trials.
        % - Wait for side-poke only after finishing playing the cue.
        sma = add_state(sma, 'name', 'play_probe', ...
                        'self_timer', 0.005,...
                        'input_to_statechange', {'Tup', 'play_cue'});
        sma = add_state(sma, 'name', 'play_cue', ...
                        'self_timer', TargetDurationLocal,...
                        'input_to_statechange', {'Tup', 'wait_for_apoke'},...
                        'output_actions', {'SoundOut', IndSoundThisTrial});
    end
end


% -- If NEXT CORRECT POKE (stay in this state when miss) --
if strcmpi(value(WaterDelivery), 'next corr poke')
sma = add_state(sma, 'name', 'wait_for_apoke', ...
                'self_timer', value(RewardAvail),...
                'input_to_statechange', ...
                {CorrectPort, 'hittrial',WrongPort, 'misstrial',...
                 'Tup', 'timeouttrial'});
% -- If ONLY WHEN CORRECT POKE (end trial if miss) --
else
sma = add_state(sma, 'name', 'wait_for_apoke', ...
                'self_timer', value(RewardAvail),...
                'input_to_statechange', ...
                {CorrectPort, 'correcttrial',WrongPort, 'errortrial','Tup', 'timeouttrial'});
end

end
% --------------------------- END of simulation vs. normal mode --------------------------



sma = add_state(sma, 'name', 'directtrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'hittrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'misstrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'wait_for_apoke'});
sma = add_state(sma, 'name', 'correcttrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'reward'});
sma = add_state(sma, 'name', 'errortrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'punish'});
sma = add_state(sma, 'name', 'timeouttrial', ...
                'self_timer', 0.001,...
                'input_to_statechange', {'Tup', 'final_state'});


sma = add_state(sma, 'name', 'reward', ...
                'self_timer', ValveDuration,...
                'input_to_statechange', {'Tup', 'final_state'},...
                'output_actions', {'DOut', RewardValve});

sma = add_state(sma, 'name', 'WithdrawalPunish', ...
                'self_timer', 0.2,...
                'input_to_statechange', {'Tup', 'wait_for_cpoke'},...
                'output_actions', {'SoundOut', IndPunishNoise});

%%%% Time of sound is hardcoded here and in SoundsSection.m %%%%
sma = add_state(sma, 'name', 'punish', ...
                'self_timer', 0.05,...
                'input_to_statechange', {'Tup', 'extratime'},...
                'output_actions', {'SoundOut', IndPunishNoise});
%%%% ExtraTime is hardcoded here %%%%
sma = add_state(sma, 'name', 'extratime', ...
                'self_timer', value(PunishExtraTime),...
                'input_to_statechange', {'Tup', 'final_state'});

sma = add_state(sma, 'name', 'final_state', ...
                'self_timer', 0.01, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
dispatcher('send_assembler', sma, 'final_state');


end %%% SWITCH action
