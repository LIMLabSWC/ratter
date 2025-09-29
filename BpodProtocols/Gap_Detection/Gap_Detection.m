%{
---------------------------------------------------------------------------
Gap_Detection.m
MAIN PROTOCOL
2019
Emmett James Thompson
Sainsbury Wellcome Center
---------------------------------------------------------------------------

Training stages:
1.
Init port lights up, poke generates go cue and reward port lights up.
poke into reward port provides reward paired with reward sound.
2.
go cue delay increases by 1% for every correct trial
3.
go cue delay is random and evenly distributed between min and max delay (GUI setting)
4.
BG sound added in, go cue indicates reward
5.
Pause in BG is the new primary go cue (previous go cue is still played
after pause duration)
6.
secondary Go cue is removed
7.
Background Pattern (predictive of pause cue) added


%}

%% Make BpodSystem object
global BpodSystem

%% Resolve AudioPlayer USB port
if (isfield(BpodSystem.ModuleUSB, 'AudioPlayer1'))
    AudioPlayerUSB = BpodSystem.ModuleUSB.AudioPlayer1;
else
    error('Error: To run this protocol, you must first pair the AudioPlayer1 module with its USB port. Click the USB config button on the Bpod console.')
end

%% GUI Params
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    %Task Features
    S.GUI.TrainingLevel = 2; % Default Training Level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.TrainingLevel.String = {'1_Habituation', '2_CueDelay_Increase', '3_Variable_CueDelay', '4_BGSound_Cue_reward', '5_Pause_Cue_Reward' '6_Pause_Reward' '7_Pattern_Pause_Reward'};
    
    S.GUI.BG_NoiseType = 1; % Default Training Level
    S.GUIMeta.BG_NoiseType.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.BG_NoiseType.String = {'1_RedNoise', '2_PinkNoise', '3_VioletNoise', '4_BlueNoise', '5_WhiteNoise'};
    
    
    S.GUI.UsePreviousCueDelay = 0; %default is off
    S.GUIMeta.UsePreviousCueDelay.Style = 'checkbox';
    
    
    S.GUI.RewardAmount = 20; %ul
    S.GUI.RewardDelay = 0; %s
    S.GUI.ResponseWindow = 4; %s
    S.GUI.HabituationResponseWindow = 600; %s
    S.GUI.PunishTimeoutDuration = 5; %s
    
    %Cue/Pause delays:
    S.GUI.InitialCueDelay = 0.5; %s
    S.GUI.MinVariableCueDelay = 2; %s
    S.GUI.MaxVariableCueDelay = 10; %s
    S.GUI.WithdrawlLeniency = 0.2; %s
    
    %Cue/Pause Duration
    S.GUI.PauseDuration= 0.5; %s
    S.GUI.CueDuration = 0.5; % Duration of sound (s)
    S.GUI.PatternDuration = 2; %s
    
    %Sound Feautres
    S.GUI.CueFreq = 8000; %Hz
    S.GUI.BackgroundDuration = 15; % Duration of sound (s)
    S.GUI.Pattern_FreqA = 5000;
    S.GUI.Pattern_FreqB = 15000;
    S.GUI.PatternSegmentDuration = 0.4; %s
    S.GUI.Amplitude = 0.02;
    
    S.GUIPanels.Task = {'TrainingLevel','RewardAmount', 'RewardDelay', 'ResponseWindow', 'HabituationResponseWindow', 'PunishTimeoutDuration'}; % GUIPanels organize the parameters into groups.
    S.GUIPanels.Time = {'UsePreviousCueDelay','InitialCueDelay', 'MinVariableCueDelay', 'MaxVariableCueDelay','PauseDuration','CueDuration','BackgroundDuration', 'WithdrawlLeniency', 'PatternDuration'};
    S.GUIPanels.Sound = {'BG_NoiseType', 'CueFreq', 'PatternSegmentDuration','Pattern_FreqA', 'Pattern_FreqB', 'Amplitude'};
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
set(BpodSystem.ProtocolFigures.ParameterGUI, 'Position', [40 50 450 950]);

% Pause to allow user to change GUI parameters
BpodSystem.Status.Pause=1;
HandlePauseCondition;

S = BpodParameterGUI('sync', S); % Sync S to the changed GUI parameters


%% Define trials
BpodSystem.Data.MaxTrials = 1000;

switch S.GUI.TrainingLevel
    case {1} % Habituation
        CueDelay = linspace(0, 0, BpodSystem.Data.MaxTrials);
        PauseDelay = nan(1,BpodSystem.Data.MaxTrials);
        
    case {2} % CueDelay_Increase
        if S.GUI.UsePreviousCueDelay == 1; %if tick box checked find and use data from previous day
            disp('Please find data from previous day')
            path = uigetdir();
            file = uigetfile(path);
            previousdata = load(strcat(path,'\',file));
            CueDelayInit = previousdata.SessionData.CueDelay(previousdata.SessionData.nTrials);
            CueDelayInit = CueDelayInit * 0.9; % reduce previous day by 10% to get mouse back in the swing of things 
            CueDelay = linspace(CueDelayInit, CueDelayInit,BpodSystem.Data.MaxTrials);
            
        else
            CueDelay = linspace(S.GUI.InitialCueDelay, S.GUI.InitialCueDelay,BpodSystem.Data.MaxTrials);
        end
        PauseDelay = nan(1,BpodSystem.Data.MaxTrials);
    case {3} %Variable_CueDelay
        CueDelay = (S.GUI.MaxVariableCueDelay-S.GUI.MinVariableCueDelay).*rand(BpodSystem.Data.MaxTrials,1) + S.GUI.MinVariableCueDelay;
        PauseDelay = nan(1,BpodSystem.Data.MaxTrials);
    case {4} % BGSound_Cue_reward
        CueDelay = (S.GUI.MaxVariableCueDelay-S.GUI.MinVariableCueDelay).*rand(BpodSystem.Data.MaxTrials,1) + S.GUI.MinVariableCueDelay;
        PauseDelay = nan(1,BpodSystem.Data.MaxTrials);
    case {5} % Pause_Cue_Reward
        PauseDelay = (S.GUI.MaxVariableCueDelay-S.GUI.MinVariableCueDelay).*rand(BpodSystem.Data.MaxTrials,1) + S.GUI.MinVariableCueDelay;
    case {6} % Pause_Reward
        PauseDelay = (S.GUI.MaxVariableCueDelay-S.GUI.MinVariableCueDelay).*rand(BpodSystem.Data.MaxTrials,1) + S.GUI.MinVariableCueDelay;
    case {7} % Pattern_Pause_Reward
        PauseDelay = (S.GUI.MaxVariableCueDelay-S.GUI.MinVariableCueDelay).*rand(BpodSystem.Data.MaxTrials,1) + S.GUI.MinVariableCueDelay;
end

BpodSystem.Data.CueDelay = [];
BpodSystem.Data.PauseDelay = [];

%% Define stimuli and send to analog module

% Create an instance of the audioPlayer module
A = BpodAudioPlayer(AudioPlayerUSB);

SF = A.Info.maxSamplingRate; % Use max supported sampling rate

%Generate Cue reward and pause sounds
CueSound = GenerateSineWave(SF, S.GUI.CueFreq, S.GUI.CueDuration)*S.GUI.Amplitude; % Sampling freq (hz), Sine frequency (hz), duration (s)
%RewardSound = GenerateSineWave(SF, 400, S.GUI.CueDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)

%make new Reward Sound
srate=20000; % sampling rate
freq1=5;
dur1=1.5*1000;
Vol=1;
RewardSound = Vol*(MakeBupperSwoop(srate,0, freq1 , freq1 , dur1/2 , dur1/2,0,0.1));


Pause = zeros(1,1000);

%Generate GUI specified BG noise
switch S.GUI.BG_NoiseType
    case {1 2 3 4}
        BGSound = GenerateNoise(1, SF*S.GUI.BackgroundDuration, S.GUI.BG_NoiseType);
    case {5}
        BGSound = (rand(1,SF*S.GUI.BackgroundDuration)*S.GUI.Amplitude) - 1;
end

%For training stage 7 generate pattern sound
switch S.GUI.TrainingLevel
    case{7}
        %ABAB pattern 5/15kHz
        SoundA = GenerateSineWave(SF, S.GUI.Pattern_FreqA, S.GUI.PatternSegmentDuration)*S.GUI.Amplitude; % Sampling freq (hz), Sine frequency (hz), duration (s)
        SoundB = GenerateSineWave(SF, S.GUI.Pattern_FreqB,  S.GUI.PatternSegmentDuration)*S.GUI.Amplitude; % Sampling freq (hz), Sine frequency (hz), duration (s)
        Pattern = [];
        AmpMod = 0.999;
        for i = 1:round(3/(S.GUI.PatternSegmentDuration*2))
            if i == 1
                Pattern = [(SoundA.*(1-AmpMod)),(SoundB.*(1-AmpMod))];
            else
                Pattern = [Pattern,(SoundA.*(1-AmpMod)),(SoundB.*(1-AmpMod))];
            end
            AmpMod = AmpMod/1.2;
        end
        Pattern = Pattern(1,:) + BGSound(1:length(Pattern));
end


% Program sound server and load sounds
P = SF/100; Interval = P;
A.SamplingRate = SF;
A.BpodEvents = 'On';
switch S.GUI.TrainingLevel
    case{1 2 3}
        A.TriggerMode = 'Toggle'; %calling a new sound turns off current one
    case{4 5 6 7}
        A.TriggerMode = 'Master'; %Calling new sound starts new sound and turns off old one
end

A.loadSound(1, CueSound);
A.loadSound(2, BGSound);
A.loadSound(3, RewardSound);
A.loadSound(4, Pause);
switch S.GUI.TrainingLevel
    case{7}
        A.loadSound(5, Pattern);
end


Envelope = 0.005:0.005:1; % Define envelope of amplitude coefficients, to play at sound onset + offset
A.AMenvelope = Envelope;

% Set Bpod serial message library with correct codes to trigger sounds 1 - 4 on analog output channels 1 - 2
analogPortIndex = find(strcmp(BpodSystem.Modules.Name, 'AudioPlayer1'));
if isempty(analogPortIndex)
    error('Error: Bpod AudioPlayer module not found. If you just plugged it in, please restart Bpod.')
end
LoadSerialMessages('AudioPlayer1', {['P' 0], ['P' 1], ['P' 2], ['P' 3],['P' 4]});


%% Initialize plots

[filepath,name,~] = fileparts(BpodSystem.Path.CurrentDataFile);

switch S.GUI.TrainingLevel
    case {1}
        figure(4);
        %Plot trials done
        xlabel('Time (mins)','FontSize',12,'FontWeight','bold');
        ylabel('Counts','FontSize',12,'FontWeight','bold');
        title('Trials Done');
        
    case {2 3 4 5 6 7}
        figure(4);
        %Plot Cumulative correct/incorrect
        subplot(2,2,1)
        xlabel('Time (mins)','FontSize',12,'FontWeight','bold');
        ylabel('Counts','FontSize',12,'FontWeight','bold');
        title('Cumulative rewards(b)/erros(r)');
        %Plot percentage correct
        subplot(2,2,2)
        xlabel('Trials','FontSize',12,'FontWeight','bold');
        ylabel('Percentage','FontSize',12,'FontWeight','bold');
        title('Percentage correct');
        ylim([0 1])
        %Plot trial by trial reuslts
        subplot(2,2,[3 4])
        hold on;
        xlabel('Trials','FontSize',12,'FontWeight','bold');
        ylabel('Response Time','FontSize',12,'FontWeight','bold');
        title('* = Pause/Cue time');
        
        %Create an object that is called on cleanup to save stuff
        finishup = onCleanup(@() CleanupFunction(4, filepath, name, BpodSystem.Path.CurrentDataFile, S));
end

%% Main trial loop
for currentTrial = 1:BpodSystem.Data.MaxTrials
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    %Dammy edit for water modulaiton
%     maxasymp = 38; %'maximum asymptote'
%     slp = 3;  %'Slope of the logistic function'
%     inflp =  300; %'concentration at the inflection point'
%     minasymp = -20; %'minimum asymptote'
%     assym = 0.7; %'asymmetry factor'
%     trial_1 = S.GUI.RewardAmount*0.2;  %'uL on first trial'
%     trial_150 = S.GUI.RewardAmount*(2/3); %'uL on trial 150');
%     trial_300 = S.GUI.RewardAmount; %'uL on trial 300');
%     WaterAmount=maxasymp + (minasymp./(1+(currentTrial/inflp).^slp).^assym);
    
%     R = GetValveTimes(WaterAmount, 2); ValveTime = R(1);% Update reward amounts
    R = GetValveTimes(S.GUI.RewardAmount, 2); ValveTime = R(1);% Update reward amounts

    display(S.GUI.RewardAmount)
    display(ValveTime)
    
    %% Trial specific Matrix outputs
    
    sma = NewStateMachine(); % Assemble state matrix

    switch S.GUI.TrainingLevel
        
        case {1} % Habituation
            RewardOutput = {'AudioPlayer1', 3};
            sma = AddState(sma, 'Name', 'WaitForInitialPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1In', 'CueDelay'},...
                'OutputActions', {'AudioPlayer1','*','PWM1', 255,}); %light on in centre
            sma = AddState(sma, 'Name', 'CueDelay', ...
                'Timer', CueDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'WaitForInitialPoke', 'Tup', 'WaitForResponse'},...
                'OutputActions', {'AudioPlayer1',1,'BNCState', 2}); %go cue after centre poke
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer',S.GUI.HabituationResponseWindow ,...
                'StateChangeConditions', {'Port2In', 'Reward',  'Tup', 'exit'},...
                'OutputActions',{'PWM2', 255,});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', 2}); % Valve state might be 1or 2  Not sure!
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', S.GUI.CueDuration,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions',RewardOutput);
            
            
        case {2 3 4} %  '2_CueDelay_Increase' '3_Variable_CueDelay' '4_BGSound_Cue_reward'
            
            
            
            
            RewardOutput = {'AudioPlayer1', 3};
            %if last  3 trials were correct, cue delay is 1% longer than previous trial
            if currentTrial > 3 && isnan(BpodSystem.Data.RawEvents.Trial{1, (currentTrial-1)}.States.Reward(1)) == 0 && isnan(BpodSystem.Data.RawEvents.Trial{1, (currentTrial-2)}.States.Reward(1)) == 0 && isnan(BpodSystem.Data.RawEvents.Trial{1, (currentTrial-3)}.States.Reward(1)) == 0
                CueDelay(currentTrial) = CueDelay(currentTrial-1)* 1.01;
            elseif currentTrial > 1
                CueDelay(currentTrial) = CueDelay(currentTrial-1);  
            end
            
            disp('Current Cue Delay is')
            CueDelay(currentTrial) %dont terminate with ;
            
            sma = SetGlobalTimer(sma, 1, CueDelay(currentTrial)); 

            if CueDelay(currentTrial) > S.GUI.MaxVariableCueDelay
                disp('Rat has reached wait criteria')
            end
            switch S.GUI.TrainingLevel
                case {2 3} 
                    BG_Output = {'GlobalTimerTrig', 1};      
                case {4}
                    BG_Output = {'AudioPlayer1', 2,'GlobalTimerTrig', 1};
            end
            
            sma = AddState(sma, 'Name', 'WaitForInitialPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1In', 'CueDelay'},...
                'OutputActions', {'AudioPlayer1','*','PWM1', 255}); % push newly uploaded waves to front (playback) buffers and turn on LED
            sma = AddState(sma, 'Name', 'CueDelay', ...
                'Timer', CueDelay(currentTrial) ,...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'Tup', 'GoCue'},...
                'OutputActions', BG_Output);
            sma = AddState(sma, 'Name', 'SecondChanceCueDelay', ...
                'Timer', CueDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'GlobalTimer1_End', 'GoCue'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'GoCue', ...
                'Timer',S.GUI.CueDuration ,...
                'StateChangeConditions', {'Port2In', 'Reward',  'Tup', 'WaitForResponse'},...
                'OutputActions',{'AudioPlayer1', 1}); %turn sound off for protocol 4
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer',(S.GUI.ResponseWindow-S.GUI.CueDuration) ,...
                'StateChangeConditions', {'Port2In', 'Reward',  'Tup', 'exit'},...
                'OutputActions',{});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', 3}); % Valve state might be 1,2,3 or 4!! Not sure
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 1,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', RewardOutput); % Valve state might be 1,2,3 or 4!! Not sure
            sma = AddState(sma, 'Name', 'EarlyWithdrawPurgatory', ...
                'Timer',S.GUI.WithdrawlLeniency  ,...
                'StateChangeConditions', {'Port1In', 'SecondChanceCueDelay','GlobalTimer1_End', 'GoCue', 'Tup', 'EarlyOut'},...
                'OutputActions', {}); %stop the sound %HOW??????
            sma = AddState(sma, 'Name', 'EarlyOut', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'Punish'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.PunishTimeoutDuration,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'AudioPlayer1', 4});
            
            
        case {5} % Pause Cue reward
            sma = SetGlobalTimer(sma, 1, PauseDelay(currentTrial)); 
            BG_Output1 = {'AudioPlayer1', 2, 'GlobalTimerTrig', 1};
            BG_Output = {'AudioPlayer1', 2};
            
            sma = AddState(sma, 'Name', 'WaitForInitialPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1In', 'CueDelay'},...
                'OutputActions', {'AudioPlayer1','*','PWM1', 255}); % Code to push newly uploaded waves to front (playback) buffers
            sma = AddState(sma, 'Name', 'CueDelay', ...
                'Timer', PauseDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'Tup', 'Pause'},...
                'OutputActions', BG_Output1); %Start BG sound
            sma = AddState(sma, 'Name', 'SecondChanceCueDelay', ...
                'Timer', PauseDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'GlobalTimer1_End', 'Pause'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Pause', ...
                'Timer',S.GUI.PauseDuration ,...
                'StateChangeConditions', {'Port2In', 'RewardDelay',  'Tup', 'GOCue'},...
                'OutputActions',{'AudioPlayer1', 4});
            sma = AddState(sma, 'Name', 'GOCue', ...
                'Timer',S.GUI.CueDuration ,...
                'StateChangeConditions', {'Port2In', 'RewardDelay',  'Tup', 'WaitForResponse'},...
                'OutputActions',{'AudioPlayer1',1, 'BNCState', 2});
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', (S.GUI.ResponseWindow-S.GUI.PauseDuration-S.GUI.CueDuration),...
                'StateChangeConditions', {'Port2In', 'RewardDelay' 'Tup', 'Punish'},...
                'OutputActions', BG_Output);
            sma = AddState(sma, 'Name', 'RewardDelay', ...
                'Timer', S.GUI.RewardDelay,...
                'StateChangeConditions', {'Tup', 'Reward'},...
                'OutputActions',{'AudioPlayer1', 4});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'AudioPlayer1', 3,'ValveState', 3}); % Valve state might be 1,2,3 or 4!! Not sure
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 1,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyWithdrawPurgatory', ...
                'Timer',S.GUI.WithdrawlLeniency  ,...
                'StateChangeConditions', {'Port1In', 'SecondChanceCueDelay','GlobalTimer1_End', 'Pause', 'Tup', 'EarlyOut'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyOut', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'Punish'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.PunishTimeoutDuration,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'AudioPlayer1', 4});  %stop the sound
            
        case {6} %  '6_Pause_Reward'
            
            sma = SetGlobalTimer(sma, 1, PauseDelay(currentTrial)); 
            BG_Output1 = {'AudioPlayer1', 2, 'BNCState', 2 , 'GlobalTimerTrig', 1};
            BG_Output = {'AudioPlayer1', 2, 'BNCState', 2};
            
            sma = AddState(sma, 'Name', 'WaitForInitialPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1In', 'CueDelay'},...
                'OutputActions', {'AudioPlayer1','*','PWM1', 255}); % Code to push newly uploaded waves to front (playback) buffers
            sma = AddState(sma, 'Name', 'CueDelay', ...
                'Timer', PauseDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'Tup', 'Pause'},...
                'OutputActions', BG_Output1); %Start BG sound
            sma = AddState(sma, 'Name', 'SecondChanceCueDelay', ...
                'Timer', PauseDelay(currentTrial),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'GlobalTimer1_End', 'Pause'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Pause', ...
                'Timer',S.GUI.PauseDuration ,...
                'StateChangeConditions', {'Port2In', 'RewardDelay',  'Tup', 'WaitForResponse'},...
                'OutputActions',{'AudioPlayer1', 4});
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', (S.GUI.ResponseWindow-S.GUI.PauseDuration),...
                'StateChangeConditions', {'Port2In', 'RewardDelay' 'Tup', 'Punish'},...
                'OutputActions',BG_Output);
            sma = AddState(sma, 'Name', 'RewardDelay', ...
                'Timer', S.GUI.RewardDelay,...
                'StateChangeConditions', {'Tup', 'Reward'},...
                'OutputActions',{'AudioPlayer1', 3});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', 3}); % Valve state might be 1,2,3 or 4!! Not sure
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 1,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyWithdrawPurgatory', ...
                'Timer',S.GUI.WithdrawlLeniency  ,...
                'StateChangeConditions', {'Port1In', 'SecondChanceCueDelay','GlobalTimer1_End', 'Pause', 'Tup', 'EarlyOut'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyOut', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'Punish'},...
                'OutputActions',{});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.PunishTimeoutDuration,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'AudioPlayer1', 4});  %stop the sound
            
        case {7} %7_Pattern_Pause_Reward
              
            sma = SetGlobalTimer(sma, 1, (PauseDelay(currentTrial)- S.GUI.PatternDuration)); 

            BG_Output1 = {'AudioPlayer1', 2, 'BNCState', 2, 'GlobalTimerTrig', 1};
            BG_Output = {'AudioPlayer1', 2, 'BNCState', 2};
            
            sma = AddState(sma, 'Name', 'WaitForInitialPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1In', 'CueDelay'},...
                'OutputActions', {'AudioPlayer1','*','PWM1', 255}); % Code to push newly uploaded waves to front (playback) buffers
            sma = AddState(sma, 'Name', 'CueDelay', ...
                'Timer', (PauseDelay(currentTrial)- S.GUI.PatternDuration),...
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'Tup', 'PatternStart'},...
                'OutputActions', BG_Output1); %Start BG sound, set global timer to take over timing incase the animal withdraws 
            sma = AddState(sma, 'Name', 'SecondChanceCueDelay', ...
                'Timer', (PauseDelay(currentTrial)- S.GUI.PatternDuration),... %irrelevant since the global timer will have now taken over
                'StateChangeConditions', {'Port1Out', 'EarlyWithdrawPurgatory', 'GlobalTimer1_End', 'PatternStart'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'PatternStart', ...
                'Timer',S.GUI.PatternDuration ,...
                'StateChangeConditions', {'Port2In', 'RewardDelay',  'Tup', 'Pause'},...
                'OutputActions',{'AudioPlayer1', 5});
            sma = AddState(sma, 'Name', 'Pause', ...
                'Timer',S.GUI.PauseDuration ,...
                'StateChangeConditions', {'Port2In', 'RewardDelay',  'Tup', 'WaitForResponse'},...
                'OutputActions',{'AudioPlayer1', 4});
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', (S.GUI.ResponseWindow-S.GUI.PauseDuration),...
                'StateChangeConditions', {'Port2In', 'RewardDelay' 'Tup', 'Punish'},...
                'OutputActions',BG_Output);
            sma = AddState(sma, 'Name', 'RewardDelay', ...
                'Timer', S.GUI.RewardDelay,...
                'StateChangeConditions', {'Tup', 'Reward'},...
                'OutputActions',{'AudioPlayer1', 3});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', 3}); % Valve state might be 1,2,3 or 4!! Not sure
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 1,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyWithdrawPurgatory', ...
                'Timer',S.GUI.WithdrawlLeniency  ,...
                'StateChangeConditions', {'Port1In', 'SecondChanceCueDelay', 'GlobalTimer1_End', 'PatternStart', 'Tup', 'EarlyOut'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'EarlyOut', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'Punish'},...
                'OutputActions',{});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.PunishTimeoutDuration,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'AudioPlayer1', 4});  %stop the sound
            
    end
    
    
    
    %% Save out data, update trialoutcome plot
    
    SendStateMachine(sma);
    RawEvents = RunStateMachine;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        
        switch S.GUI.TrainingLevel
            case {1 2 3 4} % Habituation / ShortCue_Reward / VariableCue
                BpodSystem.Data.CueDelay(currentTrial) = CueDelay(currentTrial); % Adds Cue delay of the current trial to data
                BpodSystem.Data.PauseDelay(currentTrial) = PauseDelay(currentTrial);
            case {5 6 7} % Variable Pause then Cue / Variable Pause
                BpodSystem.Data.PauseDelay(currentTrial) = PauseDelay(currentTrial);
        end
        
        switch S.GUI.TrainingLevel
            case {1}
                UpdateHabituationPlot(BpodSystem.Data); %update online plot
            case {2 3 4 5 6 7}
                UpdateOnlinePlot(BpodSystem.Data); %update online plot
        end
    end
    
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
end













