function [x, y] = Training_Performance_Summary(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------

    case 'init'
        if length(varargin) < 2
            error('Need at least two arguments, x and y position, to initialize %s', mfilename);
        end
        x = varargin{1}; y = varargin{2};

        % SoloParamHandle(obj, 'my_xyfig', 'value', [x y double(gcf)]);
        
        ToggleParam(obj, 'SummaryShow', 0, x, y, 'OnString', 'Summary Show', ...
            'OffString', 'Summary Hidden', 'TooltipString', 'Show/Hide Summary panel');
        set_callback(SummaryShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
        next_row(y);
        oldx=x; oldy=y;    parentfig=double(gcf);

        SoloParamHandle(obj, 'myfig', 'value', figure('Position', [ 226   122  1406   400], ...
            'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
            'Name', mfilename), 'saveable', 0);
        set(double(gcf), 'Visible', 'off');

         
         % Create stage names
         N_Stages = 8;
        for i = 1:N_Stages
            rowNames{i, 1} = sprintf('Stage %d', i);
        end
        % Create column names
        N_params = 5;
        columnNames = {'Stage/Param','Trials','TrialsToday','TrialsValid','ViolationRate','TimeoutRate'};       

        % Create Variable Names for each Edit Box
        count = 0;
        variable_names = cell(1,N_params * N_Stages);
        for j = 1:N_params
            for i = 1:N_Stages
                count = count + 1;
                variable_names(count) = {sprintf('stage_%i_%s',N_Stages - i + 1,columnNames{j+1})};
            end
        end

        count = 0;
         x = 100; y=100;
            
        for column_n = 1 : N_params + 1 
            for rows_n = 1 : N_Stages + 1
                if column_n == 1 && rows_n < N_Stages + 1
                    SubheaderParam(obj, 'title', sprintf('Stage%i',(N_Stages - rows_n + 1)), x, y);
                    next_row(y);
                end
                if column_n == 1 && rows_n == N_Stages + 1
                    SubheaderParam(obj, 'title', columnNames{1}, x, y);
                    next_row(y);
                end
                if column_n > 1 && rows_n < N_Stages + 1
                    count = count + 1;
                    NumeditParam(obj, variable_names{count}, 0, x, y);
                    next_row(y);
                end
                if rows_n == N_Stages + 1 && column_n > 1
                    SubheaderParam(obj, 'title', columnNames{column_n}, x, y);
                    next_row(y);
                end
            end
              next_column(x); y=100;
        end

        % 
        x=oldx; y=oldy;
        figure(parentfig);

%% Evaluate
    case evaluate

        switch value(training_stage)

            case 1

                if n_completed_trials > 0

                    stage_1_Trials.value = value(stage_1_Trials) + 1;
                    stage_1_TrialsToday.value = value(stage_1_TrialsToday) + 1;
                    if value(previous_sides(end)) ~= value(ThisTrial)
                        trial_oppSide.value = value(trial_oppSide) + 1; % updating value for variable in TrainingParams_Section
                    end                   
                    stage_1_ViolationRate.value = nan;
                    stage_1_TimeoutRate.value = nan;
                    if value(hit_history(end)) == 1
                        stage_1_TrialsValid.value = value(stage_1_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_1_Trials);
                    ntrials_stage_today.value = value(stage_1_TrialsToday);
                    violation_stage.value = value(stage_1_ViolationRate);
                    timeout_stage.value = value(stage_1_TimeoutRate);
                end

            case 2

                if n_completed_trials > 0

                    stage_2_Trials.value = value(stage_2_Trials) + 1;
                    stage_2_TrialsToday.value = value(stage_2_TrialsToday) + 1;
                    if value(previous_sides(end)) ~= value(ThisTrial) && all(hit_history(end-1:end)) % last and present trials should also be a valid trial
                        trial_oppSide.value = value(trial_oppSide) + 1;  % updating value for variable in TrainingParams_Section
                    end
                    stage_2_ViolationRate.value = nan;
                    stage_2_TimeoutRate.value = ((value(stage_2_TimeoutRate) * (value(stage_2_Trials) - 1)) + double(timeout_history(end))) / value(stage_2_Trials);
                    if value(hit_history(end)) == 1
                        stage_2_TrialsValid.value = value(stage_2_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_2_Trials);
                    ntrials_stage_today.value = value(stage_2_TrialsToday);
                    violation_stage.value = value(stage_2_ViolationRate);
                    timeout_stage.value = value(stage_2_TimeoutRate);
                end

            case 3

                if n_completed_trials > 0

                    stage_3_Trials.value = value(stage_3_Trials) + 1;
                    stage_1_TrialsToday.value = value(stage_3_TrialsToday) + 1;
                    stage_3_ViolationRate.value = ((value(stage_3_ViolationRate) * (value(stage_3_Trials) - 1)) + double(violation_history(end))) / value(stage_3_Trials);
                    stage_3_TimeoutRate.value = ((value(stage_3_TimeoutRate) * (value(stage_3_Trials) - 1)) + double(timeout_history(end))) / value(stage_3_Trials);
                    if value(hit_history(end)) == 1
                        stage_3_TrialsValid.value = value(stage_3_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_3_Trials);
                    ntrials_stage_today.value = value(stage_3_TrialsToday);
                    violation_stage.value = value(stage_3_ViolationRate);
                    timeout_stage.value = value(stage_3_TimeoutRate);
                end

            case 4  

                if n_completed_trials > 0

                    stage_4_Trials.value = value(stage_4_Trials) + 1;
                    stage_4_TrialsToday.value = value(stage_4_TrialsToday) + 1;
                    stage_4_ViolationRate.value = ((value(stage_4_ViolationRate) * (value(stage_4_Trials) - 1)) + double(violation_history(end))) / value(stage_4_Trials);
                    stage_4_TimeoutRate.value = ((value(stage_4_TimeoutRate) * (value(stage_4_Trials) - 1)) + double(timeout_history(end))) / value(stage_4_Trials);
                    if value(hit_history(end)) == 1
                        stage_4_TrialsValid.value = value(stage_4_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_4_Trials);
                    ntrials_stage_today.value = value(stage_4_TrialsToday);
                    violation_stage.value = value(stage_4_ViolationRate);
                    timeout_stage.value = value(stage_4_TimeoutRate);
                end

            case 5

                if n_completed_trials > 0

                    stage_5_Trials.value = value(stage_5_Trials) + 1;
                    stage_5_TrialsToday.value = value(stage_5_TrialsToday) + 1;
                    stage_5_ViolationRate.value = ((value(stage_5_ViolationRate) * (value(stage_5_Trials) - 1)) + double(violation_history(end))) / value(stage_5_Trials);
                    stage_5_TimeoutRate.value = ((value(stage_5_TimeoutRate) * (value(stage_5_Trials) - 1)) + double(timeout_history(end))) / value(stage_5_Trials);
                    if value(hit_history(end)) == 1
                        stage_5_TrialsValid.value = value(stage_5_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_5_Trials);
                    ntrials_stage_today.value = value(stage_5_TrialsToday);
                    violation_stage.value = value(stage_5_ViolationRate);
                    timeout_stage.value = value(stage_5_TimeoutRate);
                end

            case 6

                if n_completed_trials > 0

                    stage_6_Trials.value = value(stage_6_Trials) + 1;
                    stage_6_TrialsToday.value = value(stage_6_TrialsToday) + 1;
                    stage_6_ViolationRate.value = ((value(stage_6_ViolationRate) * (value(stage_6_Trials) - 1)) + double(violation_history(end))) / value(stage_6_Trials);
                    stage_6_TimeoutRate.value = ((value(stage_6_TimeoutRate) * (value(stage_6_Trials) - 1)) + double(timeout_history(end))) / value(stage_6_Trials);
                    if value(hit_history(end)) == 1
                        stage_6_TrialsValid.value = value(stage_6_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_6_Trials);
                    ntrials_stage_today.value = value(stage_6_TrialsToday);
                    violation_stage.value = value(stage_6_ViolationRate);
                    timeout_stage.value = value(stage_6_TimeoutRate);
                end

            case 7

                if n_completed_trials > 0

                    stage_7_Trials.value = value(stage_7_Trials) + 1;
                    stage_7_TrialsToday.value = value(stage_7_TrialsToday) + 1;
                    stage_7_ViolationRate.value = ((value(stage_7_ViolationRate) * (value(stage_7_Trials) - 1)) + double(violation_history(end))) / value(stage_7_Trials);
                    stage_7_TimeoutRate.value = ((value(stage_7_TimeoutRate) * (value(stage_7_Trials) - 1)) + double(timeout_history(end))) / value(stage_7_Trials);
                    if value(hit_history(end)) == 1
                        stage_7_TrialsValid.value = value(stage_7_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_7_Trials);
                    ntrials_stage_today.value = value(stage_7_TrialsToday);
                    violation_stage.value = value(stage_7_ViolationRate);
                    timeout_stage.value = value(stage_7_TimeoutRate);
                end

            case 8 

                if n_completed_trials > 0

                    stage_8_Trials.value = value(stage_8_Trials) + 1;
                    stage_8_TrialsToday.value = value(stage_8_TrialsToday) + 1;
                    stage_8_ViolationRate.value = ((value(stage_8_ViolationRate) * (value(stage_8_Trials) - 1)) + double(violation_history(end))) / value(stage_8_Trials);
                    stage_8_TimeoutRate.value = ((value(stage_8_TimeoutRate) * (value(stage_8_Trials) - 1)) + double(timeout_history(end))) / value(stage_8_Trials);
                    if value(hit_history(end)) == 1
                        stage_8_TrialsValid.value = value(stage_8_TrialsToday) + 1;
                    end
                    % Updating Disp Values for SessionPeformance Section as
                    % well
                    ntrials_stage.value = value(stage_8_Trials);
                    ntrials_stage_today.value = value(stage_8_TrialsToday);
                    violation_stage.value = value(stage_8_ViolationRate);
                    timeout_stage.value = value(stage_8_TimeoutRate);
                end
        end


%% Case close
    case 'close'
        set(value(myfig), 'Visible', 'off');
        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
       
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

    %% Case hide
    case 'hide'
        SummaryShow.value = 0;
        set(value(myfig), 'Visible', 'off');

    %% Case show
    case 'show'
        SummaryShow.value = 1;
        set(value(myfig), 'Visible', 'on');

    %% Case Show_hide
    case 'show_hide'
        if SummaryShow == 1
            set(value(myfig), 'Visible', 'on');            
        else
            set(value(myfig), 'Visible', 'off');
        end

end

end

