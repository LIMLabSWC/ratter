
% Online plotting Helper function for AudPause  
% Emmett Thompson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function UpdateOnlinePlot(Data)

global BpodSystem
%CurrentTrial
i = BpodSystem.Data.nTrials;

    %IntialisePlottingParams
    if i == 1
        BpodSystem.Data.OnlinePlotParams.WrongTrials = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.CorrectTrials = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.WrongCount = 0;
        BpodSystem.Data.OnlinePlotParams.CorrectCount = 0;
        BpodSystem.Data.OnlinePlotParams.RewardEventTimes = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.WrongEventTimes = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.PrcntCorrect = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.drink_time_mins = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.wrong_time_mins = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.cumtrialcount = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.missedtrials = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.WithinTrialEventTime = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.CueTime = zeros(1,BpodSystem.Data.MaxTrials);
        BpodSystem.Data.OnlinePlotParams.PlotColour = {};
    end
    
    % Determine if last was incorrect and if so change params
    if isnan(Data.RawEvents.Trial{1, i}.States.Punish(1)) == 0
        BpodSystem.Data.OnlinePlotParams.WrongCount = BpodSystem.Data.OnlinePlotParams.WrongCount + 1;
        BpodSystem.Data.OnlinePlotParams.WrongTrials((sum(BpodSystem.Data.OnlinePlotParams.WrongTrials>0)+1)) = BpodSystem.Data.OnlinePlotParams.WrongCount;
        %Find incorrect time stamp and update params
        event_time = Data.RawEvents.Trial{1, i}.States.Punish(1);
        BpodSystem.Data.OnlinePlotParams.WrongEventTimes(i) = BpodSystem.Data.TrialStartTimestamp(i) + event_time;
        %Find within trial event time
        BpodSystem.Data.OnlinePlotParams.WithinTrialEventTime(i) = Data.RawEvents.Trial{1, i}.States.Punish(1);

        % Determine if last was correct and if so change params
    elseif isnan(Data.RawEvents.Trial{1, i}.States.Reward(1)) == 0
        BpodSystem.Data.OnlinePlotParams.CorrectCount = BpodSystem.Data.OnlinePlotParams.CorrectCount + 1;
        BpodSystem.Data.OnlinePlotParams.CorrectTrials((sum(BpodSystem.Data.OnlinePlotParams.CorrectTrials>0)+1)) = BpodSystem.Data.OnlinePlotParams.CorrectCount;
        %Find Correct time stamp and update params
        event_time = Data.RawEvents.Trial{1, i}.States.Reward(1);
        BpodSystem.Data.OnlinePlotParams.RewardEventTimes(i) = BpodSystem.Data.TrialStartTimestamp(i) + event_time;
        %Find within trial event time
        BpodSystem.Data.OnlinePlotParams.WithinTrialEventTime(i) = Data.RawEvents.Trial{1, i}.States.Reward(1);
    end
    
    %Find Pause/Cue delay 
    if isnan(BpodSystem.Data.PauseDelay(i)) == 0
        Cuetime = BpodSystem.Data.PauseDelay(i);
    else 
        Cuetime = BpodSystem.Data.CueDelay(i);
    end
    BpodSystem.Data.OnlinePlotParams.CueTime(i) = Cuetime;
    
    %Determine Prct correct and update params
    BpodSystem.Data.OnlinePlotParams.PrcntCorrect(i) = BpodSystem.Data.OnlinePlotParams.CorrectCount/i;

    BpodSystem.Data.OnlinePlotParams.drink_time_mins((sum(BpodSystem.Data.OnlinePlotParams.drink_time_mins>0)+1)) = (BpodSystem.Data.OnlinePlotParams.RewardEventTimes(i))/60;
    BpodSystem.Data.OnlinePlotParams.wrong_time_mins((sum(BpodSystem.Data.OnlinePlotParams.wrong_time_mins>0)+1)) = (BpodSystem.Data.OnlinePlotParams.WrongEventTimes(i))/60;
    BpodSystem.Data.OnlinePlotParams.cumtrialcount(i) = i;
    
    if BpodSystem.Data.OnlinePlotParams.missedtrials(i) == 0
        
        figure(4);
       
        %Plot Cumulative correct/incorrect
        subplot(2,2,1)
        plot(BpodSystem.Data.OnlinePlotParams.wrong_time_mins(1:(sum(BpodSystem.Data.OnlinePlotParams.wrong_time_mins>0))), BpodSystem.Data.OnlinePlotParams.WrongTrials(1:(sum(BpodSystem.Data.OnlinePlotParams.WrongTrials>0))), 'r', 'LineWidth', 2)
        hold on
        plot(BpodSystem.Data.OnlinePlotParams.drink_time_mins(1:(sum(BpodSystem.Data.OnlinePlotParams.drink_time_mins>0))), BpodSystem.Data.OnlinePlotParams.CorrectTrials(1:(sum(BpodSystem.Data.OnlinePlotParams.CorrectTrials>0))), 'b', 'LineWidth', 2)
        hold on
        xlabel('Time (mins)','FontSize',12,'FontWeight','bold');
        ylabel('Counts','FontSize',12,'FontWeight','bold');
        title('Cumulative rewards(b)/erros(r)');
        
        %Plot percentage correct
        subplot(2,2,2)
        plot(BpodSystem.Data.OnlinePlotParams.cumtrialcount(1:i), BpodSystem.Data.OnlinePlotParams.PrcntCorrect(1:i), 'k', 'LineWidth', 2)
        xlabel('Trials','FontSize',12,'FontWeight','bold');
        ylabel('Percentage','FontSize',12,'FontWeight','bold');
        title('Percentage correct');
        ylim([0 1])
        
        %Plot percentage correct
        subplot(2,2,[3 4])
        if isnan(BpodSystem.Data.RawEvents.Trial{1, i}.States.Punish(1)) == 0
        BpodSystem.Data.OnlinePlotParams.PlotColour{i} = 'ro';
        else
        BpodSystem.Data.OnlinePlotParams.PlotColour{i} = 'bo';
        end    
        for e = 1:i
        plot(BpodSystem.Data.OnlinePlotParams.cumtrialcount(e),BpodSystem.Data.OnlinePlotParams.WithinTrialEventTime(e), BpodSystem.Data.OnlinePlotParams.PlotColour{e},'LineWidth', 2)
        hold on;
        end
        hold on;
        plot(BpodSystem.Data.OnlinePlotParams.cumtrialcount(1:i), BpodSystem.Data.OnlinePlotParams.CueTime(1:i),  'k*','LineWidth', 1)
        xlabel('Trials','FontSize',12,'FontWeight','bold');
        ylabel('Response Time','FontSize',12,'FontWeight','bold');
        title('* = Pause/Cue time');
    end