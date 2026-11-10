function recipients = Sound2AFC_crash_recipients(experimenter, ratname)
% recipients = Sound2AFC_crash_recipients(experimenter, ratname)
%
% Email addresses to notify when a Sound2AFC session run by experimenter
% crashes, read from the Sound2AFC crash email Google Sheet (columns
% Person, Email). experimenter is matched against Person, ignoring case and
% spaces. An Email cell may hold several addresses separated by commas or
% semicolons. Returns {} if nobody is listed.
%
% Each successful download is cached next to this file (the cache holds
% email addresses and is git-ignored); if the download fails the cached copy
% is used. Problems are logged to the rat's Sound2AFC_problem_log.csv
% (ratname is only used for that).

recipients = {};
sheet_url = ['https://docs.google.com/spreadsheets/d/' ...
    '1JZAlK6hL8q-O9vNhAjwugU1gPW15vXzWDEvMS6bpvBg/export?format=csv'];
cache_file = fullfile(fileparts(mfilename('fullpath')), 'Sound2AFC_crash_emails_cache.csv');

try
    table_text = webread(sheet_url, weboptions('ContentType', 'text', 'Timeout', 15));
    try %#ok<TRYNC>
        fid = fopen(cache_file, 'w');
        fwrite(fid, table_text, 'char');
        fclose(fid);
    end
catch ME
    if ~exist(cache_file, 'file')
        Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
            'Could not download crash email sheet and no cached copy exists; no crash email sent', ME);
        return;
    end
    Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
        'Could not download crash email sheet; used cached copy', ME);
    table_text = fileread(cache_file);
end

person_col = [];
email_col = [];
lines = regexp(table_text, '\r?\n', 'split');
for i = 1:numel(lines)
    cells = csv_split(lines{i});
    if all(cellfun(@isempty, cells)), continue; end   % blank row

    if isempty(person_col)
        % First non-blank row is the header
        keys = lower(regexprep(cells, '[^A-Za-z0-9]', ''));
        person_col = find(strcmp(keys, 'person'), 1);
        email_col = find(strcmp(keys, 'email'), 1);
        if isempty(person_col) || isempty(email_col)
            Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
                'Crash email sheet needs "Person" and "Email" columns; no crash email sent');
            return;
        end
        continue;
    end

    if numel(cells) < max(person_col, email_col), continue; end
    if strcmpi(regexprep(cells{person_col}, '\s', ''), regexprep(experimenter, '\s', ''))
        recipients = [recipients, regexp(cells{email_col}, '[^\s,;]+@[^\s,;]+', 'match')]; %#ok<AGROW>
    end
end

if isempty(recipients)
    Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
        sprintf('No email for "%s" in crash email sheet; no crash email sent', experimenter));
end
end


function cells = csv_split(ln)
% Split one CSV line into trimmed cells, respecting double-quoted cells
% (Google quotes a cell that contains a comma)
cells = {};
cur = '';
in_quotes = false;
k = 1;
while k <= length(ln)
    c = ln(k);
    if in_quotes
        if c == '"'
            if k < length(ln) && ln(k+1) == '"'
                cur(end+1) = '"'; %#ok<AGROW>
                k = k + 1;
            else
                in_quotes = false;
            end
        else
            cur(end+1) = c; %#ok<AGROW>
        end
    elseif c == '"'
        in_quotes = true;
    elseif c == ','
        cells{end+1} = strtrim(cur); %#ok<AGROW>
        cur = '';
    else
        cur(end+1) = c; %#ok<AGROW>
    end
    k = k + 1;
end
cells{end+1} = strtrim(cur);
end
