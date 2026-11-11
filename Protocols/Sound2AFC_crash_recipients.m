function recipients = Sound2AFC_crash_recipients(experimenter, ratname)
% recipients = Sound2AFC_crash_recipients(experimenter, ratname)
%
% Email addresses to notify when any Sound2AFC session crashes: every
% address in the Email column of @Sound2AFC/Sound2AFC_crash_emails.csv
% (the Person column is just a label). An Email cell may hold several
% addresses separated by commas or semicolons; duplicates are sent once.
% Returns {} if nobody is listed.
%
% Problems are logged to the rat's Sound2AFC_problem_log.csv (experimenter
% and ratname are only used for that).

recipients = {};
email_file = fullfile(fileparts(mfilename('fullpath')), '@Sound2AFC', 'Sound2AFC_crash_emails.csv');
if ~exist(email_file, 'file')
    Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
        sprintf('Crash email file not found (%s); no crash email sent', email_file));
    return;
end
table_text = fileread(email_file);

email_col = [];
lines = regexp(table_text, '\r?\n', 'split');
for i = 1:numel(lines)
    cells = csv_split(lines{i});
    if all(cellfun(@isempty, cells)), continue; end   % blank row

    if isempty(email_col)
        % First non-blank row is the header
        keys = lower(regexprep(cells, '[^A-Za-z0-9]', ''));
        email_col = find(strcmp(keys, 'email'), 1);
        if isempty(email_col)
            Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
                'Crash email sheet needs an "Email" column; no crash email sent');
            return;
        end
        continue;
    end

    if numel(cells) < email_col, continue; end
    recipients = [recipients, regexp(cells{email_col}, '[^\s,;]+@[^\s,;]+', 'match')]; %#ok<AGROW>
end

% Send each address once, keeping sheet order
[~, first] = unique(lower(recipients), 'stable');
recipients = recipients(first);

if isempty(recipients)
    Sound2AFC_log_problem(experimenter, ratname, 'warning', ...
        'No addresses in crash email sheet; no crash email sent');
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
