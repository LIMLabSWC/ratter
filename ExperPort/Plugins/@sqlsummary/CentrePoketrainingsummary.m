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
            'hits',             get_val('hit_history');...
            'sides',            get_val('previous_sides');...
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
        
        %% Calculate Performance Metrics
        hits = hits(1:n_done_trials);
        sides = sides(1:n_done_trials);
        total_correct = nanmean(hits);
        
        try
            right_correct = nanmean(hits(sides=='r'));
            left_correct = nanmean(hits(sides=='l'));
        catch ME
            fprintf(2, 'Error calculating correct pokes\n');
            disp(ME.message);
            disp(ME.stack);
            right_correct = -1;
            left_correct = -1;
        end
        
        %% Calculate Violation Percentage
        if strncmpi('pbups', protocol, 5) && isfield(protocol_data, 'violations')
            percent_violations = mean(protocol_data.violations);
        else
            percent_violations = mean(isnan(hits));
        end
        
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
            'sessid, ', ...
            'ratname, ', ...
            'hostname, ', ...
            'experimenter, ', ...
            'endtime, ', ...
            'starttime, ', ...
            'sessiondate, ', ...
            'protocol, ', ...
            'n_done_trials, ', ...
            'total_correct, ', ...
            'right_correct, ', ...
            'left_correct, ', ...
            'percent_violations, ', ...
            'protocol_data, ', ...
            'comments, ', ...
            'data_file, ', ...
            'data_path, ', ...
            'left_pokes, ', ...
            'center_pokes, ', ...
            'right_pokes, ', ...
            'technotes, ', ...
            'IP_addr'
        ];

        valstr = [
            '"{Si}",', ...    % sessid
            '"{S}",', ...     % ratname
            '"{S}",', ...     % hostname
            '"{S}",', ...     % experimenter
            '"{S}",', ...     % endtime
            '"{S}",', ...     % starttime
            '"{S}",', ...     % sessiondate
            '"{S}",', ...     % protocol
            '"{S}",', ...     % n_done_trials
            '"{S}",', ...     % total_correct
            '"{S}",', ...     % right_correct
            '"{S}",', ...     % left_correct
            '"{S}",', ...     % percent_violations
            '"{S}",', ...     % protocol_data
            '"{S}",', ...     % comments
            '"{S}",', ...     % data_file
            '"{S}",', ...     % data_path
            '"{S}",', ...     % left_pokes
            '"{S}",', ...     % center_pokes
            '"{S}",', ...     % right_pokes
            '"{S}",', ...     % technotes
            '"{S}"'           % IP_addr
        ];



        %% Construct SQL string
        sqlstr = ['insert into sessions (' strtrim(colstr) ') values (' strtrim(valstr) ')'];

        
        %% Execute SQL Query
        bdata(sqlstr, ... 
            sessid, ... 
            ratname, ...
            hostname, ...
            experimenter, ... 
            endtime, ...
            starttime, ...
            sessiondate, ...
            protocol, ...
            n_done_trials, ...
            total_correct, ...
            right_correct, ...
            left_correct, ...
            percent_violations, ...
            protocol_data, ...
            last_comment, ...
            fl, ...
            pth, ...
            left_pokes, ...
            center_pokes, ...
            right_pokes, ...
            technotes, ...
            IP_addr ...
        );

        %% Insert Parsed Events
        bdata('insert into parsed_events values ("{S}", "{M}")', sessid, peh);

        err = 0;

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
