function Sound2AFC_log_problem(experimenter, ratname, event_type, msg, ME)
% Sound2AFC_log_problem(experimenter, ratname, event_type, msg, [ME])
%
% Appends one row to <Main_Data_Directory>/Data/<experimenter>/<ratname>/
% Sound2AFC_problem_log.csv recording a crash, failed load or warning for a
% Sound2AFC session.
%
% Columns: date, time, rig, experimenter, rat, trials_done, type, message,
% error_id, location
%
% event_type  Short label, e.g. 'crash', 'load_failed', 'warning'
% msg         What happened, in words. If ME is given its message is
%             appended.
% ME          Optional MException (or lasterror struct). Its identifier and
%             the file/line it was thrown from are recorded.
%
% Never errors: logging must not get in the way of crash handling.

try
    experimenter = strtrim(char(experimenter));
    ratname = strtrim(char(ratname));
    % Skip placeholder names (protocol opened by hand before a rat is set)
    if isempty(experimenter) || isempty(ratname) || ...
            strcmp(experimenter, 'experimenter') || strcmp(ratname, 'ratname')
        return;
    end

    error_id = '';
    location = '';
    if nargin >= 5 && ~isempty(ME)
        if isempty(msg)
            msg = ME.message;
        else
            msg = [msg ': ' ME.message];
        end
        error_id = ME.identifier;
        if ~isempty(ME.stack)
            [~, fname, ext] = fileparts(ME.stack(1).file);
            location = sprintf('%s%s line %d (%s)', fname, ext, ME.stack(1).line, ME.stack(1).name);
        end
    end

    rig = '';
    try rig = num2str(bSettings('get', 'RIGS', 'Rig_ID')); end %#ok<TRYNC>

    % Trials completed so far this session. dispatcher creates this counter
    % but hands it to the open protocol, so it's owned by Sound2AFC.
    trials_done = '';
    try %#ok<TRYNC>
        h = get_sphandle('name', '^n_done_trials$', 'owner', 'Sound2AFC');
        if ~isempty(h), trials_done = num2str(value(h{1})); end
    end

    data_dir = bSettings('get', 'GENERAL', 'Main_Data_Directory');
    rat_dir = fullfile(data_dir, 'Data', experimenter, ratname);
    if ~exist(rat_dir, 'dir'), mkdir(rat_dir); end
    log_file = fullfile(rat_dir, 'Sound2AFC_problem_log.csv');

    is_new = ~exist(log_file, 'file');
    fid = fopen(log_file, 'a');
    if fid < 0
        error('Cannot open %s', log_file);
    end
    if is_new
        fprintf(fid, 'date,time,rig,experimenter,rat,trials_done,type,message,error_id,location\n');
    end
    t = now;
    fields = {datestr(t, 'yyyy-mm-dd'), datestr(t, 'HH:MM:SS'), rig, experimenter, ...
        ratname, trials_done, event_type, msg, error_id, location};
    fprintf(fid, '%s\n', strjoin(cellfun(@csv_field, fields, 'UniformOutput', false), ','));
    fclose(fid);
catch log_ME
    warning('Sound2AFC:log_failed', 'Could not write Sound2AFC problem log: %s', log_ME.message);
end
end


function s = csv_field(s)
% Quote a value for CSV; newlines become ' | ' so each problem is one row
s = char(s);
s = regexprep(s, '\s*[\r\n]+\s*', ' | ');
s = ['"' strrep(s, '"', '""') '"'];
end
