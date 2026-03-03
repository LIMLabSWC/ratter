
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
obj = class(struct, mfilename, pokesplot, saveload, sessionmodel, soundmanager, soundui, antibias, ...
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

switch action
    case 'init'
        create_gui()

        obj = create_sounds(obj);
        Sound2AFC(obj, 'prepare_next_trial')

    case 'prepare_next_trial'
        trial_params = get_trial_params(obj);
        [sma, prep_next_trial_states] = build_sma(obj, trial_params);

        dispatcher('send_assembler', sma, prep_next_trial_states);

    case 'trial_completed'

    case 'update'

    case 'end_session'

    case 'pre_saving_settings'
        % Make and send summary
    case 'close'

    otherwise
        warning('Unknown action! "%s"\n', action); %#ok<WNTAG>
end

return

end

function create_gui()
            % Make the GUI
        SoloParamHandle(obj, 'myfig', 'saveable', 0); 
        myfig.value = figure;
        set(value(myfig), 'Name', mfilename, 'Tag', mfilename, ...
        'closerequestfcn', 'dispatcher(''close_protocol'')', 'MenuBar', 'none');
        set(value(myfig), 'Position', [150 550   910  440 ]);
        
        x = 5; 
        y = 5;
        [x, y] = SavingSection(obj, 'init', x, y);
        [x, y] = PokesPlotSection(obj, 'init', x, y);
        PokesPlotSection(obj, 'set_alignon', 'wait_for_center_poke(1,1)');
end

function trial_params = get_trial_params(obj)
    trial_params = struct('sound_name', 'bus', ...
        'correct_side', 'left');
end

function obj = create_sounds(obj)
    sound_files = {'181900__yurkobb__bus-engine-looped.wav'};
    sound_names = {'bus'};
    sound_port_mappings = {'left'};
    assert(length(sound_files) == length(sound_names))

    SoundManagerSection(obj, 'init')
    target_sample_rate = SoundManagerSection(obj, 'get_sample_rate');
    
    for i = 1:length(sound_files)
        loop_flag = 0;
        [y, orig_rate] = audioread(sound_files{i});
            
        y = resample(y, target_sample_rate, orig_rate);

        SoundManagerSection(obj, 'declare_new_sound', sound_names{i}, y, loop_flag);
    end

    % Define the correct sound
    duration = .5;  % seconds
    volume = .1;
    t = (0:1/target_sample_rate:duration);
    t = t(1:end-1);
    carrier = sin(2*pi*12000*t);
    modulation = 1 + 0.5*sin(2*pi*8*t);  % 0.5 is modulation depth (0-1)
    waveform = volume * modulation .* carrier;  % 0.01 is overall volume
    waveform = [waveform; waveform];

    SoundManagerSection(obj, 'declare_new_sound', 'correct', waveform, loop_flag);

    % Define the error sound
    duration = 0.25;  % seconds
    n_samples = round(target_sample_rate * duration);
    waveform = 0.01 * randn(1, n_samples);
    SoundManagerSection(obj, 'declare_new_sound', 'error', waveform, loop_flag);

    SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
end




function [sma, prep_next_trial_states] = build_sma(obj, trial_params)
    global left1water;
    global right1water;

    pre_stim_cpoke_dur = .1;
    post_stim_cpoke_dur = .3;
    choice_timer = 5;
    cpoke_viol_state = 'check_next_trial_ready';
    
    sound_name = trial_params.sound_name ;
    correct_side = trial_params.correct_side;
    
    correct_state = sprintf('%s_reward', correct_side);
    error_state = 'error_state';
    switch correct_side
        case 'left'
            correct_in = 'Lin';
            error_in = 'Rin';
            rew_dout = left1water;
        case 'right'
            correct_in = 'Rin';
            error_in = 'Lin';
            rew_dout = right1water;
        otherwise
            error('Don''t know how to handle correct_side')
    end

    stim_id = SoundManagerSection(obj, 'get_sound_id', sound_name);
    rew_snd_id = SoundManagerSection(obj, 'get_sound_id', 'correct'); 
    err_snd_id = SoundManagerSection(obj, 'get_sound_id', 'error');

    center1led   = bSettings('get', 'DIOLINES', 'center1led');
    % Initialize a state machine with some default states: including check_next_trial_ready
    prep_next_trial_states = {'check_next_trial_ready'};

    sma = StateMachineAssembler('full_trial_structure');

    % wait for center poke, with center LED on
    sma = add_state(sma, 'name', 'wait_for_center_poke', ...
        'output_actions', {'DOut', center1led}, ...
        'input_to_statechange',{'Cin', 'cpoke_pre_stim'});

    % center poke to start stimulus
    sma = add_state(sma, 'name', 'cpoke_pre_stim','timer', pre_stim_cpoke_dur, ...
        'output_actions', {'DOut', center1led}, ...
        'input_to_statechange',{'Cout', 'wait_for_center_poke', ...
        'Tup', 'cpoke_stim'});
    sma = add_state(sma, 'name', 'cpoke_stim', 'timer', post_stim_cpoke_dur, ...
        'output_actions', {'DOut', center1led, 'SoundOut', stim_id}, ...
        'input_to_statechange',{'Cout', cpoke_viol_state, ...
        'Tup', 'wait_for_choice'});

    % wait for a choice
    sma = add_state(sma, 'name', 'wait_for_choice', 'timer', choice_timer, ...
        'input_to_statechange', {correct_in, correct_state; ...
        error_in, error_state; 'Tup', 'check_next_trial_ready'});

    % deliver the outcome
    sma = add_state(sma, 'name', correct_state, ...
        'output_actions', {'DOut', rew_dout, 'SoundOut', rew_snd_id});

    sma = add_state(sma, 'name', error_state, {'SoundOut', err_snd_id});
    
end