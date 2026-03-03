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

        % Define available sound files
        SoloParamHandle(obj, 'available_sound_files', 'value', {
            '181900__yurkobb__bus-engine-looped.wav'
            % Add more files here as needed
        }, 'save_with_settings', 0);

        % Create fixed sound labels
        sound_labels = {'A', 'B', 'C', 'D'};
        SoloParamHandle(obj, 'sound_labels', 'value', sound_labels, 'save_with_settings', 0);

        % Title
        SubheaderParam(obj, 'soundconfig_title', 'Sound Configuration', x, y);
        next_row(y, 1.5);

        % Column headers
        TextParam(obj, 'header_label', 'Label', x, y, 'position', [x y 40 20]);
        TextParam(obj, 'header_file', 'File', x+45, y, 'position', [x+45 y 200 20]);
        TextParam(obj, 'header_port', 'Port', x+250, y, 'position', [x+250 y 60 20]);
        TextParam(obj, 'header_prob', 'Weight', x+315, y, 'position', [x+315 y 60 20]);
        next_row(y);

        % Create GUI elements for each sound label
        for i = 1:length(sound_labels)
            label = sound_labels{i};

            % Label display
            TextParam(obj, sprintf('label_%s', label), label, x, y, ...
                'position', [x y 40 20]);

            % File selection menu
            MenuParam(obj, sprintf('sound_%s_file', label), ...
                value(available_sound_files), 1, x+45, y, ...
                'position', [x+45 y 200 20], ...
                'save_with_settings', 1, ...
                'labelfraction', 0);

            % Port mapping menu (which port is correct)
            MenuParam(obj, sprintf('sound_%s_port', label), ...
                {'left', 'right', 'random'}, 1, x+250, y, ...
                'position', [x+250 y 70 20], ...
                'save_with_settings', 1, ...
                'labelfraction', 0);

            % Probability weight
            EditParam(obj, sprintf('sound_%s_prob', label), ...
                1, x+315, y, ...
                'position', [x+315 y 60 20], ...
                'save_with_settings', 1, ...
                'labelfraction', 0);
            set_callback(eval(sprintf('sound_%s_prob', label)), ...
                {mfilename, 'normalize_probs'});

            next_row(y);
        end

        % Add normalized probability display
        next_row(y, 0.5);
        TextParam(obj, 'normalized_probs_label', 'Normalized:', x, y, ...
            'position', [x y 80 20]);
        TextParam(obj, 'normalized_probs_display', '', x+85, y, ...
            'position', [x+85 y 290 20]);
        next_row(y, 1.5);

        % Initialize normalized probabilities
        SoloParamHandle(obj, 'normalized_probs', 'value', [0.25 0.25 0.25 0.25], ...
            'save_with_settings', 0);

        % Normalize on init
        SoundConfigSection(obj, 'normalize_probs');

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

        file_param = sprintf('sound_%s_file', label);
        port_param = sprintf('sound_%s_port', label);

        config = struct();
        config.file = value(available_sound_files){value(eval(file_param))};
        config.port = value(eval(port_param));
        config.label = label;

        y = config;  % Return via y

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
