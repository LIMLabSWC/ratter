function [x, y] = PerformanceSummarySection(obj, action, varargin)

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
    case 'evaluate'

        % if value(training_stage) == 8 && n_completed_trials > 0
        %     stage_8_Trials.value = value(stage_8_Trials) + 1;
        %     stage_8_TrialsToday.value = value(stage_8_TrialsToday) + 1;
        %     stage_8_ViolationRate.value = ((value(stage_8_ViolationRate) * (value(stage_8_Trials) - 1)) + double(violation_history(end))) / value(stage_8_Trials);
        %     stage_8_TimeoutRate.value = ((value(stage_8_TimeoutRate) * (value(stage_8_Trials) - 1)) + double(timeout_history(end))) / value(stage_8_Trials);
        %     if value(hit_history(end)) == 1
        %         stage_8_TrialsValid.value = value(stage_8_TrialsValid) + 1;
        %     end
        % end
        % 

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
        if value(SummaryShow) == 1
            set(value(myfig), 'Visible', 'on');            
        else
            set(value(myfig), 'Visible', 'off');
        end

end

end

