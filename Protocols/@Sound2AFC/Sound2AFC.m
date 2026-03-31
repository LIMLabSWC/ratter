
function [obj] = Sound2AFC(varargin)
% Create an instance of the class Sound2AFC
% If varargin is empty, return an empty instance of Sound2AFC. Otherwise, expected usage is either:
% obj = Sound2AFC(obj, action) or
% obj = Sound2AFC(action)
% 
% This class creates an object that dispatcher communicates with

% BEGIN ARGUMENT PARSING HEADER COMMON TO ALL PROTOCOLS -------------

% This is old MATLAB oop syntax to create an instance of the class with the name from this file (mfilename) e.g., Sound2AFC
% It can use methods available in all of the other referenced functions, e.g., pokesplot
obj = class(struct, mfilename, pokesplot2, saveload, sessionmodel2, soundmanager, soundui, antibias, ...
  water, distribui, punishui, comments, soundtable, sqlsummary);

% If there are no input arguments, return this empty instance of the class
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty')), 
   return; 
end;

% Check if first argument is an instance of this class or an action string
if isa(varargin{1}, mfilename), 
    % Check for incorrect calls with class object, but without a desired action
    if length(varargin) < 2 || ~ischar(varargin{2}), 
        error(['If called with a "%s" object as first arg, a second arg, a ' ...
      'string specifying the action, is required\n']);
    else 
        action = varargin{2}; 
        varargin = varargin(3:end); %#ok<NASGU>
    end;
elseif ischar(varargin{1})
       action = varargin{1}; 
       varargin = varargin(2:end); %#ok<NASGU>
else
    warning("The first argument should be an instance of the class object or an action")
end;
if ~ischar(action), 
    error('The action parameter must be a string'); 
end;

GetSoloFunctionArgs(obj);

% END HEADER COMMON TO ALL PROTOCOLS -------------

% Every protocol needs to have a behavior defined for each of the following actions: init, prepare_next_trial, trial_completed, update, end_session, pre_saving_settings, close

switch action
    case 'init'
        hackvar = 10; 
        SoloFunctionAddVars('SessionModel', 'ro_args', 'hackvar');
        % Trial outcome tracking
        SoloParamHandle(obj, 'hit_history',    'value', []);   % 1=hit, 0=error, NaN=violation/timeout
        SoloParamHandle(obj, 'previous_sides', 'value', []);   % 'l' or 'r' per trial
        SoloParamHandle(obj, 'trial_params_history', 'value', {});  % struct per trial: sound_name, correct_side, port_mapping
        SoloParamHandle(obj, 'current_trial_params', 'value', struct());
        DeclareGlobals(obj, 'rw_args', {'hit_history', 'previous_sides', 'trial_params_history', 'current_trial_params'});

        % Build the GUI and set up solo param handle variables
        create_gui(obj);

        % Define the sounds to use in this task
        obj = create_sounds(obj);

        % Need to prepare the first trial to present
        Sound2AFC(obj, 'prepare_next_trial')

    case 'prepare_next_trial'
        SessionDefinition(obj, 'next_trial');
        trial_params = get_trial_params(obj);
        current_trial_params.value = trial_params;

        [sma, prep_next_trial_states] = build_sma(obj, trial_params);
        dispatcher('send_assembler', sma, prep_next_trial_states);

    case 'trial_completed'
        Sound2AFC(obj, 'update');
        PokesPlotSection(obj, 'trial_completed');

        tp  = value(current_trial_params);
        hit = outcome_from_parsed_events(parsed_events.states);

        hit_history.value        = [value(hit_history),    hit];
        previous_sides.value     = [value(previous_sides), tp.correct_side(1)];  % 'l' or 'r'
        trial_params_history.value = [value(trial_params_history), {tp}];

    case 'update'
        PokesPlotSection(obj, 'update');

    case 'reload_sounds'
        obj = load_stim_sounds(obj);

    case 'end_session'
        prot_title.value = [value(prot_title), '  End: ', datestr(now, 'HH:MM')];

    case 'pre_saving_settings'
        pd.hits  = hit_history(:);
        pd.sides = previous_sides(:);
        pd.trial_params = trial_params_history(:);
        sendsummary(obj, 'protocol_data', pd);


    case 'close'
        PokesPlotSection(obj, 'close');
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig))
            delete(value(myfig));
        end
    otherwise
        warning('Unknown action! "%s"\n', action); %#ok<WNTAG>
end

return

end

% Define helper functions used above 
% ----------------------------------

function create_gui(obj)
        GetSoloFunctionArgs(obj);

        % Make the GUI
        SoloParamHandle(obj, 'myfig', 'saveable', 0);
        myfig.value = figure;
        set(value(myfig), 'Name', mfilename, 'Tag', mfilename, ...
        'closerequestfcn', 'dispatcher(''close_protocol'')', 'MenuBar', 'none');

        % Center the window on screen with good size
        screen_size = get(0, 'ScreenSize');
        fig_width = 910;
        fig_height = 700;
        fig_x = (screen_size(3) - fig_width) / 2;
        fig_y = (screen_size(4) - fig_height) / 2;
        set(value(myfig), 'Position', [fig_x fig_y fig_width fig_height]);

        % Column 1: Saving and Sound Config
        x = 5;
        y = 5;
        [x, y] = SavingSection(obj, 'init', x, y);

        next_row(y, 1);
        [x, y] = SoundConfigSection(obj, 'init', x, y);

        % Column 1: PokesPlot
        next_row(y, 1);
        [x, y] = PokesPlotSection(obj, 'init', x, y, struct('states',  state_colors()));
        PokesPlotSection(obj, 'set_alignon', 'wait_for_center_poke(1,1)');
        PokesPlotSection(obj, 'hide');
    

        [expmtr, rname] = SavingSection(obj, 'get_info');
        figpos = get(value(myfig), 'Position');
        HeaderParam(obj, 'prot_title', ['Sound2AFC: ' expmtr ', ' rname], ...
            x, y, 'position', [10 figpos(4)-25, 600 20]);

        y = 5;
        next_column(x);
        [x,y] = WaterValvesSection(obj, 'init', x, y, 'streak_gui',1);

        next_row(y, 1);
        ToggleParam(obj, 'use_light_guides', 0, x, y, 'label', 'Light correct port', ...
            'OnString', 'Light: ON', 'OffString', 'Light: OFF');
        next_row(y);
        
        DeclareGlobals(obj, 'rw_args', {'use_light_guides'});

        SessionDefinition(obj, 'init', x, y, value(myfig));
        
end

function obj = create_sounds(obj)
    GetSoloFunctionArgs(obj);

    obj = load_stim_sounds(obj);
end

function obj = load_stim_sounds(obj)
    GetSoloFunctionArgs(obj);
    
    SoundManagerSection(obj, 'init');

    target_sample_rate = SoundManagerSection(obj, 'get_sample_rate');

    % Reload stimulus sounds A, B, C, D from current GUI config
    labels = {'A', 'B', 'C', 'D'};
    loop_flag = 0;

    for i = 1:length(labels)
        label = labels{i};
        config = SoundConfigSection(obj, 'get_sound_config', label);

        [audio_data, orig_rate] = audioread(config.file);

        if size(audio_data, 2) == 2
            audio_data = mean(audio_data, 2);
        end

        if orig_rate ~= target_sample_rate
            orig_time = (0:length(audio_data)-1) / orig_rate;
            target_time = (0:1/target_sample_rate:orig_time(end));
            audio_data = interp1(orig_time, audio_data, target_time, 'linear');
            audio_data = audio_data(:);
        end

        stereo_waveform = .1*[audio_data'; audio_data'];
        SoundManagerSection(obj, 'declare_new_sound', label, stereo_waveform, loop_flag);
    end

    % Correct feedback sound
    duration = .5;
    volume = .1;
    t = (0:1/target_sample_rate:duration);
    t = t(1:end-1);
    carrier = sin(2*pi*12000*t);
    modulation = sin(2*pi*8*t);
    waveform = volume * modulation .* carrier;
    waveform = [waveform; waveform];
    SoundManagerSection(obj, 'declare_new_sound', 'correct', waveform, loop_flag);

    % Error sound
    duration = 0.25;
    n_samples = round(target_sample_rate * duration);
    waveform = 0.01 * randn(1, n_samples);
    waveform = [waveform; waveform];
    SoundManagerSection(obj, 'declare_new_sound', 'error', waveform, loop_flag);

    SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
end


function trial_params = get_trial_params(obj)
    GetSoloFunctionArgs(obj);

    % Get normalized probabilities
    probs = value(normalized_probs);
    labels = {'A', 'B', 'C', 'D'};

    % Select sound based on probabilities
    cumprobs = cumsum(probs);
    r = rand();
    sound_idx = find(r <= cumprobs, 1, 'first');
    selected_label = labels{sound_idx};

    % Get the port mapping for this sound
    config = SoundConfigSection(obj, 'get_sound_config', selected_label);
    port_mapping = config.port;

    % Determine correct side based on port mapping
    switch port_mapping
        case 'left'
            correct_side = 'left';
        case 'right'
            correct_side = 'right';
        case 'random'
            if rand() < 0.5
                correct_side = 'left';
            else
                correct_side = 'right';
            end
        otherwise
            error('Unknown port_mapping: %s', port_mapping);
    end

    trial_params = struct('sound_name', selected_label, ...
                         'correct_side', correct_side, ...
                         'port_mapping', port_mapping);
end


function [sma, prep_next_trial_states] = build_sma(obj, trial_params)
    GetSoloFunctionArgs(obj);
    global left1water;
    global right1water;
    center1led = bSettings('get', 'DIOLINES', 'center1led');
    right1led  = bSettings('get', 'DIOLINES', 'right1led');
    left1led   = bSettings('get', 'DIOLINES', 'left1led');

    light_correct_port = value(use_light_guides);
    iti_min = 3;
    iti_max = 8;
    iti_dur = iti_min + rand()*(iti_max-iti_min);
    pre_stim_cpoke_dur = .1;
    post_stim_cpoke_dur = .3;
    choice_timer = 45;
    [LeftWValveTime, RightWValveTime] = WaterValvesSection(obj, 'get_water_times');
    fprintf('The left and right water valve times are: %.2f, %.2f', ...
        LeftWValveTime, RightWValveTime)

    err_timer = 2;

    sound_name = trial_params.sound_name;
    correct_side = trial_params.correct_side;
    port_mapping = trial_params.port_mapping;

    % Determine if this is a random trial
    is_random = strcmp(port_mapping, 'random');
    
    correct_side_led = '';
    % Set up inputs and outputs based on correct side
    switch correct_side
        case 'left'
            drink_timer_1 = LeftWValveTime;
            if light_correct_port
                correct_side_led = left1led;
            end
            correct_in = 'Lin';
            error_in = 'Rin';
            rew_dout = left1water;
            % State names: left poke = reward, right poke = error
            if is_random
                correct_state = 'left_random_reward';
                error_state = 'right_random_error';
            else
                correct_state = 'left_reward';
                error_state = 'right_error';
            end
        case 'right'
            drink_timer_1 = RightWValveTime;
            if light_correct_port
                correct_side_led = right1led;
            end
            correct_in = 'Rin';
            error_in = 'Lin';
            rew_dout = right1water;
            % State names: right poke = reward, left poke = error
            if is_random
                correct_state = 'right_random_reward';
                error_state = 'left_random_error';
            else
                correct_state = 'right_reward';
                error_state = 'left_error';
            end
        otherwise
            error('Don''t know how to handle correct_side: %s', correct_side)
    end

    if light_correct_port
        wait_for_choice_led = correct_side_led;
    else
        wait_for_choice_led = 0;
    end

    stim_id = SoundManagerSection(obj, 'get_sound_id', sound_name);
    rew_snd_id = SoundManagerSection(obj, 'get_sound_id', 'correct'); 
    err_snd_id = SoundManagerSection(obj, 'get_sound_id', 'error');

    
    % Initialize a state machine with some default states: including check_next_trial_ready
    prep_next_trial_states = {'check_next_trial_ready'};

    sma = StateMachineAssembler('full_trial_structure');

    % wait for center poke, with center LED on
    sma = add_state(sma, 'name', 'wait_for_center_poke', ...
        'output_actions', {'DOut', center1led}, ...
        'input_to_statechange',{'Cin', 'cpoke_pre_stim'});

    % center poke to start stimulus
    sma = add_state(sma, 'name', 'cpoke_pre_stim','self_timer', pre_stim_cpoke_dur, ...
        'output_actions', {'DOut', center1led}, ...
        'input_to_statechange',{'Cout', 'wait_for_center_poke', ...
        'Tup', 'cpoke_stim'});
    
    sma = add_state(sma, 'name', 'cpoke_stim', 'self_timer', post_stim_cpoke_dur, ...
        'output_actions', {'DOut', center1led; 'SoundOut', stim_id}, ...
        'input_to_statechange',{'Cout', 'cpoke_violation', ...
        'Tup', 'wait_for_choice'});

    sma = add_state(sma, 'name', 'cpoke_violation', 'self_timer', .001, ...
        'input_to_statechange', {'Tup', 'ITI'}, ...
        'output_actions', {'SoundOut', -stim_id});

    % wait for a choice
    sma = add_state(sma, 'name', 'wait_for_choice', 'self_timer', choice_timer, ...
        'input_to_statechange', {correct_in, correct_state; ...
        error_in, error_state; 'Tup', 'ITI'},...
        'output_actions', {'DOut', wait_for_choice_led});

    % deliver the outcome
    

    sma = add_state(sma, 'name', correct_state, 'self_timer', drink_timer_1, ...
        'output_actions', {'DOut', rew_dout, 'SoundOut', rew_snd_id},...
        'input_to_statechange', {'Tup', 'ITI'});

    sma = add_state(sma, 'name', error_state, 'self_timer', err_timer, ...
        'output_actions', {'SoundOut', err_snd_id}, ...
        'input_to_statechange', {'Tup', 'ITI'});

    sma = add_state(sma, 'name', 'ITI', 'self_timer', iti_dur, ...
        'input_to_statechange', {'Tup', 'check_next_trial_ready'})
    
end

function hit = outcome_from_parsed_events(states)
% Returns 1 (hit), 0 (error), or NaN (violation/timeout) based on which
% terminal state was entered during the trial.
    reward_states = {'left_reward', 'right_reward', 'left_random_reward', 'right_random_reward'};
    error_states  = {'left_error',  'right_error',  'left_random_error',  'right_random_error'};

    for i = 1:length(reward_states)
        if isfield(states, reward_states{i}) && rows(states.(reward_states{i})) > 0
            hit = 1;
            return
        end
    end
    for i = 1:length(error_states)
        if isfield(states, error_states{i}) && rows(states.(error_states{i})) > 0
            hit = 0;
            return
        end
    end
    hit = NaN;  % violation or timeout — no choice was made
end

function sc = state_colors()
% Returns a structure with RGB color triplets for each state in the protocol
% Colors are used by PokesPlot to visualize trial states

sc = struct( ...
    'wait_for_center_poke',  [0.7  0.7  0.7], ...  % Light gray - waiting
    'cpoke_pre_stim',        [1.0  1.0  0.5], ...  % Light yellow - pre-stimulus
    'cpoke_stim',            [1.0  0.65 0.0], ...  % Orange - stimulus playing
    'wait_for_choice',       [0.5  0.8  1.0], ...  % Light cyan - waiting for choice
    ...
    'left_reward',           [0.0  0.5  1.0], ...  % Blue - left correct (deterministic)
    'right_reward',          [0.0  0.8  0.3], ...  % Green - right correct (deterministic)
    'left_error',            [1.0  0.4  0.4], ...  % Light red - left error (deterministic)
    'right_error',           [1.0  0.4  0.4], ...  % Light red - right error (deterministic)
    ...
    'left_random_reward',    [0.0  0.3  0.7], ...  % Darker blue - left correct (random)
    'right_random_reward',   [0.0  0.5  0.2], ...  % Darker green - right correct (random)
    'left_random_error',     [0.7  0.2  0.2], ...  % Darker red - left error (random)
    'right_random_error',    [0.7  0.2  0.2], ...  % Darker red - right error (random)
    ...
    'check_next_trial_ready',[0.3  0.3  0.3]);     % Dark gray - ITI

end
