% [x, y] = SoundConfigSection(obj, action, x, y)
%
% Section for configuring sound files, port mappings, and probabilities
%
% Manages 4 sound labels (A, B, C, D), each with:
%   - Sound file selection
%   - Port mapping (left/right/both)
%   - Probability weight (auto-normalized)

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

        % Available sound names
        SoloParamHandle(obj, 'available_sound_names', 'value', ...
            {'bus', 'storm', 'leafblower', 'crowd'}, 'save_with_settings', 0);

        % Create fixed sound labels
        SoloParamHandle(obj, 'sound_labels', 'value', {'A', 'B', 'C', 'D'}, 'save_with_settings', 0);

        % Title
        SubheaderParam(obj, 'soundconfig_title', 'Sound Configuration', x, y);
        next_row(y, 1.5);

        % Define defaults for each sound
        defaults = struct();
        defaults.A = struct('name', 'bus', 'weight', 0.5, 'port', 'left');
        defaults.B = struct('name', 'leafblower', 'weight', 0, 'port', 'random');
        defaults.C = struct('name', 'storm', 'weight', .5, 'port', 'right');
        defaults.D = struct('name', 'crowd', 'weight', 0, 'port', 'random');

        % Create GUI elements for each sound label
        labels = value(sound_labels);
        sound_names = value(available_sound_names);

        for i = length(labels):-1:1
            label = labels{i};
            def = defaults.(label);

            % Find default indices
            default_name_idx = find(strcmp(sound_names, def.name));
            default_port_idx = find(strcmp({'left', 'right', 'random'}, def.port));

            % Probability weight
            NumeditParam(obj, sprintf('sound_%s_prob', label), ...
                def.weight, x, y, ...
                'label', 'Weight');
            set_callback(eval(sprintf('sound_%s_prob', label)), ...
                {mfilename, 'normalize_probs'});
            next_row(y);

            % Port mapping menu (which port is correct)
            MenuParam(obj, sprintf('sound_%s_port', label), ...
                {'left', 'right', 'random'}, default_port_idx, x, y, ...
                'label', 'Port');
            next_row(y);
            
            % Sound name selection menu
            MenuParam(obj, sprintf('sound_%s_name', label), ...
                sound_names, default_name_idx, x, y, ...
                'label', 'Name');
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
        global_vars = {'normalized_probs', 'sound_name_to_file_map', 'available_sound_names'};
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

    case 'get_sound_config'
        % Returns struct with configuration for a given label
        GetSoloFunctionArgs(obj);

        label = x;  % x parameter used for label when called this way

        name_param = sprintf('sound_%s_name', label);
        port_param = sprintf('sound_%s_port', label);

        % Get the sound name and look up the file
        sound_name = value(eval(name_param));
        file_map = value(sound_name_to_file_map);
        sound_file = file_map.(sound_name);

        config = struct();
        config.name = sound_name;
        config.file = sound_file;
        config.port = value(eval(port_param));
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
