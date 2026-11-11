% [x, y] = SoundConfigSection(obj, action, x, y)
%
% Section for configuring sound files, port mappings, and probabilities
%
% Manages 4 sound labels (A, B, C, D), each with:
%   - Sound assignment (read-only; pulled per rat from sound_assignments.csv)
%   - Correct port (read-only; set by the phase and the rat's CSV row)
%   - Fraction of trials (read-only; set by the phase)
%
% Each rat's row in sound_assignments.csv (next to this file) gives its A-D
% sounds and its ports. The phase is chosen on the GUI and saved with the
% rat's settings:
%   Train A/C     A, C 50% each at Correct Left/Right; no B/D trials
%   Probe Trials  A, C 45% each at Correct Left/Right; B, D 5% each,
%                 rewarded on a random side
%   B/D Remap     B, D 50% each at Remap Correct Left/Right; no A/C trials
% There is no default phase: a rat with no row in the CSV, or with no phase
% chosen (e.g. a new rat, or settings that failed to load), cannot run.

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
        % data (so each session records its sounds and ports) but never
        % with settings, so a settings file can't override the CSV.
        SoloParamHandle(obj, 'sound_assignment', 'value', struct(), 'save_with_settings', 0);
        SoloParamHandle(obj, 'sound_assignment_ratname', 'value', '', 'save_with_settings', 0);

        % Title
        SubheaderParam(obj, 'soundconfig_title', 'Sound Configuration', x, y);
        next_row(y, 1.5);

        % Create GUI elements for each sound label
        labels = value(sound_labels);

        for i = length(labels):-1:1
            label = labels{i};

            % Correct port (display only; set from the phase and the CSV)
            DispParam(obj, sprintf('sound_%s_port', label), ...
                '(unassigned)', x, y, 'label', 'Port', 'save_with_settings', 0);
            next_row(y);

            % Assigned sound (display only; set from the CSV)
            DispParam(obj, sprintf('sound_%s_name', label), ...
                '(unassigned)', x, y, 'label', 'Name', 'save_with_settings', 0);
            next_row(y);

            % Section label
            SubheaderParam(obj, sprintf('sound_%s_header', label), ...
                sprintf('Sound %s', label), x, y);
            next_row(y);

            next_row(y, 0.5);  % Extra space between sounds
        end

        % Task phase, saved with the rat's settings. No default on purpose:
        % '(choose phase)' blocks trials, so a rat whose settings didn't load
        % never silently runs the wrong phase.
        MenuParam(obj, 'sound_phase', [{'(choose phase)'}, phase_names()], ...
            '(choose phase)', x, y, 'label', 'Phase', ...
            'TooltipString', 'Applies from the next trial. Save settings to keep it for this rat.');
        set_callback(sound_phase, {mfilename, 'phase_changed'});
        next_row(y, 1.5);
        % Last phase that passed checks, to undo an invalid menu choice
        SoloParamHandle(obj, 'applied_phase', 'value', '', 'save_with_settings', 0, 'saveable', 0);

        % Add normalized probability display
        DispParam(obj, 'normalized_probs_display', ...
            '(choose phase)', x, y, ...
            'label', 'Normalized', 'labelpos', 'top', ...
            'position', [x, y, 200, 40]);
        next_row(y, 1.5);

        % Fraction of trials per label; set from the phase by 'apply_phase'
        SoloParamHandle(obj, 'normalized_probs', 'value', [0 0 0 0], ...
            'save_with_settings', 0);

        % Make all sound parameters globally accessible
        global_vars = {'normalized_probs', 'sound_name_to_file_map', 'sound_phase'};
        for i = 1:length(labels)
            label = labels{i};
            global_vars{end+1} = sprintf('sound_%s_name', label);
            global_vars{end+1} = sprintf('sound_%s_port', label);
        end
        DeclareGlobals(obj, 'ro_args', global_vars);

    case 'load_assignment'
        % Look up the current ratname in sound_assignments.csv and store its
        % A-D sound names and ports. Returns x = true if the rat was found.
        % Pass x = 'error' to error out (instead of warn) when not found.
        error_if_missing = nargin >= 3 && ischar(x) && strcmp(x, 'error');

        [expmtr, rname] = SavingSection(obj, 'get_info');
        rname = strtrim(rname);
        [table_text, source, fetch_problem] = fetch_assignment_table();
        if ~isempty(fetch_problem)
            Sound2AFC_log_problem(expmtr, rname, 'warning', fetch_problem);
        end
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
                % runrats logs this as a crash or failed load
                error('Sound2AFC:no_sound_assignment', '%s', msg);
            end
            warning('Sound2AFC:no_sound_assignment', '%s', msg);
            Sound2AFC_log_problem(expmtr, rname, 'warning', msg);
            x = false;
        else
            sound_assignment.value = assignment;
            sound_assignment_ratname.value = rname;
            for i = 1:length(labels)
                name_disp = eval(sprintf('sound_%s_name', labels{i}));
                name_disp.value = assignment.(labels{i});
            end
            fprintf(['Sound2AFC %s sounds: A=%s B=%s C=%s D=%s (Correct L/R %s/%s, ' ...
                'Remap Correct L/R %s/%s)\n'], rname, assignment.A, assignment.B, ...
                assignment.C, assignment.D, assignment.correct_left, ...
                assignment.correct_right, assignment.remap_correct_left, ...
                assignment.remap_correct_right);
            x = true;
        end
        SoundConfigSection(obj, 'update_display');

    case 'phase_changed'
        % Phase menu callback (also run when settings load). Mid-session,
        % an invalid choice is undone so the running session isn't stopped;
        % otherwise prepare_next_trial ('apply_phase') refuses to run it.
        [~, problem] = check_phase(value(sound_assignment), value(sound_phase));
        if ~isempty(problem)
            if dispatcher('is_running') && ~isempty(value(applied_phase))
                sound_phase.value = value(applied_phase);
                problem = sprintf('%s Kept phase %s.', problem, value(applied_phase));
            end
            warning('Sound2AFC:bad_phase', '%s', problem);
            [expmtr, rname] = SavingSection(obj, 'get_info');
            Sound2AFC_log_problem(expmtr, rname, 'warning', problem);
        end
        SoundConfigSection(obj, 'update_display');

    case 'apply_phase'
        % Called by prepare_next_trial before each trial: sets the fraction
        % of trials per label from the phase menu. Errors if no valid phase
        % is chosen, so a rat never runs a phase nobody picked.
        [phase, problem] = check_phase(value(sound_assignment), value(sound_phase));
        if ~isempty(problem)
            error('Sound2AFC:bad_phase', '%s', problem);
        end
        normalized_probs.value = phase_probs(phase);
        SoundConfigSection(obj, 'update_display');
        if ~strcmp(value(applied_phase), value(sound_phase))
            applied_phase.value = value(sound_phase);
            [~, rname] = SavingSection(obj, 'get_info');
            labels = value(sound_labels);
            desc = '';
            for i = 1:length(labels)
                port_disp = eval(sprintf('sound_%s_port', labels{i}));
                desc = [desc sprintf(' %s(%s, %.0f%%)', labels{i}, ...
                    value(port_disp), 100*normalized_probs(i))]; %#ok<AGROW>
            end
            fprintf('Sound2AFC %s, phase %s:%s\n', rname, value(sound_phase), desc);
        end

    case 'update_display'
        % Refresh the port and fraction-of-trials displays from the phase
        % menu and the rat's CSV row
        assignment = value(sound_assignment);
        labels = value(sound_labels);
        [phase, problem] = check_phase(assignment, value(sound_phase));
        if isempty(problem), probs = phase_probs(phase); end
        for i = 1:length(labels)
            port_disp = eval(sprintf('sound_%s_port', labels{i}));
            if ~isfield(assignment, labels{i})
                port_disp.value = '(unassigned)';
            elseif ~isempty(problem)
                port_disp.value = '(choose phase)';
            elseif probs(i) == 0
                port_disp.value = '(not used)';
            else
                port_disp.value = label_port(assignment, labels{i}, phase);
            end
        end
        if isempty(problem)
            normalized_probs_display.value = sprintf('A:%.2f  B:%.2f  C:%.2f  D:%.2f', probs);
        else
            normalized_probs_display.value = '(choose phase)';
        end

    case 'phase_is_set'
        % True if the phase menu holds a real phase (not '(choose phase)')
        x = ~isempty(phase_key(value(sound_phase)));

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
                'No sound assignment loaded. Add this rat to sound_assignments.csv.');
        end
        sound_name = assignment.(label);
        file_map = value(sound_name_to_file_map);
        sound_file = file_map.(sound_name);

        config = struct();
        config.name = sound_name;
        config.file = sound_file;
        config.port = label_port(assignment, label, phase_key(value(sound_phase)));
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


function names = phase_names()
% Phase menu choices, in order (see phase_key)
names = {'Train A/C', 'Probe Trials', 'B/D Remap'};
end


function phase = phase_key(phase_name)
% Internal key for a phase menu choice; '' for '(choose phase)'
switch phase_name
    case 'Train A/C',    phase = 'train_ac';
    case 'Probe Trials', phase = 'probe';
    case 'B/D Remap',    phase = 'bd_remap';
    otherwise,           phase = '';
end
end


function [phase, problem] = check_phase(assignment, phase_name)
% phase key for the menu choice, and why it can't run ('' if it can).
% The ports are only checked once the rat's CSV row is loaded.
phase = phase_key(phase_name);
problem = '';
if isempty(phase)
    problem = 'No phase chosen. Choose one in the Phase menu on the Sound2AFC window, then save settings.';
elseif ~isfield(assignment, 'correct_left')
    return;
elseif strcmp(phase, 'bd_remap')
    if ~isequal(sort({assignment.remap_correct_left, assignment.remap_correct_right}), {'B', 'D'})
        problem = ['B/D Remap needs Remap Correct Left/Right to be B and D (one each) ' ...
            'in this rat''s row of sound_assignments.csv.'];
    end
elseif ~isequal(sort({assignment.correct_left, assignment.correct_right}), {'A', 'C'})
    problem = [phase_name ' needs Correct Left/Right to be A and C (one each) ' ...
        'in this rat''s row of sound_assignments.csv.'];
end
end


function port = label_port(assignment, label, phase)
% 'left', 'right', or 'random' for a label, per the phase and the rat's CSV row
if strcmp(phase, 'bd_remap')
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


function [table_text, source, problem] = fetch_assignment_table()
% Reads sound_assignments.csv (next to this file, version controlled).
% problem is always '' now; kept so the caller doesn't change.
assignment_file = fullfile(fileparts(mfilename('fullpath')), 'sound_assignments.csv');
problem = '';
if ~exist(assignment_file, 'file')
    error('Sound2AFC:no_assignment_table', ...
        'Sound assignment file not found: %s', assignment_file);
end
table_text = fileread(assignment_file);
source = assignment_file;
end


function assignment = read_sound_assignment(table_text, source, rname, valid_names)
% Returns the rat's row as a struct (fields A-D = sound names,
% correct_left/right, remap_correct_left/right), or [] if the rat has no
% row. Columns are found by header name, so their order in the CSV doesn't
% matter. Blank rows are skipped; ratname matching ignores case. The ports
% are checked against the phase in check_phase.
assignment = [];
labels = {'A', 'B', 'C', 'D'};
col_names = {'ratname', 'a', 'b', 'c', 'd', ...
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

    names = lower(row(2:5));
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

    ports = upper(row(6:9));
    assignment = cell2struct(names(:), labels(:), 1);
    assignment.correct_left = ports{1};
    assignment.correct_right = ports{2};
    assignment.remap_correct_left = ports{3};
    assignment.remap_correct_right = ports{4};
end
end
