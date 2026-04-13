function [err] = SoundCatContextSwitchSummary(obj, varargin)
    %% Function Description
    % Sends session data to bdata.SoundCatContinuous
    % Includes global performance metrics followed by context-specific details.
    
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
            'protocol_data',    {};... % The 'psych_result' cell array
            'peh',              get_parsed_events;...
            'last_comment',     cleanup(CommentsSection(obj,'get_latest'));...
            'data_file',        SavingSection(obj,'get_data_file');...
            'technotes',        get_val('TechComment')... 
        };
        parseargs(varargin, pairs);
        
        %% Validate Rig ID
        [rigID, ~, ~] = bSettings('get','RIGS','Rig_ID');
        if ~force_send && isnan(rigID)
            err = 42; return;
        end
        
        %% Calculate Global Session Metrics
        hits = hits(1:n_done_trials);
        % Convert sides to char if they are stored as ASCII (114='r', 108='l')
        if isnumeric(sides); sides = char(sides(1:n_done_trials)); else sides = sides(1:n_done_trials); end
        
        total_correct   = nanmean(hits) * 100;
        percent_viol    = mean(isnan(hits)) * 100;
        
        try
            right_correct = nanmean(hits(sides == 'r')) * 100;
            left_correct  = nanmean(hits(sides == 'l')) * 100;
        catch
            right_correct = -1; left_correct = -1;
        end
        
        % Handle cases where no trials of a certain side occurred
        if isnan(right_correct); right_correct = 0; end
        if isnan(left_correct);  left_correct  = 0; end

        [pth, fl] = extract_path(data_file);
        
        %% Calculate Poke Counts
        left_pokes = 0; center_pokes = 0; right_pokes = 0;
        for px = 1:numel(peh)
            left_pokes = left_pokes + numel(peh(px).pokes.L);
            center_pokes = center_pokes + numel(peh(px).pokes.C);
            right_pokes = right_pokes + numel(peh(px).pokes.R);
        end
        
        sessid = getSessID(obj);
        starttime = get_starttime(sessid);
        if isempty(starttime)
            starttime = datestr(datenum(savetime)-sess_length(obj)/86400, 13);
        else
            bdata('call set_sess_ended("{Si}", "{Si}")', sessid, 1);
        end

        %% Prepare Context-Specific Data (10 variables per context)
        ctx_vals = repmat({0, 0, 0, 'NULL', 0, 0, 0, 0, 0, 0}, 1, 4);
        num_contexts = min(length(protocol_data), 4);
        for i = 1:num_contexts
            res = protocol_data(i);
            idx = (i-1)*10;
            ctx_vals{idx+1}  = res.start_trial;
            ctx_vals{idx+2}  = res.end_trial;
            ctx_vals{idx+3}  = res.valid_trials;
            ctx_vals{idx+4}  = res.distribution_type;
            ctx_vals{idx+5}  = res.calculated_boundary;
            ctx_vals{idx+6}  = res.total_hit_percent;
            ctx_vals{idx+7}  = res.total_violations_percent;
            ctx_vals{idx+8}  = res.right_correct_percent;
            ctx_vals{idx+9}  = res.left_correct_percent;
            ctx_vals{idx+10} = (res.end_trial - res.start_trial) + 1;
        end

        %% Build SQL Column String
        % General Session Data
        colstr = 'sessid, sessiondate, starttime, endtime, ratname, experimenter, protocol, hostname, IP_address, ';
        % Global Performance Metrics
        colstr = [colstr, 'n_done_trials, total_correct_pct, left_correct_pct, right_correct_pct, percent_violations, '];
        
        % Context Columns
        for i = 1:4
            c = num2str(i);
            colstr = [colstr, ...
                'ctx',c,'_start, ctx',c,'_end, ctx',c,'_valid, ctx',c,'_dist, ctx',c,'_bound, ', ...
                'ctx',c,'_hit_pct, ctx',c,'_viol_pct, ctx',c,'_R_pct, ctx',c,'_L_pct, ctx',c,'_total, '];
        end
        
        colstr = [colstr, 'datafile, datapath, centre_poke, left_poke, right_poke, comments, tech_notes'];

        % Total columns: 9 (headers) + 5 (global metrics) + 40 (contexts) + 7 (meta) = 61 placeholders
        valstr = repmat('"{S}",', 1, 60); valstr = [valstr '"{S}"'];
        sqlstr = ['insert into SoundCatContinuous (' colstr ') values (' valstr ')'];

        %% Execute SQL Update
        bdata(sqlstr, ...
            sessid, sessiondate, starttime, endtime, ratname, experimenter, protocol, hostname, IP_addr, ...
            n_done_trials, total_correct, left_correct, right_correct, percent_viol, ...
            ctx_vals{:}, ... 
            pth, fl, center_pokes, left_pokes, right_pokes, last_comment, technotes);

        fprintf('Complete session and context summary sent to SQL successfully.\n');
        
    catch ME
        fprintf(2, 'Failed to send summary to sql\n');
        disp(ME.message);
        err = 1;
        
        % Log error details
        % fprintf('Error occurred during sendsummary execution:\n');
        % fprintf('%s\n', ME.message);
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
