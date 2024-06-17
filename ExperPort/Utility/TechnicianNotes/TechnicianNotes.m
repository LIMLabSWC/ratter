function [varargout] = TechnicianNotes(varargin) %#ok<STOUT>

if nargin>=1
    action = varargin{1};
else
    error('No arguments specified');
end

persistent GUI_NAME;
persistent TECH_NOTES_LOCAL;
persistent TECH_NOTES_LOCAL_ratsnotrun;
persistent HANDLES;
persistent DEFAULT_SESSION_DATE;

switch action
    %% CASE init
    case 'init'
        %This section initializes the GUI, sets element callbacks
        %e.g. rigtester('init');
        error(nargchk(1, 1, nargin, 'struct'));
        
        GUI_NAME = 'TECHNICIAN_NOTES_WINDOW';
        TECH_NOTES_LOCAL = struct('sessid', [], 'technotes', []);
        TECH_NOTES_LOCAL = TECH_NOTES_LOCAL([]);
        TECH_NOTES_LOCAL = TECH_NOTES_LOCAL(:);
        TECH_NOTES_LOCAL_ratsnotrun = struct('rigname', [], 'ratname', [], 'technotes', [], 'sessiondate', []);
        TECH_NOTES_LOCAL_ratsnotrun = TECH_NOTES_LOCAL_ratsnotrun([]);
        TECH_NOTES_LOCAL_ratsnotrun = TECH_NOTES_LOCAL_ratsnotrun(:);
        
        
        % Step 1: Enter Technician details and session date
        prompt = {'Enter your initials:';
            'Enter the session date:'};
        dlg_title = 'Technician Notes';
        num_lines = 1;
        defAns = {'', datestr(now, 'yyyy-mm-dd')};
        options.WindowStyle = 'modal';
        answer = inputdlg(prompt, dlg_title, num_lines, defAns, options);
        is_answer_valid = false;
        while(~is_answer_valid && ~isempty(answer))
            try
                answer = strtrim(answer);
                if ~ischar(answer{1}) || isempty(answer{1})
                    error('Invalid initials');
                end
                datenum_value = datenum(answer{2});
                is_answer_valid = true;
            catch %#ok<CTCH>
                waitfor(errordlg('ERROR: Invalid input. Try again'));
                answer = inputdlg(prompt, dlg_title, num_lines, defAns, options);
            end
        end
        
        if isempty(answer)
            fprintf([datestr(now) ' - ' mfilename ' - Cancelled by user.']);
        else
            %Cancel was not pressed
            initials = upper(answer{1});
            DEFAULT_SESSION_DATE = datestr(datenum_value, 'yyyy-mm-dd');
            
            %% GUI ELEMENTS SECTION
            %TECHNICIAN_NOTES_WINDOW
            figure('WindowStyle', 'normal', ...
                'Units', 'normalized', ...
                'Name', GUI_NAME, ...
                'Visible', 'on', ...
                'Menubar', 'none', ...
                'Resize', 'on', ...
                'Position', [0.27031     0.20667     0.44323     0.45917]);
            
            %textNotesHeader
            uicontrol('Units', 'normalized', ...
                'BackgroundColor', 'cyan', ...
                'FontSize', 13.0, ...
                'Tag', 'textNotesHeader', ...
                'String', 'Notes', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'center', ...
                'Position', [0.64512     0.72595     0.29495    0.047187]);
            
            %textRatHeader
            uicontrol('Units', 'normalized', ...
                'BackgroundColor', 'cyan', ...
                'FontSize', 13.0, ...
                'Tag', 'textRatHeader', ...
                'String', 'Rat', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'center', ...
                'Position', [0.35135     0.72595     0.23619    0.047187]);
            
            %textSessionID
            uicontrol('Units', 'normalized', ...
                'BackgroundColor', 'yellow', ...
                'FontSize', 9.0, ...
                'Style', 'text', ...
                'Tag', 'textSessionID', ...
                'HorizontalAlignment', 'left', ...
                'String', 'Session ID:', ...
                'Visible', 'on', ...
                'Position', [0.057647     0.16152     0.17765    0.036298]);
            
            %textRigID
            uicontrol('Units', 'normalized', ...
                'BackgroundColor', 'yellow', ...
                'FontSize', 9.0, ...
                'Tag', 'textRigID', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'left', ...
                'String', 'Rig ID:', ...
                'Visible', 'on', ...
                'Position', [0.057647     0.12523     0.17765    0.036298]);
            
            
            %textRat
            uicontrol('Style', 'text', ...
                'Units', 'normalized', ...
                'BackgroundColor', 'yellow', ...
                'FontSize', 9.0, ...
                'Tag', 'textRat', ...
                'HorizontalAlignment', 'left', ...
                'String', 'Rat:', ...
                'Visible', 'on', ...
                'Position', [0.057647    0.088929     0.17765    0.036298]);
            
            %textRigIDHeader
            uicontrol('Units', 'normalized', ...
                'BackgroundColor', 'cyan', ...
                'FontSize', 13.0, ...
                'Tag', 'textRigIDHeader', ...
                'String', 'Rig ID', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'center', ...
                'Position', [0.057579     0.72414     0.23619    0.047187]);
            
            %editInitials
            uicontrol('Units', 'normalized', ...
                'FontSize', 12.0, ...
                'Tag', 'editInitials', ...
                'Enable', 'inactive', ...
                'Style', 'edit', ...
                'String', initials, ...
                'HorizontalAlignment', 'center', ...
                'Position', [0.23384     0.90744     0.11868    0.052632]);
            
            %textTechnicianNotesHeader
            uicontrol('Units', 'normalized', ...
                'FontSize', 15.0, ...
                'Tag', 'textTechnicianNotesHeader', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'center', ...
                'String', 'TECHNICIAN NOTES', ...
                'Position', [0.057579     0.85481     0.88249    0.052632]);
            
            %btnSubmit
            uicontrol('Units', 'normalized', ...
                'Tag', 'btnSubmit', ...
                'FontSize', 12.0, ...
                'HorizontalAlignment', 'center', ...
                'Style', 'pushbutton', ...
                'String', 'Submit', ...
                'Callback', [mfilename '(''btnSubmitCallback'')'], ...
                'Position', [0.41011    0.090744     0.17744    0.092559]);
            
            %editNotes
            uicontrol('Units', 'normalized', ...
                'Tag', 'editNotes', ...
                'FontName', 'monospaced', ...
                'BackgroundColor', 'white', ...
                'FontSize', 12.0, ...
                'HorizontalAlignment', 'left', ...
                'Style', 'edit', ...
                'Max', 99, ...
                'Callback', [mfilename '(''editNotesCallback'')'], ...
                'Position', [0.64512     0.27223     0.29377     0.45372]);
            
            
            %editSessionDate
            uicontrol('Style', 'edit', ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Tag', 'editSessionDate', ...
                'HorizontalAlignment', 'center', ...
                'Enable', 'on', ...
                'String', DEFAULT_SESSION_DATE, ...
                'FontSize', 12.0, ...
                'Callback', [mfilename '(''editSessionDateCallback'')'], ...
                'Position', [0.056404     0.90744     0.17744    0.052632]);
            
            %lbxRat
            uicontrol('Tag', 'lbxRat', ...
                'Units', 'normalized', ...
                'Style', 'listbox', ...
                'FontSize', 14.0, ...
                'Max', 1, ...
                'String', {''}, ...
                'Value', 1, ...
                'Callback', [mfilename '(''lbxRatCallback'')'], ...
                'Position', [0.35135     0.27223     0.23502     0.45372]);
            
            %lbxRig
            uicontrol('Tag', 'lbxRig', ...
                'Units', 'normalized', ...
                'Style', 'listbox', ...
                'FontSize', 14.0, ...
                'Max', 1, ...
                'String', {''}, ...
                'Value', 1, ...
                'Callback', [mfilename '(''lbxRigCallback'')'], ...
                'Position', [0.057579     0.27042     0.23502     0.45554]);
            
            %btnRefresh
            uicontrol('Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Tag', 'btnRefresh', ...
                'String', 'REFRESH', ...
                'TooltipString', 'Retrieves all tech notes from the database and erases local technotes', ...
                'Callback', [mfilename '(''btnRefreshCallback'')'], ...
                'Position', [0.90012     0.93466    0.081081    0.039927]);
            
            
            HANDLES = guihandles(gcf);
            
            
            %% Initializing listbox content
            feval(mfilename, 'refresh_lbxRig');
            feval(mfilename, 'refresh_lbxRat');
            feval(mfilename, 'refresh_editNotes');
        end
        
        %% CASE editSessionDateCallback
    case 'editSessionDateCallback'
        try
            datenum_val = datenum(get(HANDLES.editSessionDate, 'String'));
            set(HANDLES.editSessionDate, 'String', datestr(datenum_val, 'yyyy-mm-dd'));
        catch %#ok<CTCH>
            waitfor(errordlg('ERROR: Invalid date entered. Reverting back to default date.'));
            set(HANDLES.editSessionDate, 'String', DEFAULT_SESSION_DATE);
        end
        feval(mfilename, 'btnRefreshCallback');
        
        %% CASE refresh_lbxRig
    case 'refresh_lbxRig'
        
        %Convention: We need to use the string "Rig##"
        sqlstr = 'SELECT MAX(rig) AS maxrig FROM ratinfo.schedule';
        data.maxrig = bdata(sqlstr);
        riglist = cell(data.maxrig, 1);
        for ctr = 1:data.maxrig
            rig_id_str = num2str(ctr);
            if length(rig_id_str)==1
                rig_id_str = ['0' rig_id_str]; %#ok<AGROW>
            end
            riglist{ctr} = ['Rig' rig_id_str];
        end
        set(HANDLES.lbxRig, 'Value', 1);
        set(HANDLES.lbxRig, 'String', riglist);
        
        
        %% CASE refresh_lbxRat
    case 'refresh_lbxRat'
        selected_rig = get(HANDLES.lbxRig, 'Value');
        lbxRig_String = getascell(HANDLES.lbxRig, 'String');
        rig_id_selected = regexprep(lbxRig_String{selected_rig}, '[^\d+]', '');
        session_date = datestr(get(HANDLES.editSessionDate, 'String'), 'yyyy-mm-dd');
        
        %Not using distinct, to prepare for the possibility of one rat
        %running in multiple sessions on the same rig
        sqlstr = ['SELECT TRIM(ratname) AS ratname FROM bdata.sess_started WHERE sessiondate="' session_date '" AND hostname="' lbxRig_String{selected_rig} '" ORDER BY starttime'];
        data.ratname = bdata(sqlstr);
        
        for ctr = 1:length(data.ratname)
            sqlstr = ['SELECT DISTINCT timeslot FROM ratinfo.schedule WHERE date="' session_date '" AND ratname="' data.ratname{ctr} '";'];
            data.timeslot = bdata(sqlstr);
            if ~isempty(data.timeslot)
                for ctr2 = 1:length(data.timeslot)
                    data.ratname{ctr} = ['Session ' num2str(data.timeslot(ctr2)) filesep data.ratname{ctr}];
                end
            end
        end
        
        ctr2 = 1;
        for ctr = 2:length(data.ratname)
            curr_ratname = regexprep(data.ratname{ctr}, '\(\d+\)', '');
            %curr_ratname = regexprep(curr_ratname, '\s+', '');
            %curr_ratname = curr_ratname(find(curr_ratname==separator, 1, 'last')+1:end);
            prev_ratname = regexprep(data.ratname{ctr-1}, '\(\d+\)', '');
            %prev_ratname = regexprep(prev_ratname, '\s+', '');
            %prev_ratname = prev_ratname(find(prev_ratname==separator, 1, 'last')+1:end);
            if strcmp(curr_ratname, prev_ratname)
                ctr2 = ctr2 + 1;
                data.ratname{ctr} = [data.ratname{ctr} '(' num2str(ctr2) ')'];
                data.ratname{ctr-1} = [data.ratname{ctr-1} '(' num2str(ctr2-1) ')'];
            else
                ctr2 = 1;
            end
        end
        
        
        %Now to get the list of rats that did not run at all
        %This can be obtained by looking at the ratinfo.schedule table and
        %the sess_started table. The rats that were present in the
        %ratinfo.schedule table and not present in the sess_started table
        %for a particular day are the rats that were not run at all.
        sqlstr = ['SELECT DISTINCT ratname FROM ratinfo.schedule WHERE date="' session_date '" AND rig=' rig_id_selected ...
            ' AND TRIM(ratname)<>"" AND ratname IS NOT NULL ORDER BY ratname'];
        rats_that_were_supposed_to_run = bdata(sqlstr);
        sqlstr = ['SELECT DISTINCT ratname FROM bdata.sess_started WHERE sessiondate="' session_date '" AND hostname="' lbxRig_String{selected_rig} '" ' ...
            'ORDER BY ratname'];
        rats_that_actually_ran = bdata(sqlstr);
        rats_that_did_not_run = setdiff(rats_that_were_supposed_to_run, rats_that_actually_ran);
        if ~isempty(rats_that_did_not_run)
            data.ratname = [data.ratname; rats_that_did_not_run(:)];
        end
        
        set(HANDLES.lbxRat, 'Value', 1);
        if ~isempty(data.ratname)
            set(HANDLES.lbxRat, 'String', data.ratname);
        else
            set(HANDLES.lbxRat, 'String', {''});
        end
        
        
        %% CASE lbxRigCallback
    case 'lbxRigCallback'
        set(HANDLES.lbxRig, 'Enable', 'off');
        set(HANDLES.lbxRat, 'Enable', 'off');
        set(HANDLES.editNotes, 'Enable', 'off');
        drawnow;
        uicontrol(HANDLES.lbxRig);
        feval(mfilename, 'refresh_lbxRat');
        feval(mfilename, 'refresh_editNotes');
        set(HANDLES.editNotes, 'Enable', 'on');
        set(HANDLES.lbxRat, 'Enable', 'on');
        set(HANDLES.lbxRig, 'Enable', 'on');
        drawnow;
        uicontrol(HANDLES.lbxRig);
        
        
        %% CASE lbxRatCallback
    case 'lbxRatCallback'
        set(HANDLES.lbxRig, 'Enable', 'off');
        set(HANDLES.lbxRat, 'Enable', 'off');
        set(HANDLES.editNotes, 'Enable', 'off');
        drawnow;
        uicontrol(HANDLES.lbxRat);
        feval(mfilename, 'refresh_editNotes');
        set(HANDLES.editNotes, 'Enable', 'on');
        set(HANDLES.lbxRat, 'Enable', 'on');
        set(HANDLES.lbxRig, 'Enable', 'on');
        drawnow;
        uicontrol(HANDLES.lbxRat);
        
        
        %% CASE btnRefreshCallback
    case 'btnRefreshCallback'
        TECH_NOTES_LOCAL = TECH_NOTES_LOCAL([]);
        TECH_NOTES_LOCAL_ratsnotrun = TECH_NOTES_LOCAL_ratsnotrun([]);
        
        set(HANDLES.lbxRig, 'Enable', 'off');
        set(HANDLES.lbxRat, 'Enable', 'off');
        set(HANDLES.editNotes, 'Enable', 'off');
        drawnow;
        feval(mfilename, 'refresh_lbxRig');
        feval(mfilename, 'refresh_lbxRat');
        feval(mfilename, 'refresh_editNotes');
        set(HANDLES.editNotes, 'Enable', 'on');
        set(HANDLES.lbxRat, 'Enable', 'on');
        set(HANDLES.lbxRig, 'Enable', 'on');
        drawnow;
        
        %% CASE editNotesCallback
    case 'editNotesCallback'
        lbxRig_String = get(HANDLES.lbxRig, 'String');
        rigname = lbxRig_String{get(HANDLES.lbxRig, 'Value')};
        lbxRat_String = get(HANDLES.lbxRat, 'String');
        lbxRat_Selection = get(HANDLES.lbxRat, 'Value');
        ratname = regexprep(lbxRat_String{lbxRat_Selection}, '\(\d+\)', '');
        pos = find(ratname==filesep, 1, 'last');
        if isempty(pos)
            pos = 0;
        end
        ratname = ratname(pos+1:end); ratname = strtrim(ratname);
        pattern = '\((?<index>\d+)\)';
        n = regexp(lbxRat_String{lbxRat_Selection}, pattern, 'names');
        if isempty(n)
            sessid_vector_index = 1;
        else
            sessid_vector_index = eval(n.index);
        end
        technotes = cell2str(strtrim(getascell(HANDLES.editNotes, 'String')), sprintf('\n'));
        
        %Get sessid
        sqlstr = ['SELECT DISTINCT sessid FROM bdata.sess_started WHERE sessiondate="' datestr(get(HANDLES.editSessionDate, 'String'), 'yyyy-mm-dd') '" AND hostname="' rigname '" AND ratname="' ratname '"'];
        data.sessid = bdata(sqlstr);
        if ~isempty(data.sessid)
            data.sessid = data.sessid(sessid_vector_index);
        end
        
        
        
        %If sessid is empty at this stage, it means that the session never
        %started
        if isempty(data.sessid)
            %Extending the size of TECH_NOTES_LOCAL_ratsnotrun
            TECH_NOTES_LOCAL_ratsnotrun(end+1).rigname = rigname;
            TECH_NOTES_LOCAL_ratsnotrun(end).ratname = ratname;
            TECH_NOTES_LOCAL_ratsnotrun(end).technotes = technotes;
            TECH_NOTES_LOCAL_ratsnotrun(end).sessiondate = get(HANDLES.editSessionDate, 'String');
        else
            %Extending the size of TECH_NOTES_LOCAL while replacing
            %previous entries for the given session id
            if ~isempty(TECH_NOTES_LOCAL)
                [TECH_NOTES_LOCAL_sessid{1:length(TECH_NOTES_LOCAL)}] = deal(TECH_NOTES_LOCAL.sessid);
            else
                TECH_NOTES_LOCAL_sessid = {};
            end
            indices = find(strcmp(num2str(data.sessid), TECH_NOTES_LOCAL_sessid));
            TECH_NOTES_LOCAL(indices) = []; %#ok<FNDSB> %Erasing previous entry
            TECH_NOTES_LOCAL(end+1).sessid = num2str(data.sessid);
            TECH_NOTES_LOCAL(end).technotes = technotes;
        end
        
        
        %% CASE refresh_editNotes
    case 'refresh_editNotes'
        %If possible, obtain tech notes from TECH_NOTES_LOCAL
        
        %Step 1: Get all applicable session IDs based on the selections in
        %lbxRig and lbxRat
        session_date = datestr(get(HANDLES.editSessionDate, 'String'), 'yyyy-mm-dd');
        lbxRig_Selection = get(HANDLES.lbxRig, 'Value');
        lbxRig_String = strtrim(get(HANDLES.lbxRig, 'String'));
        lbxRig_String_Selected = lbxRig_String{lbxRig_Selection};
        lbxRat_Selection = get(HANDLES.lbxRat, 'Value');
        lbxRat_String = get(HANDLES.lbxRat, 'String');
        lbxRat_String_Selected = lbxRat_String{lbxRat_Selection};
        
        %The index of sessid to be used is specified in
        %<Session_num\ratname>(2/3/4...). If not, the index is simply 1.
        ratname = regexprep(lbxRat_String_Selected, '\(\d+\)', '');
        pos = find(ratname==filesep, 1, 'last');
        if isempty(pos)
            pos = 0;
        end
        ratname = ratname(pos+1:end);
        ratname = regexprep(ratname, '\s+', '');
        rigname = lbxRig_String_Selected;
        pattern = '\((?<index>\d+)\)';
        n = regexp(lbxRat_String_Selected, pattern, 'names');
        if isempty(n)
            sessid_vector_index = 1;
        else
            sessid_vector_index = eval(n.index);
        end
        sqlstr = ['SELECT sessid FROM bdata.sess_started WHERE sessiondate="' session_date '" AND hostname="' rigname '" AND ratname="' ratname '"'];
        data.sessid = bdata(sqlstr);
        
        %Update status
        set(HANDLES.textNotesHeader, 'String', ['Notes (' rigname ', ' ratname ')']);
        set(HANDLES.textRigID, 'String', ['Rig ID: ' rigname]);
        set(HANDLES.textRat, 'String', ['Rat: ' ratname]);
        if ~isempty(data.sessid)
            set(HANDLES.textSessionID, 'String', ['Session ID: ' num2str(data.sessid(sessid_vector_index))]);
        else
            set(HANDLES.textSessionID, 'String', 'Session ID:');
        end
        
        if ~isempty(data.sessid)
            data.sessid = data.sessid(sessid_vector_index);
            if ~isempty(TECH_NOTES_LOCAL)
                [TECH_NOTES_LOCAL_sessid{1:length(TECH_NOTES_LOCAL)}] = deal(TECH_NOTES_LOCAL.sessid);
            else
                TECH_NOTES_LOCAL_sessid = {};
            end
            if any(strcmp(num2str(data.sessid), TECH_NOTES_LOCAL_sessid)) && ...
                    ~isempty(strtrim(TECH_NOTES_LOCAL(find(strcmp(num2str(data.sessid), TECH_NOTES_LOCAL_sessid), 1, 'first')).technotes))
                index = find(strcmp(num2str(data.sessid), TECH_NOTES_LOCAL_sessid), 1, 'first');
                set(HANDLES.editNotes, 'String', strtrim(TECH_NOTES_LOCAL(index).technotes));
            else
                %Finally, retrieve the tech notes for the given sessid
                sqlstr = ['SELECT TRIM(technotes) FROM bdata.technician_notes_tbl WHERE sessiondate="' session_date '" AND sessid=' num2str(data.sessid)];
                data.technotes = cellstr(bdata(sqlstr));
                set(HANDLES.editNotes, 'String', data.technotes);
            end
        else%The session never started
            %This information should thus be retrieved from
            %TECH_NOTES_LOCAL_ratsnotrun
            found = false;
            for ctr = length(TECH_NOTES_LOCAL_ratsnotrun):-1:1
                if strcmp(TECH_NOTES_LOCAL_ratsnotrun(ctr).rigname, rigname) && ...
                        strcmp(TECH_NOTES_LOCAL_ratsnotrun(ctr).ratname, ratname) && ...
                        strcmp(TECH_NOTES_LOCAL_ratsnotrun(ctr).sessiondate, session_date) && ...
                        ~isempty(strtrim(TECH_NOTES_LOCAL_ratsnotrun(ctr).technotes))
                    set(HANDLES.editNotes, 'String', TECH_NOTES_LOCAL_ratsnotrun(ctr).technotes);
                    found = true;
                    break;
                end
            end
            
            if ~found
                %Retrieve the tech notes for the given dateval, rigname,
                %and ratname
                rigid_str = regexprep(rigname, '[^\d+]', '');
                sqlstr = ['SELECT TRIM(technotes) FROM bdata.technician_notes_tbl ' ...
                    'WHERE sessiondate="' session_date '" AND rig_id=' rigid_str ' AND ratname="' ratname '"'];
                data.technotes = cellstr(bdata(sqlstr));
                set(HANDLES.editNotes, 'String', data.technotes);
            end
            
        end
        
        
        
        %% CASE btnSubmitCallback
    case 'btnSubmitCallback'
        answer = questdlg('Are you sure?', 'Are you sure?', 'YES', 'NO', 'NO');
        if strcmpi(answer, 'YES')
            session_date = datestr(get(HANDLES.editSessionDate, 'String'), 'yyyy-mm-dd');
            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            tech_initials = get(HANDLES.editInitials, 'String');
            found_data_to_submit = false;
            for ctr = 1:length(TECH_NOTES_LOCAL)
                if ~isempty(TECH_NOTES_LOCAL(ctr).technotes)
                    found_data_to_submit = true;
                    sessid = TECH_NOTES_LOCAL(ctr).sessid;
                    technotes = TECH_NOTES_LOCAL(ctr).technotes;
                    %If sessid does not exist, insert, else, update
                    sqlstr = ['SELECT sessid FROM bdata.technician_notes_tbl WHERE sessid=' sessid];
                    data.sessid = bdata(sqlstr);
                    if isempty(data.sessid)
                        sqlstr = ['SELECT hostname, ratname FROM bdata.sess_started WHERE sessid=' sessid];
                        [data.hostname, data.ratname] = bdata(sqlstr); %Rig##
                        rig_id_str = num2str(eval(regexprep(data.hostname{1}, '[^\d+]', '')));
                        ratname = data.ratname{1};
                        sqlstr = ['INSERT INTO bdata.technician_notes_tbl (tech_initials, rig_id, ratname, timestamp, sessid, technotes, sessiondate) ' ...
                            'VALUES ("' tech_initials '", ' rig_id_str ', "' ratname '", "' timestamp '", ' sessid ', "' technotes '", "' session_date '")'];
                    else
                        sqlstr = ['CALL update_tech_notes(' sessid ', "' technotes '")'];
                    end
                    bdata(sqlstr);
                end
            end
            for ctr = 1:length(TECH_NOTES_LOCAL_ratsnotrun)
                if ~isempty(TECH_NOTES_LOCAL_ratsnotrun(ctr).technotes)
                    found_data_to_submit = true;
                    ratname = TECH_NOTES_LOCAL_ratsnotrun(ctr).ratname;
                    rigname = TECH_NOTES_LOCAL_ratsnotrun(ctr).rigname;
                    rig_id_str = num2str(eval(regexprep(rigname, '[^\d+]', '')));
                    technotes = TECH_NOTES_LOCAL_ratsnotrun(ctr).technotes;
                    sqlstr = ['INSERT INTO bdata.technician_notes_tbl (tech_initials, rig_id, ratname, timestamp, technotes, sessiondate) ' ...
                        'VALUES("' tech_initials '", ' rig_id_str ', "' ratname '", "' timestamp '", "' technotes '", "' session_date '")'];
                    bdata(sqlstr);
                end
            end
            
            if ~found_data_to_submit
                msgbox('Nothing to submit!');
            end
        end
        
        
    otherwise
        error(['Unknown action: ' action]);
        
end

end



function out = cell2str(cellarray, separator)
cellarray = cellarray(:);
cellarray = cellarray';
for ctr = 1:length(cellarray)
    if ctr<length(cellarray)
        cellarray{ctr} = [cellarray{ctr} separator];
    end
end
if ~isempty(cellarray)
    out = cell2mat(cellarray);
else
    out = '';
end
end



function out = getascell(hndl, property)
result = get(hndl, property);
if ~iscell(result)
    out = cell(size(result, 1), 1);
    for ctr = 1:size(result, 1)
        out{ctr} = result(ctr, :);
    end
else
    out = result;
end
end