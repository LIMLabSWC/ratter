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

       % ------------------------------------------------------------------
	%              evaluate
	% ------------------------------------------------------------------

	case 'evaluate'
    	
    	pd.stage1_trials_total = value(stage_1_Trials);
        pd.stage1_trials_today = value(stage_1_TrialsToday);
        pd.stage1_trials_valid = value(stage_1_TrialsValid); 
        pd.stage1_violationrate = value(stage_1_ViolationRate);
        pd.stage1_timeoutrate = value(stage_1_TimeoutRate);

        pd.stage2_trials_total = value(stage_2_Trials);
        pd.stage2_trials_today = value(stage_2_TrialsToday);
        pd.stage2_trials_valid = value(stage_2_TrialsValid); 
        pd.stage2_violationrate = value(stage_2_ViolationRate);
        pd.stage2_timeoutrate = value(stage_2_TimeoutRate);

        pd.stage3_trials_total = value(stage_3_Trials);
        pd.stage3_trials_today = value(stage_3_TrialsToday);
        pd.stage3_trials_valid = value(stage_3_TrialsValid); 
        pd.stage3_violationrate = value(stage_3_ViolationRate);
        pd.stage3_timeoutrate = value(stage_3_TimeoutRate);

        pd.stage4_trials_total = value(stage_4_Trials);
        pd.stage4_trials_today = value(stage_4_TrialsToday);
        pd.stage4_trials_valid = value(stage_4_TrialsValid); 
        pd.stage4_violationrate = value(stage_4_ViolationRate);
        pd.stage4_timeoutrate = value(stage_4_TimeoutRate);

        pd.stage5_trials_total = value(stage_5_Trials);
        pd.stage5_trials_today = value(stage_5_TrialsToday);
        pd.stage5_trials_valid = value(stage_5_TrialsValid); 
        pd.stage5_violationrate = value(stage_5_ViolationRate);
        pd.stage5_timeoutrate = value(stage_5_TimeoutRate);

        pd.stage6_trials_total = value(stage_6_Trials);
        pd.stage6_trials_today = value(stage_6_TrialsToday);
        pd.stage6_trials_valid = value(stage_6_TrialsValid); 
        pd.stage6_violationrate = value(stage_6_ViolationRate);
        pd.stage6_timeoutrate = value(stage_6_TimeoutRate);

        pd.stage7_trials_total = value(stage_7_Trials);
        pd.stage7_trials_today = value(stage_7_TrialsToday);
        pd.stage7_trials_valid = value(stage_7_TrialsValid); 
        pd.stage7_violationrate = value(stage_7_ViolationRate);
        pd.stage7_timeoutrate = value(stage_7_TimeoutRate);

        pd.stage8_trials_total = value(stage_8_Trials);
        pd.stage8_trials_today = value(stage_8_TrialsToday);
        pd.stage8_trials_valid = value(stage_8_TrialsValid); 
        pd.stage8_violationrate = value(stage_8_ViolationRate);
        pd.stage8_timeoutrate = value(stage_8_TimeoutRate);
        
                
        if nargout > 0
            x = pd;
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
        if value(SummaryShow) == 1
            set(value(myfig), 'Visible', 'on');            
        else
            set(value(myfig), 'Visible', 'off');
        end

end

end

