function [x, y] = Training_ParamsSection(obj, action, x,y)

GetSoloFunctionArgs(obj);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------

    case 'init'

        SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);
        next_row(y); next_row(y); next_row(y);next_row(y);
        switch value(training_stage)

            case 1
            % STAGE RUNNING PARAMETERS
            % SubheaderParam(obj, 'title', 'Stage Params', x, y);
            % next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'total_trials', 300, x, y,'label','Trials','TooltipString','total trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'total_trials_opp', 150, x, y,'label','Trials_Opp','TooltipString','total trials with opposide side option in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y); next_row(y);

            case 2
             % STAGE RUNNING PARAMETERS
            NumeditParam(obj, 'max_rColl_dur', 300, x, y,'label','T_Max_RCollect','TooltipString','User given max water collect time(code will optimize for value below this)'); next_row(y);
            NumeditParam(obj, 'min_rColl_dur', 100, x, y,'label','T_Min_RCollect','TooltipString','User given min water collect time(code will optimize for value above this)'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'total_trials', 1000, x, y,'label','Trials','TooltipString','total trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'total_trials_opp', 400, x, y,'label','Trials_Opp','TooltipString','total trials with opposide side option in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y);next_row(y);
           
            case 3  % no completion test required
             % STAGE RUNNING PARAMETERS
            DispParam(obj, 'max_CP', 0.3, x, y,'label','CP_Dur_Max','TooltipString','max CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'CPfraction_inc', 0.001, x, y,'label','CP_frac_Increase','TooltipString','CP duration is increased by this fraction'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            
            case 4
            % STAGE RUNNING PARAMETERS
            NumeditParam(obj, 'max_CP', 1.5, x, y,'label','CP_Dur_Max','TooltipString','max CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'CPfraction_inc', 0.001, x, y,'label','CP_frac_Increase','TooltipString','CP duration is increased by this fraction'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'recent_violation', 0.15, x, y,'label','Recent_ViolateRate','TooltipString','violation rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'recent_timeout', 0.15, x, y,'label','Recent_TimeoutRate','TooltipString','timeout rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'stage_violation', 0.35, x, y,'label','Stage_ViolationRate','TooltipString','overall violation rate in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y);next_row(y);
            
            case 5
             % STAGE RUNNING PARAMETERS
            NumeditParam(obj, 'max_CP', 5, x, y,'label','CP_Dur_Max','TooltipString','max CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'CPfraction_inc', 0.002, x, y,'label','CP_frac_Increase','TooltipString','CP duration is increased by this fraction'); next_row(y);
            NumeditParam(obj, 'min_CP', 1.5, x, y,'label','CP_Dur_Min','TooltipString','min CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'starting_CP', 0.3, x, y,'TooltipString','min CP duration (minus the settling-in time) during warm up'); next_row(y);
            NumeditParam(obj, 'warm_up_trials', 10, x, y,'label','Warmup Trials','TooltipString','N trials for warmup'); next_row(y);
            NumeditParam(obj, 'stim_dur', 0.4, x, y,'label','A1 Dur','TooltipString','This stage A1 duration'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'recent_violation', 0.15, x, y,'label','Recent_ViolateRate','TooltipString','violation rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'recent_timeout', 0.15, x, y,'label','Recent_TimeoutRate','TooltipString','timeout rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'stage_violation', 0.35, x, y,'label','Stage_ViolationRate','TooltipString','overall violation rate in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'total_trials', 1200, x, y,'label','Trials','TooltipString','total trials in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y);next_row(y);

            case 6
             % STAGE RUNNING PARAMETERS
            NumeditParam(obj, 'max_CP', 5, x, y,'label','CP_Dur_Max','TooltipString','max CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'starting_CP', 0.3, x, y,'TooltipString','min CP duration (minus the settling-in time) during warm up'); next_row(y);
            NumeditParam(obj, 'warm_up_trials', 20, x, y,'label','Warmup Trials','TooltipString','N trials for warmup'); next_row(y);
            NumeditParam(obj, 'max_prestim', 2, x, y,'label','Pre-Stim Max','TooltipString','This stage Max Time, before starting the stimulus'); next_row(y);
            NumeditParam(obj, 'min_prestim', 0.2, x, y,'label','Pre-Stim Min','TooltipString','This stage Min Time, before starting the stimulus'); next_row(y);
            NumeditParam(obj, 'stim_dur', 0.4, x, y,'label','A1 Dur','TooltipString','This stage A1 duration'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'recent_violation', 0.15, x, y,'label','Recent_ViolateRate','TooltipString','violation rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'recent_timeout', 0.15, x, y,'label','Recent_TimeoutRate','TooltipString','timeout rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'stage_violation', 0.25, x, y,'label','Stage_ViolationRate','TooltipString','overall violation rate in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'total_trials', 1500, x, y,'label','Trials','TooltipString','total trials in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y);next_row(y);

            case 7
             % STAGE RUNNING PARAMETERS
            NumeditParam(obj, 'max_CP', 5, x, y,'label','CP_Dur_Max','TooltipString','max CP duration being trained in this stage'); next_row(y);
            NumeditParam(obj, 'starting_CP', 0.3, x, y,'TooltipString','min CP duration (minus the settling-in time) during warm up'); next_row(y);
            NumeditParam(obj, 'warm_up_trials', 20, x, y,'label','Warmup Trials','TooltipString','N trials for warmup'); next_row(y);
            NumeditParam(obj, 'max_prestim', 2, x, y,'label','Pre-Stim Max','TooltipString','This stage Max Time, before starting the stimulus'); next_row(y);
            NumeditParam(obj, 'min_prestim', 0.2, x, y,'label','Pre-Stim Min','TooltipString','This stage Min Time, before starting the stimulus'); next_row(y);
            NumeditParam(obj, 'max_prego', 2, x, y,'label','Max A1-GoCue time','TooltipString','This stage Max time, between the end of the stimulus and the go cue'); next_row(y);
            NumeditParam(obj, 'min_prego', 0.2, x, y,'label','Min A1-GoCue time','TooltipString','This stage Min time, between the end of the stimulus and the go cue'); next_row(y);
            NumeditParam(obj, 'stim_dur', 0.4, x, y,'label','A1 Dur','TooltipString','This stage A1 duration'); next_row(y);
            SubheaderParam(obj, 'title', 'Stage Params', x, y); next_row(y);
            % COMPLETION TEST PARAMETERS
            NumeditParam(obj, 'recent_violation', 0.15, x, y,'label','Recent_ViolateRate','TooltipString','violation rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'recent_timeout', 0.15, x, y,'label','Recent_TimeoutRate','TooltipString','timeout rate for last 20 trials in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'stage_violation', 0.20, x, y,'label','Stage_ViolationRate','TooltipString','overall violation rate in this stage for its completion'); next_row(y);
            NumeditParam(obj, 'total_trials', 2000, x, y,'label','Trials','TooltipString','total trials in this stage for its completion'); next_row(y);
            SubheaderParam(obj, 'title', 'Completion Params', x, y); next_row(y);
        end
        SubheaderParam(obj, 'title', 'AUTOMATED TRAINING STAGE', x, y);

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

end
