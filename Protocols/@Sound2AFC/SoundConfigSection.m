% [x, y] = SoundConfigSection(obj, action, x, y)
%
% Section for configuring sound files, port mappings, and probabilities
%
% Manages 4 sound labels (A, B, C, D), each with:
%   - Sound assignment (read-only; pulled per rat from a Google Sheet)
%   - Correct port (read-only; pulled per rat from the same sheet)
%   - Probability weight (auto-normalized)
%
% Which sound plays as A/B/C/D, and which labels are correct-left and
% correct-right, are NOT editable from the GUI. They are looked up by
% ratname in the "Generalization Task Sound Orderings" Google Sheet
% (columns ratname,A,B,C,D,correct left,correct right; see
% fetch_assignment_table below). The two labels that are neither
% correct-left nor correct-right reward a random side. A rat with no row in
% that sheet cannot run.

function [x, y] = SoundConfigSection(obj, action, x, y)

GetSoloFunctionArgs(obj);

switch action
    case 'init'
        % Save GUI position
        SoloParamHandle(obj, 'soundconfig_gui_info', 'value', [x y double(gcf)]);

        % Define sound name to file mapping
        SoloParamHandle(obj, 'sound_name_to_file_map', 'value', struct(...
            'bus', '181900__yurkobb__bus-engine-looped.wav', ...
            'storm', '788203__klankbeeld__storm-bare-trees-7bft-421-pm-170223_1093.wav', ...
            'leafblower', '803709__itinerantmonk108__electric-leaf-blower-in-quad.wav', ...
            'crowd', '805977__kevp888__250510_121339_fr_large_crowd_in_palais_garnier.wav' ...
        ), 'save_with_settings', 0);

        % Create fixed sound labels
        SoloParamHandle(obj, 'sound_labels', 'value', {'A', 'B', 'C', 'D'}, 'save_with_settings', 0);

        % Per-rat sound assignment, filled by 'load_assignment'. Saved with
        % data (so each session records what A-D and the ports were) but
        % never with settings, so a settings file can't override the sheet.
        SoloParamHandle(obj, 'sound_assignment', 'value', struct(), 'save_with_settings', 0);
        SoloParamHandle(obj, 'sound_assignment_ratname', 'value', '', 'save_with_settings', 0);

        % Title
        SubheaderParam(obj, 'soundconfig_title', 'Sound Configuration', x, y);
        next_row(y, 1.5);

        % Create GUI elements for each sound label. Weights start at 0 and
        % are set by 'load_assignment' once the rat's ports are known.
        labels = value(sound_labels);

        for i = length(labels):-1:1
            label = labels{i};

            % Probability weight
            NumeditParam(obj, sprintf('sound_%s_prob', label), ...
                0, x, y, ...
                'label', 'Weight');
            set_callback(eval(sprintf('sound_%s_prob', label)), ...
                {mfilename, 'normalize_probs'});
            next_row(y);

            % Correct port (display only; set from the Google Sheet)
            DispParam(obj, sprintf('sound_%s_port', label), ...
                '(unassigned)', x, y, 'label', 'Port', 'save_with_settings', 0);
            next_row(y);

            % Assigned sound (display only; set from the Google Sheet)
            DispParam(obj, sprintf('sound_%s_name', label), ...
                '(unassigned)', x, y, 'label', 'Name', 'save_with_settings', 0);
            next_row(y);

            % Section label
            SubheaderParam(obj, sprintf('sound_%s_header', label), ...
                sprintf('Sound %s', label), x, y);
            next_row(y);

            next_row(y, 0.5);  % Extra space between sounds
        end

        % Add normalized probability display
        DispParam(obj, 'normalized_probs_display', ...
            'A:0.25 B:0.25 C:0.25 D:0.25', x, y, ...
            'label', 'Normalized', 'labelpos', 'top', ...
            'position', [x, y, 200, 40]);
        next_row(y, 1.5);

        % Initialize normalized probabilities
        SoloParamHandle(obj, 'normalized_probs', 'value', [0.25 0.25 0.25 0.25], ...
            'save_with_settings', 0);

        % Normalize on init
        SoundConfigSection(obj, 'normalize_probs');

        % Make all sound parameters globally accessible
        global_vars = {'normalized_probs', 'sound_name_to_file_map'};
        for i = 1:length(labels)
            label = labels{i};
            global_vars{end+1} = sprintf('sound_%s_name', label);
            global_vars{end+1} = sprintf('sound_%s_port', label);
            global_vars{end+1} = sprintf('sound_%s_prob', label);
        end
        DeclareGlobals(obj, 'ro_args', global_vars);

    case 'normalize_probs'
        % Collect raw probability weights
        sound_labels = value(sound_labels);
        raw_probs = zeros(1, length(sound_labels));

        for i = 1:length(sound_labels)
            label = sound_labels{i};
            prob_param = sprintf('sound_%s_prob', label);
            raw_probs(i) = value(eval(prob_param));
        end

        % Normalize
        total = sum(raw_probs);
        if total > 0
            norm_probs = raw_probs / total;
        else
            norm_probs = ones(1, length(sound_labels)) / length(sound_labels);
        end

        normalized_probs.value = norm_probs;

        % Update display
        display_str = sprintf('A:%.2f  B:%.2f  C:%.2f  D:%.2f', ...
            norm_probs(1), norm_probs(2), norm_probs(3), norm_probs(4));
        normalized_probs_display.value = display_str;

    case 'load_assignment'
        % Look up the current ratname in the sound assignment Google Sheet
        % and store its A-D sound names and correct ports. Resets weights to
        % 0.5 for the correct-left and correct-right labels and 0 for the
        % other two. Returns x = true if the rat was found.
        % Pass x = 'error' to error out (instead of warn) when not found.
        error_if_missing = nargin >= 3 && ischar(x) && strcmp(x, 'error');

        [~, rname] = SavingSection(obj, 'get_info');
        rname = strtrim(rname);
        [table_text, source] = fetch_assignment_table();
        assignment = read_sound_assignment(table_text, source, rname, ...
            fieldnames(value(sound_name_to_file_map)));

        labels = value(sound_labels);
        if isempty(assignment)
            sound_assignment.value = struct();
            sound_assignment_ratname.value = '';
            for i = 1:length(labels)
                name_disp = eval(sprintf('sound_%s_name', labels{i}));
                name_disp.value = '(unassigned)';
                port_disp = eval(sprintf('sound_%s_port', labels{i}));
                port_disp.value = '(unassigned)';
            end
            msg = sprintf('No sound assignment for rat "%s" in %s. Add a row for this rat before running.', ...
                rname, source);
            if error_if_missing
                error('Sound2AFC:no_sound_assignment', '%s', msg);
            end
            warning('Sound2AFC:no_sound_assignment', '%s', msg);
            x = false;
        else
            sound_assignment.value = assignment;
            sound_assignment_ratname.value = rname;
            for i = 1:length(labels)
                label = labels{i};
                name_disp = eval(sprintf('sound_%s_name', label));
                name_disp.value = assignment.(label);
                port_disp = eval(sprintf('sound_%s_port', label));
                port_disp.value = label_port(assignment, label);
                prob = eval(sprintf('sound_%s_prob', label));
                if strcmp(label_port(assignment, label), 'random')
                    prob.value = 0;
                else
                    prob.value = 0.5;
                end
            end
            SoundConfigSection(obj, 'normalize_probs');
            fprintf('Sound assignment for %s: A=%s B=%s C=%s D=%s, correct left=%s, correct right=%s\n', ...
                rname, assignment.A, assignment.B, assignment.C, assignment.D, ...
                assignment.correct_left, assignment.correct_right);
            x = true;
        end

    case 'check_weights'
        % Warn if the correct-left or correct-right sound has weight 0, e.g.
        % because a settings file saved weights for different labels.
        assignment = value(sound_assignment);
        if isfield(assignment, 'correct_left')
            sides = {'correct left', assignment.correct_left; ...
                     'correct right', assignment.correct_right};
            for i = 1:size(sides, 1)
                if value(eval(sprintf('sound_%s_prob', sides{i, 2}))) == 0
                    warning('Sound2AFC:zero_weight', ...
                        'Sound %s is the %s sound but its weight is 0, so it will never play.', ...
                        sides{i, 2}, sides{i, 1});
                end
            end
        end

    case 'get_assignment_ratname'
        % Ratname the current sound assignment was loaded for ('' if none)
        x = value(sound_assignment_ratname);

    case 'get_sound_config'
        % Returns struct with configuration for a given label
        GetSoloFunctionArgs(obj);

        label = x;  % x parameter used for label when called this way

        % Get the assigned sound name and look up the file
        assignment = value(sound_assignment);
        if ~isfield(assignment, label)
            error('Sound2AFC:no_sound_assignment', ...
                'No sound assignment loaded. Add this rat to the "Generalization Task Sound Orderings" sheet.');
        end
        sound_name = assignment.(label);
        file_map = value(sound_name_to_file_map);
        sound_file = file_map.(sound_name);

        config = struct();
        config.name = sound_name;
        config.file = sound_file;
        config.port = label_port(assignment, label);
        config.label = label;

        x = config;
        y = label;

    case 'reinit'
        % Get original GUI position
        x = soundconfig_gui_info(1);
        y = soundconfig_gui_info(2);
        figure(soundconfig_gui_info(3));

        % Delete old GUI elements
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

        % Reinitialize
        [x, y] = feval(mfilename, obj, 'init', x, y);
end

end


function port = label_port(assignment, label)
% 'left', 'right', or 'random' for a label, per the rat's sheet row
if strcmp(label, assignment.correct_left)
    port = 'left';
elseif strcmp(label, assignment.correct_right)
    port = 'right';
else
    port = 'random';
end
end


function [table_text, source] = fetch_assignment_table()
% Downloads the "Generalization Task Sound Orderings" Google Sheet as CSV.
% The sheet must be viewable by anyone with the link. Each successful
% download is cached locally; if the download fails (no internet, Google
% down) the cached copy is used with a warning.
sheet_url = ['https://docs.google.com/spreadsheets/d/' ...
    '1C7BHR3yfgxGvL0hvvexWOQ-3oneIaqPQ92uaDs1Sf40/export?format=csv'];
cache_file = fullfile(fileparts(mfilename('fullpath')), 'sound_assignments_cache.csv');

try
    table_text = webread(sheet_url, weboptions('ContentType', 'text', 'Timeout', 15));
    source = 'Google Sheet "Generalization Task Sound Orderings"';
    try
        fid = fopen(cache_file, 'w');
        fwrite(fid, table_text, 'char');
        fclose(fid);
    catch ME
        warning('Sound2AFC:assignment_cache', 'Could not write cache %s: %s', cache_file, ME.message);
    end
catch ME
    if ~exist(cache_file, 'file')
        error('Sound2AFC:no_assignment_table', ...
            'Could not download the sound assignment sheet (%s) and no cached copy exists at %s', ...
            ME.message, cache_file);
    end
    d = dir(cache_file);
    warning('Sound2AFC:assignment_offline', ...
        'Could not download the sound assignment sheet (%s). Using cached copy from %s.', ...
        ME.message, d.date);
    table_text = fileread(cache_file);
    source = sprintf('cached sheet %s', cache_file);
end
end


function assignment = read_sound_assignment(table_text, source, rname, valid_names)
% Returns struct with fields A-D (sound names) plus correct_left and
% correct_right (labels A-D) for rname, or [] if the rat has no row.
% Format: header 'ratname,A,B,C,D,correct left,correct right', one row per
% rat, '#' starts a comment. Ratname matching is case-insensitive.
assignment = [];
labels = {'A', 'B', 'C', 'D'};
header = {'ratname', 'a', 'b', 'c', 'd', 'correct left', 'correct right'};
n_cols = numel(header);
header_seen = false;
lines = regexp(table_text, '\r?\n', 'split');
for line_num = 1:numel(lines)
    ln = lines{line_num};
    hash = strfind(ln, '#');
    if ~isempty(hash), ln = ln(1:hash(1)-1); end
    ln = strtrim(ln);
    if isempty(ln), continue; end

    cols = strtrim(strsplit(ln, ','));
    % Sheets can export trailing empty columns; skip blank rows entirely
    last = find(~cellfun(@isempty, cols), 1, 'last');
    if isempty(last), continue; end
    cols = cols(1:max(last, min(n_cols, numel(cols))));
    if ~header_seen
        header_seen = true;
        if ~isequal(lower(regexprep(cols, '[\s_]+', ' ')), header)
            error('Sound2AFC:bad_assignment_table', ...
                '%s: header must be "ratname,A,B,C,D,correct left,correct right"', source);
        end
        continue;
    end
    % Only this rat's row is validated, so a half-filled row for another
    % rat doesn't block everyone
    if ~strcmpi(cols{1}, rname), continue; end
    if numel(cols) ~= n_cols
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: expected %d columns (ratname,A,B,C,D,correct left,correct right)', ...
            source, line_num, n_cols);
    end

    names = lower(cols(2:5));
    bad = names(~ismember(names, valid_names));
    if ~isempty(bad)
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: unknown sound "%s". Valid: %s', source, line_num, ...
            bad{1}, strjoin(valid_names(:)', ', '));
    end
    if numel(unique(names)) ~= numel(names)
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: each sound may only be used once per rat', source, line_num);
    end
    ports = upper(cols(6:7));
    if ~all(ismember(ports, labels))
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: correct left/right must each be one of A, B, C, D', source, line_num);
    end
    if strcmp(ports{1}, ports{2})
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: correct left and correct right must be different labels', source, line_num);
    end
    if ~isempty(assignment)
        error('Sound2AFC:bad_assignment_table', ...
            '%s: rat "%s" appears more than once', source, rname);
    end
    assignment = cell2struct(names(:), labels(:), 1);
    assignment.correct_left = ports{1};
    assignment.correct_right = ports{2};
end
end
