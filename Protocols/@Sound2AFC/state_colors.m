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
