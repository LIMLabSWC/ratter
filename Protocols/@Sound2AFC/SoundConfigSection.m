% [x, y] = SoundConfigSection(obj, action, x, y)
%
% Section for configuring sound files, port mappings, and probabilities
%
% Manages 4 sound labels (A, B, C, D), each with:
%   - Sound assignment (read-only; pulled per rat from a Google Sheet)
%   - Correct port (read-only; set by the rat's phase and sheet row)
%   - Fraction of trials (read-only; set by the rat's phase)
%
% Nothing here is editable from the GUI. Each rat's row in the
% "Generalization Task Sound Orderings" Google Sheet (see
% fetch_assignment_table below) gives its A-D sounds, its Current Phase,
% and its ports:
%   Train A/C     A, C 50% each at Correct Left/Right; no B/D trials
%   Probe Trials  A, C 45% each at Correct Left/Right; B, D 5% each,
%                 rewarded on a random side
%   B/D Remap     B, D 50% each at Remap Correct Left/Right; no A/C trials
% A rat with no row in that sheet, or an unknown phase, cannot run.

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
        % data (so each session records its sounds, phase and ports) but
        % never with settings, so a settings file can't override the sheet.
        SoloParamHandle(obj, 'sound_assignment', 'value', struct(), 'save_with_settings', 0);
        SoloParamHandle(obj, 'sound_assignment_ratname', 'value', '', 'save_with_settings', 0);

        % Title
        SubheaderParam(obj, 'soundconfig_title', 'Sound Configuration', x, y);
        next_row(y, 1.5);

        % Create GUI elements for each sound label
        labels = value(sound_labels);

        for i = length(labels):-1:1
            label = labels{i};

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

        % Task phase (display only; set from the Google Sheet)
        DispParam(obj, 'task_phase', '(unassigned)', x, y, ...
            'label', 'Phase', 'save_with_settings', 0);
        next_row(y, 1.5);

        % Add normalized probability display
        DispParam(obj, 'normalized_probs_display', ...
            'A:0.25 B:0.25 C:0.25 D:0.25', x, y, ...
            'label', 'Normalized', 'labelpos', 'top', ...
            'position', [x, y, 200, 40]);
        next_row(y, 1.5);

        % Fraction of trials per label; set from the phase by 'load_assignment'
        SoloParamHandle(obj, 'normalized_probs', 'value', [0.25 0.25 0.25 0.25], ...
            'save_with_settings', 0);

        % Make all sound parameters globally accessible
        global_vars = {'normalized_probs', 'sound_name_to_file_map', 'task_phase'};
        for i = 1:length(labels)
            label = labels{i};
            global_vars{end+1} = sprintf('sound_%s_name', label);
            global_vars{end+1} = sprintf('sound_%s_port', label);
        end
        DeclareGlobals(obj, 'ro_args', global_vars);

    case 'load_assignment'
        % Look up the current ratname in the sound assignment Google Sheet
        % and store its A-D sound names, phase and ports. Sets the fraction
        % of trials per label from the phase. Returns x = true if the rat
        % was found.
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
            task_phase.value = '(unassigned)';
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
            task_phase.value = assignment.phase_name;
            probs = phase_probs(assignment.phase);
            desc = '';
            for i = 1:length(labels)
                label = labels{i};
                name_disp = eval(sprintf('sound_%s_name', label));
                name_disp.value = assignment.(label);
                port_disp = eval(sprintf('sound_%s_port', label));
                if probs(i) == 0
                    port_disp.value = '(not used)';
                else
                    port_disp.value = label_port(assignment, label);
                end
                desc = [desc sprintf(' %s=%s(%s, %.0f%%)', label, ...
                    assignment.(label), value(port_disp), 100*probs(i))]; %#ok<AGROW>
            end
            normalized_probs.value = probs;
            normalized_probs_display.value = sprintf('A:%.2f  B:%.2f  C:%.2f  D:%.2f', probs);
            fprintf('Sound2AFC %s, phase %s:%s\n', rname, assignment.phase_name, desc);
            x = true;
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


function probs = phase_probs(phase)
% Fraction of trials for A, B, C, D in each phase
switch phase
    case 'train_ac', probs = [0.50 0    0.50 0   ];
    case 'probe',    probs = [0.45 0.05 0.45 0.05];
    case 'bd_remap', probs = [0    0.50 0    0.50];
end
end


function port = label_port(assignment, label)
% 'left', 'right', or 'random' for a label, per the rat's phase and sheet row
if strcmp(assignment.phase, 'bd_remap')
    left = assignment.remap_correct_left;
    right = assignment.remap_correct_right;
else
    left = assignment.correct_left;
    right = assignment.correct_right;
end
if strcmp(label, left)
    port = 'left';
elseif strcmp(label, right)
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
% Returns the rat's row as a struct (fields A-D = sound names, phase,
% phase_name, correct_left/right, remap_correct_left/right), or [] if the
% rat has no row. Columns are found by header name, so their order in the
% sheet doesn't matter. Blank rows are skipped; ratname and phase matching
% ignore case and spaces.
assignment = [];
labels = {'A', 'B', 'C', 'D'};
col_names = {'ratname', 'currentphase', 'a', 'b', 'c', 'd', ...
    'correctleft', 'correctright', 'remapcorrectleft', 'remapcorrectright'};
col_idx = [];
lines = regexp(table_text, '\r?\n', 'split');
for line_num = 1:numel(lines)
    cols = strtrim(strsplit(lines{line_num}, ','));
    if all(cellfun(@isempty, cols)), continue; end   % blank row

    if isempty(col_idx)
        % First non-blank row is the header
        keys = lower(regexprep(cols, '[^A-Za-z0-9]', ''));
        [found, col_idx] = ismember(col_names, keys);
        if ~all(found)
            error('Sound2AFC:bad_assignment_table', '%s: missing column(s): %s', ...
                source, strjoin(col_names(~found), ', '));
        end
        continue;
    end

    % Only this rat's row is validated, so a half-filled row for another
    % rat doesn't block everyone
    cols(end+1:max(col_idx)) = {''};
    if ~strcmpi(cols{col_idx(1)}, rname), continue; end
    if ~isempty(assignment)
        error('Sound2AFC:bad_assignment_table', ...
            '%s: rat "%s" appears more than once', source, rname);
    end
    row = cols(col_idx);   % in col_names order

    names = lower(row(3:6));
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

    phase_name = row{2};
    switch lower(regexprep(phase_name, '[^A-Za-z0-9]', ''))
        case 'trainac',     phase = 'train_ac';
        case 'probetrials', phase = 'probe';
        case 'bdremap',     phase = 'bd_remap';
        otherwise
            error('Sound2AFC:bad_assignment_table', ...
                '%s row %d: unknown phase "%s". Use Train A/C, Probe Trials, or B/D Remap', ...
                source, line_num, phase_name);
    end

    ports = upper(row(7:10));
    if ~strcmp(phase, 'bd_remap') && ~isequal(sort(ports(1:2)), {'A', 'C'})
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: Correct Left/Right must be A and C (one each)', source, line_num);
    end
    if strcmp(phase, 'bd_remap') && ~isequal(sort(ports(3:4)), {'B', 'D'})
        error('Sound2AFC:bad_assignment_table', ...
            '%s row %d: Remap Correct Left/Right must be B and D (one each)', source, line_num);
    end

    assignment = cell2struct(names(:), labels(:), 1);
    assignment.phase = phase;
    assignment.phase_name = phase_name;
    assignment.correct_left = ports{1};
    assignment.correct_right = ports{2};
    assignment.remap_correct_left = ports{3};
    assignment.remap_correct_right = ports{4};
end
end
