function [err] = CentrePoketrainingsummary(obj, varargin)
    %% Function Description
    % Sends session data to the bdata.sessions table
    % By default, it tries to get data from standard plugins
    % See the pairs structure below for details
    
    %% Initialize Error Logging
    diary('sendsummary_error_log.txt');
    
    try
        %% Define Default Parameters
        pairs = {
            'force_send',      0;...
            'savetime',         get_savetime(obj);...
            'endtime',          get_endtime(obj);...
            'sessiondate',      get_sessiondate(obj);...
            'hostname',         get_rigid;...
            'IP_addr',          get_network_info;...
            'experimenter',     get_val('SavingSection_experimenter');...
            'ratname',          get_val('SavingSection_ratname');...
            'n_done_trials',    get_val('n_completed_trials');...
            'protocol',         class(obj);...
            'protocol_data',    'NULL';...
            'peh',              get_parsed_events;...
            'last_comment',     cleanup(CommentsSection(obj,'get_latest'));...
            'data_file',        SavingSection(obj,'get_data_file');...
            'technotes',        get_val('TechComment')... % Added technician comments field
        };
        parseargs(varargin, pairs);
        
        %% Validate Rig ID
        [rigID, e, m] = bSettings('get','RIGS','Rig_ID');
        if ~force_send && isnan(rigID)
            err = 42;
            return
        end
        
        %% Handle Tech Notes
        if ~ischar(technotes) || isempty(technotes)
            technotes = '';
        end
        
        %% Extract Path Information
        [pth, fl] = extract_path(data_file);
        
        %% Calculate Violation Percentage
        % if isfield(protocol_data, 'violation_rate')
        %     percent_violations = perf.violation_rate;
        % else
        %     percent_violations = [];
        % end
        % 
        %% Calculate Poke Counts
        left_pokes = 0;
        center_pokes = 0;
        right_pokes = 0;
        for px = 1:numel(peh)
            left_pokes = left_pokes + numel(peh(px).pokes.L);
            center_pokes = center_pokes + numel(peh(px).pokes.C);
            right_pokes = right_pokes + numel(peh(px).pokes.R);
        end
        
        %% Get Session ID and Start Time
        sessid = getSessID(obj);
        starttime = get_starttime(sessid); % added 20091214
        
        if isempty(starttime)
            % Compute start time if not found in sess_started table
            starttime = datestr(datenum(savetime)-sess_length(obj)/60/60/24, 13);
        else
            % Update sess_started table indicating session end
            bdata('call set_sess_ended("{Si}", "{Si}")', sessid, 1);
        end
        
        %% Define SQL columns and placeholders
        colstr = [
            'sessid, ',...
            'sessiondate, '...				DATE
            'starttime, '...				TIME
            'endtime, '...				TIME
            'ratname, '...					VARCHAR
            'experimenter, '...			VARCHAR
            'protocol, '...					VARCHAR
            'hostname, '...				VARCHAR
            'IP_address, '...				VARCHAR
            'training_stage_no, '...		 	INT
            'training_stage_name, '...		VARCHAR
            'n_done_trials, '...				INT
            'percent_violations, '...		VARCHAR
            'percent_timeout, '...			VARCHAR
            'stage1_trials_total, '...		INT
            'stage1_trials_today, '...		INT
            'stage1_trials_valid, '...		INT
            'stage1_percent_violation, '... 	VARCHAR
            'stage1_percent_timeout, '...	VARCHAR
            'stage2_trials_total, '...		INT
            'stage2_trials_today, '...		INT
            'stage2_trials_valid, '...		INT
            'stage2_percent_violation, '... 	VARCHAR
            'stage2_percent_timeout, '...	VARCHAR
            'stage3_trials_total, '...		INT
            'stage3_trials_today, '...		INT
            'stage3_trials_valid, '...		INT
            'stage3_percent_violation, '... 	VARCHAR
            'stage3_percent_timeout, '...	VARCHAR
            'stage4_trials_total, '...		INT
            'stage4_trials_today, '...		INT
            'stage4_trials_valid, '...		INT
            'stage4_percent_violation, '... 	VARCHAR
            'stage4_percent_timeout, '...	VARCHAR
            'stage5_trials_total, '...		INT
            'stage5_trials_today, '...		INT
            'stage5_trials_valid, '...		INT
            'stage5_percent_violation, '... 	VARCHAR
            'stage5_percent_timeout, '...	VARCHAR
            'stage6_trials_total, '...		INT
            'stage6_trials_today, '...		INT
            'stage6_trials_valid, '...		INT
            'stage6_percent_violation, '... 	VARCHAR
            'stage6_percent_timeout, '...	VARCHAR
            'stage7_trials_total, '...		INT
            'stage7_trials_today, '...		INT
            'stage7_trials_valid, '...		INT
            'stage7_percent_violation, '... 	VARCHAR
            'stage7_percent_timeout, '...	VARCHAR
            'stage8_trials_total, '...		INT
            'stage8_trials_today, '...		INT
            'stage8_trials_valid, '...		INT
            'stage8_percent_violation, '... 	VARCHAR
            'stage8_percent_timeout, '...	VARCHAR
            'datafile, '...					VARCHAR
            'datapath, '...				VARCHAR
            'videofile, '...					VARCHAR
            'videopath, '...				VARCHAR
            'centre_poke, '...			VARCHAR
            'left_poke, '...				VARCHAR
            'right_poke, '...				VARCHAR
            'comments, '...				VARCHAR
            'tech_notes']; % total 63 columns

            
valstr = [
            '"{Si}",', ...    % sessid
            '"{S}",', ...     % sessiondate
            '"{S}",', ...     % starttime
            '"{S}",', ...     % endtime
            '"{S}",', ...     % ratname
            '"{S}",', ...     % experimenter
            '"{S}",', ...     % protocol
            '"{S}",', ...     % hostname
            '"{S}",', ...     % IP_address
            '"{S}",', ...     % training_stage_no
            '"{S}",', ...     % training_stage_name
            '"{S}",', ...     % n_done_trials
            '"{S}",', ...     % percent_violations
            '"{S}",', ...     % percent_timeout
            '"{S}",', ...     % stage1_trials_total
            '"{S}",', ...     % stage1_trials_today
            '"{S}",', ...     % stage1_trials_valid
            '"{S}",', ...     % stage1_percent_violation
            '"{S}",', ...     % stage1_percent_timeout
            '"{S}",', ...     % stage2_trials_total
            '"{S}",', ...     % stage2_trials_today
            '"{S}",', ...     % stage2_trials_valid
            '"{S}",', ...     % stage2_percent_violation
            '"{S}",', ...     % stage2_percent_timeout
            '"{S}",', ...     % stage3_trials_total
            '"{S}",', ...     % stage3_trials_today
            '"{S}",', ...     % stage3_trials_valid
            '"{S}",', ...     % stage3_percent_violation
            '"{S}",', ...     % stage3_percent_timeout
            '"{S}",', ...     % stage4_trials_total
            '"{S}",', ...     % stage4_trials_today
            '"{S}",', ...     % stage4_trials_valid
            '"{S}",', ...     % stage4_percent_violation
            '"{S}",', ...     % stage4_percent_timeout
            '"{S}",', ...     % stage5_trials_total
            '"{S}",', ...     % stage5_trials_today
            '"{S}",', ...     % stage5_trials_valid
            '"{S}",', ...     % stage5_percent_violation
            '"{S}",', ...     % stage5_percent_timeout
            '"{S}",', ...     % stage6_trials_total
            '"{S}",', ...     % stage6_trials_today
            '"{S}",', ...     % stage6_trials_valid
            '"{S}",', ...     % stage6_percent_violation
            '"{S}",', ...     % stage6_percent_timeout
            '"{S}",', ...     % stage7_trials_total
            '"{S}",', ...     % stage7_trials_today
            '"{S}",', ...     % stage7_trials_valid
            '"{S}",', ...     % stage7_percent_violation
            '"{S}",', ...     % stage7_percent_timeout
            '"{S}",', ...     % stage8_trials_total
            '"{S}",', ...     % stage8_trials_today
            '"{S}",', ...     % stage8_trials_valid
            '"{S}",', ...     % stage8_percent_violation
            '"{S}",', ...     % stage8_percent_timeout
            '"{S}",', ...     % datafile
            '"{S}",', ...     % datapath
            '"{S}",', ...     % video_path
            '"{S}",', ...     % videofile
            '"{S}",', ...     % left_pokes
            '"{S}",', ...     % center_pokes
            '"{S}",', ...     % right_pokes
            '"{S}",', ...     % comments
            '"{S}",', ...     % technotes
        ];


        %% Construct SQL string
        sqlstr = ['insert into CentrePokeTraining (' strtrim(colstr) ') values (' strtrim(valstr) ')'];

        
        %% Execute SQL Query
        bdata(sqlstr, ... 
            sessid, ... 
            sessiondate, ...
            starttime, ...
            endtime, ...
            ratname, ...
            experimenter, ... 
            protocol, ...
            hostname, ...
            IP_addr, ...
            protocol_data.stage_no, ...
            protocol_data.stage_name, ...
            n_done_trials, ...
            protocol_data.violation_percent, ...
            protocol_data.timeout_percent, ...
            protocol_data.stage1_trials_total, ...
            protocol_data.stage1_trials_today, ...
            protocol_data.stage1_trials_valid, ...
            protocol_data.stage1_violationrate, ...
            protocol_data.stage1_timeoutrate, ...
            protocol_data.stage2_trials_total, ...
            protocol_data.stage2_trials_today, ...
            protocol_data.stage2_trials_valid, ...
            protocol_data.stage2_violationrate, ...
            protocol_data.stage2_timeoutrate, ...
            protocol_data.stage3_trials_total, ...
            protocol_data.stage3_trials_today, ...
            protocol_data.stage3_trials_valid, ...
            protocol_data.stage3_violationrate, ...
            protocol_data.stage3_timeoutrate, ...
            protocol_data.stage4_trials_total, ...
            protocol_data.stage4_trials_today, ...
            protocol_data.stage4_trials_valid, ...
            protocol_data.stage4_violationrate, ...
            protocol_data.stage4_timeoutrate, ...
            protocol_data.stage5_trials_total, ...
            protocol_data.stage5_trials_today, ...
            protocol_data.stage5_trials_valid, ...
            protocol_data.stage5_violationrate, ...
            protocol_data.stage5_timeoutrate, ...
            protocol_data.stage6_trials_total, ...
            protocol_data.stage6_trials_today, ...
            protocol_data.stage6_trials_valid, ...
            protocol_data.stage6_violationrate, ...
            protocol_data.stage6_timeoutrate, ...
            protocol_data.stage7_trials_total, ...
            protocol_data.stage7_trials_today, ...
            protocol_data.stage7_trials_valid, ...
            protocol_data.stage7_violationrate, ...
            protocol_data.stage7_timeoutrate, ...
            protocol_data.stage8_trials_total, ...
            protocol_data.stage8_trials_today, ...
            protocol_data.stage8_trials_valid, ...
            protocol_data.stage8_violationrate, ...
            protocol_data.stage8_timeoutrate, ...
            pth, ...
            fl, ...
            perf.video_filepath, ...
            perf.CP_Duration, ....
            left_pokes, ...
            center_pokes, ...
            right_pokes, ...
            last_comment, ...
            technotes...
            );

        % Log successful execution
        fprintf('No errors encountered during sendsummary execution.\n');
        

    catch ME
        fprintf(2, 'Failed to send summary to sql\n');
        disp(ME.message);
        disp(ME.stack);
        err = 1;
        
        % Log error details
        fprintf('Error occurred during sendsummary execution:\n');
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.stack);
    end
    
    diary off;
end

%% Helper Functions
function y = get_val(x)
    y = get_sphandle('fullname', x);
    if isempty(y)
        y = '';
    else
        y = value(y{1});
    end
end

function y = get_parsed_events
    y = get_sphandle('fullname', 'ProtocolsSection_parsed_events');
    y = cell2mat(get_history(y{1}));
end

function y = sess_length(obj)
    % Estimate session length
    GetSoloFunctionArgs(obj);
    
    try
        st = parsed_events_history{1}.states; %#ok<USENS>
        ss = st.starting_state;
        es = st.starting_state;
        eval(['ST = min(min(st.', ss, '));']);
        eval(['ET = max(max(st.', es, '));']);
        
        D1 = round(ET - ST);
        
        pt = get_sphandle('name', 'prot_title');
        [Ts, Te] = get_times_from_prottitle(value(pt{1}));
        Ts = [Ts, ':00'];
        Te = [Te, ':00'];
        
        Dt = timediff(Ts, Te, 2);
        y = Dt + D1;
    catch ME
        showerror; % Assuming showerror is a function that displays errors
        fprintf(2, 'Error calculating session length\n');
        disp(ME.message);
        disp(ME.stack);
    end
end

function y = cleanup(M)
    try
        y = strtrim(sprintf('%s', M'));
    catch
        y = '';
    end
end

function [p, f] = extract_path(s)
    last_fs = find(s == filesep, 1, 'last' );
    p = s(1:last_fs);
    f = s(last_fs+1:end);
end

function y = get_savetime(obj)
    [x, x, y] = SavingSection(obj, 'get_info');
    if y == '_'
        y = datestr(now);
    end
end

function y = get_endtime(obj)
    [x, x, savetime] = SavingSection(obj, 'get_info');
    if savetime == '_'
        y = datestr(now, 13);
    else
        y = datestr(savetime, 13);
    end
end

function y = get_starttime(sessid)
    y = bdata('select starttime from sess_started where sessid="{Si}"', sessid);
    if ~isempty(y)
        y = y{1};
    end
end

function y = get_sessiondate(obj)
    [x, x, savetime] = SavingSection(obj, 'get_info');
    if savetime == '_'
        y = datestr(now, 29);
    else
        y = datestr(savetime, 29);
    end
end

function y = get_rigid
    y = getRigID;
    if isnan(y)
        y = 'Unknown';
    elseif isnumeric(y)
        y = sprintf('Rig%02d', y);
    end
end
