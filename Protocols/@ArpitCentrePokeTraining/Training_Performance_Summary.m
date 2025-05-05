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

        ToggleParam(obj, 'SummaryShow', 1, x, y, 'OnString', 'Summary Show', ...
            'OffString', 'Summary Hidden', 'TooltipString', 'Show/Hide Summary panel');
        set_callback(SummaryShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
        next_row(y);

        SoloParamHandle(obj, 'myfig', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
            'Name', mfilename), 'saveable', 0);
        screen_size = get(0, 'ScreenSize');
        set(value(myfig),'Position',[1 screen_size(4)-740, 400 400]); % put fig at top right
        % set(gcf, 'Visible', 'off');

        SoloParamHandle(obj, 'h1', 'value', []);

        x = 10; y=5;
               
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
        for j = 1:N_params
            for i = 1:N_Stages
                count = count + 1;
                variable_names(count) = sprintf('stage_%i_%s',i,columnNames{j+1});
            end
        end

        count = 0;

        for column_n = 1 : N_params + 1            
            for rows_n = 1 : N_Stages + 1
                if column_n == 1 && rows_n ~= N_Stages + 1
                    SubheaderParam(obj, 'title', sprintf('Stage %i',(N_stages - column_n + 1)), x, y);
                    next_row(y);
                end
                if column_n == 1 && rows_n == N_Stages + 1
                    SubheaderParam(obj, 'title', columnNames{1}, x, y);
                    next_row(y);
                end
                if column_n ~= 1 && rows_n ~= N_Stages + 1
                    count = count + 1;
                    NumeditParam(obj, variable_names{count}, 0, x, y);
                    next_row(y);
                end
                if rows_n == N_Stages + 1
                    SubheaderParam(obj, 'title', columnNames{column_n+1}, x, y);
                    next_row(y);
                end
            end
            next_column(x);
        end


%% Case close
    case 'close'
        set(value(myfig), 'Visible', 'off');
        set(value(stim_dist_fig), 'Visible', 'off');
        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        if exist('stim_dist_fig', 'var') && isa(stim_dist_fig, 'SoloParamHandle') && ishandle(value(stim_dist_fig)) %#ok<NODEF>
            delete(value(stim_dist_fig));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

    %% Case hide
    case 'hide'
        SummaryShow.value = 0;
        set(value(myfig), 'Visible', 'off');
        set(value(stim_dist_fig), 'Visible', 'off');

    %% Case show
    case 'show'
        SummaryShow.value = 1;
        set(value(myfig), 'Visible', 'on');
        set(value(stim_dist_fig), 'Visible', 'on');

    %% Case Show_hide
    case 'show_hide'
        if SummaryShow == 1
            set(value(myfig), 'Visible', 'on'); 
            set(value(stim_dist_fig), 'Visible', 'on');%#ok<NODEF> (defined by GetSoloFunctionArgs)
        else
            set(value(myfig), 'Visible', 'off');
            set(value(stim_dist_fig), 'Visible', 'off');
        end

end

end

