function sma = AddSyncStates_RLE(sma, trialnum, bnc_dioline, timebin)
% Inputs:
% sma: State Machine Assembler object
% trialnum: The trial number to encode (e.g., n_done_trials + 1)
% bnc_dioline: The DOut bit mask corresponding to the BNC output line (e.g., 32)
% timebin: Duration for each bit run (e.g., 0.001 for 1 ms)

% --- Settings ---
bits = 15;        % Number of bits for the trial number
header = 1;       % 1-bit header (value '1')
state_name = 'sync_states_rle';

% --- Encoding ---
% 1. Combine header and trial number (up to 15 bits)
trialnum_bin = dec2bin(trialnum);
padded_trialnum = ['0'*ones(1, bits - length(trialnum_bin)) trialnum_bin];
int2send = [dec2bin(header) padded_trialnum]; % e.g., '1000...001'

% 2. Run-Length Encoding (RLE) Logic: Calculates pulse durations
char2send = int2send;
nextchar = char2send(1); % Start with the first bit (usually '1' from the header)
done = false;
state_times = []; % Holds the duration (in bits) for each pulse

while ~done
    % Find the first index where the bit switches (e.g., '1' -> '0')
    ind = find(char2send ~= nextchar, 1, 'first'); 
    
    if isempty(ind)
        % End of sequence: current run lasts to the end
        state_times(end+1) = numel(char2send);
        break
    else
        % Duration of the current run
        state_times(end+1) = ind - 1;
        % Update the remaining sequence and the expected next bit
        char2send = char2send(ind:end);
        nextchar = char2send(1); % The new bit value
    end
end

% --- State Addition ---
orig_current_state = sma.current_state;
sma.current_state = 1; % Temporarily set current_state marker to state 1

for sx = 1:numel(state_times)
    this_name = sprintf('%s_%02d', state_name, sx);
    
    % The exit state for the last sync state should be the user's first state (40)
    if sx == numel(state_times)
        next_name = 40; % User's first state in full_trial_structure
    else
        next_name = sprintf('%s_%02d', state_name, sx + 1);
    end
    
    % Determine DOut action based on the pulse index (Odd/Even means High/Low)
    if mod(sx, 2) == 1 % Odd-numbered pulse (start is '1' (High))
        dout_val = bnc_dioline; % Set the bit High
    else % Even-numbered pulse (start is '0' (Low))
        dout_val = 0; % Set the bit Low
    end
    
    % Add the state with the calculated duration (run length * timebin)
    sma = add_state(sma, 'name', this_name, 'Timer', state_times(sx) * timebin, ...
        'StateChangeConditions', {'Tup', next_name}, ...
        'OutputActions', {'DOut', dout_val});
end

% --- Final Rewiring ---
% Now change state_0 so it jumps to State 1 (the first sync state)
TupCol = find(strcmp('Tup', sma.input_map(:,1))); TupCol = sma.input_map{TupCol,2};
all_input_cols = cell2mat(sma.input_map(:,2))';
for i=1:length(all_input_cols), sma.states{1,all_input_cols(i)} = 1; end;

% Return the current_state marker to its proper value
sma.current_state = orig_current_state;
end