% UpdateHabituationPlot

function UpdateHabituationPlot(Data)

global BpodSystem
%CurrentTrial
i = BpodSystem.Data.nTrials;

%IntialisePlottingParams
if i == 1
    BpodSystem.Data.OnlinePlotParams.CorrectCount = 0;
    BpodSystem.Data.OnlinePlotParams.RewardEventTimes = zeros(1,BpodSystem.Data.MaxTrials);
    BpodSystem.Data.OnlinePlotParams.drink_time_mins = zeros(1,BpodSystem.Data.MaxTrials);
    BpodSystem.Data.OnlinePlotParams.cumtrialcount = zeros(1,BpodSystem.Data.MaxTrials);
    BpodSystem.Data.OnlinePlotParams.CorrectTrials = zeros(1,BpodSystem.Data.MaxTrials);
    
end

% HOW MANY REWARDS AND HOW LONG
if isnan(Data.RawEvents.Trial{1, i}.States.Reward(1)) == 0
    BpodSystem.Data.OnlinePlotParams.CorrectCount = BpodSystem.Data.OnlinePlotParams.CorrectCount + 1;
     BpodSystem.Data.OnlinePlotParams.CorrectTrials((sum(BpodSystem.Data.OnlinePlotParams.CorrectTrials>0)+1)) = BpodSystem.Data.OnlinePlotParams.CorrectCount;
    %Find Correct time stamp and update params
    event_time = Data.RawEvents.Trial{1, i}.States.Reward(1);
    BpodSystem.Data.OnlinePlotParams.RewardEventTimes(i) = BpodSystem.Data.TrialStartTimestamp(i) + event_time;
    %Find within trial event time
    BpodSystem.Data.OnlinePlotParams.WithinTrialEventTime(i) = Data.RawEvents.Trial{1, i}.States.Reward(1);
end

BpodSystem.Data.OnlinePlotParams.drink_time_mins((sum(BpodSystem.Data.OnlinePlotParams.drink_time_mins>0)+1)) = (BpodSystem.Data.OnlinePlotParams.RewardEventTimes(i))/60;
BpodSystem.Data.OnlinePlotParams.cumtrialcount(i) = i;

figure(4);
%Plot Cumulative correct/incorrect
plot(BpodSystem.Data.OnlinePlotParams.drink_time_mins(1:(sum(BpodSystem.Data.OnlinePlotParams.drink_time_mins>0))), BpodSystem.Data.OnlinePlotParams.CorrectTrials(1:(sum(BpodSystem.Data.OnlinePlotParams.CorrectTrials>0))), 'x-', 'LineWidth', 2)
hold on
xlabel('Time (mins)','FontSize',12,'FontWeight','bold');
ylabel('Counts','FontSize',12,'FontWeight','bold');
title('Cumulative rewards(b)/erros(r)');

end
