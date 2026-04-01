% [sma] = add_ephys_trial_indicator(sma, trialnum, ...)
%
% Sends a binary trial number signal on a DIO line for synchronisation with
% neural recording systems (e.g. Neuropixels via Open Ephys or SpikeGLX).
%
% Replacement for add_trialnum_indicator with two fixes:
%
%   FIX 1 - Jump target:
%     Original hardcoded jump target of 40 is correct for this BControl/Bpod
%     implementation (full_trial_structure always places user states at 40).
%     Previous version incorrectly used orig_current_state (= 59, the next
%     empty slot) which jumped beyond the state table causing trial crashes.
%     This version reads the correct target dynamically from state_0's Tup
%     transition before redirecting it, so it is robust to any framework.
%
%   FIX 2 - Last state row index:
%     Previous version used sma.current_state to find the last added trialnum
%     state. This is unreliable because current_state behaviour (last added vs
%     next empty) differs across BControl versions and caused the wrong row to
%     be modified. This version uses length(preamble) + nbits + 1 which is
%     always the exact row of the last added state.
%
% Signal format on DIO line:
%   Preamble : one or more HIGH bits (sync marker), default [1]
%   15-bit binary representation of trialnum, MSB first
%   Total states added : length(preamble) + 15  (default = 16)
%   Total signal at 5ms/state : 80ms
%
% USAGE:
%   sma = add_ephys_trial_indicator(sma, trialnum)
%   sma = add_ephys_trial_indicator(sma, trialnum, 'time_per_state', 5e-3)
%   sma = add_ephys_trial_indicator(sma, trialnum, 'preamble', [1 1])
%   sma = add_ephys_trial_indicator(sma, trialnum, 'DIOLINE', 512)
%
% REQUIRED ARGUMENTS:
%   sma        StateMachineAssembler with full_trial_structure
%   trialnum   Positive integer (max 32767 = 2^15 - 1)
%
% OPTIONAL ARGUMENTS:
%   'time_per_state'          Seconds per bit state. Default 800e-6.
%                             Recommended 5e-3 for reliable Neuropixels detection.
%   'preamble'                Numeric vector before trialnum bits.
%                             Default [1] (single HIGH sync pulse).
%   'indicator_states_name'   Name for added states. Default 'sending_trialnum'.
%   'DIOLINE'                 DIO line bitmask. Default 'from_settings'.
%
% Written by Arpit, based on add_trialnum_indicator by Carlos Brody.

function [sma] = add_ephys_trial_indicator(sma, trialnum, varargin)

    %% Parse arguments
    pairs = { ...
        'time_per_state',        800e-6              ; ...
        'preamble',              [1]                 ; ...
        'indicator_states_name', 'sending_trialnum'  ; ...
        'DIOLINE',               'from_settings'     ; ...
    };
    parseargs(varargin, pairs);

    %% Validate inputs
    if nargin < 2
        error('add_ephys_trial_indicator: Need at least sma and trialnum.');
    end
    if ~is_full_trial_structure(sma)
        error(['add_ephys_trial_indicator: Requires StateMachineAssembler ' ...
               'initialized with full_trial_structure flag.']);
    end
    if ~isnumeric(trialnum) || trialnum < 1 || trialnum ~= floor(trialnum)
        error('add_ephys_trial_indicator: trialnum must be a positive integer.');
    end
    nbits = 15;
    if trialnum >= 2^nbits
        warning('add_ephys_trial_indicator: trialnum %d exceeds 15-bit max (%d).', ...
            trialnum, 2^nbits - 1);
    end
    if time_per_state <= 0
        error('add_ephys_trial_indicator: time_per_state must be positive.');
    end

    %% Resolve DIO line
    if ischar(DIOLINE) && strcmp(DIOLINE, 'from_settings')
        try
            DIOLINE = bSettings('get', 'DIOLINES', 'trialnum_indicator');
        catch
            warning('add_ephys_trial_indicator: Could not read trialnum_indicator. No DOut.');
            DIOLINE = 0;
        end
    end
    if isnan(DIOLINE)
        warning('add_ephys_trial_indicator: DIOLINE is NaN, defaulting to 0.');
        DIOLINE = 0;
    end

    %% Find the Tup column index in sma.states
    TupCol = find(strcmp('Tup', sma.input_map(:,1)));
    TupCol = sma.input_map{TupCol, 2};

    %% FIX 1: Read first user state from state_0 BEFORE redirecting it
    % state_0 (row 1 of sma.states) Tup transition always points to the
    % first user state. For this BControl/Bpod framework that is state 40
    % (wait_for_cpoke). Reading it here means no hardcoding needed.
    first_user_state = sma.states{1, TupCol};

    % Guard against corrupted state_0 — should always be 40 for this framework
    if ~isnumeric(first_user_state) || first_user_state < 2
        error(['add_ephys_trial_indicator: state_0 Tup = %s, expected numeric >= 2. ' ...
            'Was add_ephys_trial_indicator called twice on the same SMA?'], ...
            num2str(first_user_state));
    end

    fprintf('[add_ephys_trial_indicator] Trial %d | first_user_state=%d | DIOLINE=%d | n_states=%d\n', ...
        trialnum, first_user_state, DIOLINE, length(preamble) + nbits);

    %% Save current_state and redirect to slot 1 to insert trialnum states
    orig_current_state = sma.current_state;
    sma.current_state = 1;

    %% Add preamble states (sync pulses)
    for i = 1:length(preamble)
        dout = preamble(i);
        if i == 1
            sma = add_state(sma, 'name', indicator_states_name, ...
                'self_timer', time_per_state, ...
                'input_to_statechange', {'Tup', 'current_state+1'}, ...
                'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
        else
            sma = add_state(sma, ...
                'self_timer', time_per_state, ...
                'input_to_statechange', {'Tup', 'current_state+1'}, ...
                'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
        end
    end

    %% Add 15 binary bit states encoding trialnum MSB first
    trialnum_bin = dec2bin(trialnum);
    trialnum_bin = [repmat('0', 1, nbits - length(trialnum_bin)) trialnum_bin];

    for i = 1:nbits
        dout = str2double(trialnum_bin(i));
        sma = add_state(sma, ...
            'self_timer', time_per_state, ...
            'input_to_statechange', {'Tup', 'current_state+1'}, ...
            'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
    end

    %% FIX 2: Set last trialnum state to jump to first_user_state
    % Deterministic row index: 1 preamble + 15 bits = 16 states starting at
    % row 2 (state 1). Last state is at row 1 + length(preamble) + nbits.
    % Adding 1 for MATLAB 1-based indexing of sma.states.
    % This does NOT rely on sma.current_state which is unreliable here.
    last_trialnum_row = 1 + length(preamble) + nbits;  % = 17 with default preamble
    sma.states{last_trialnum_row, TupCol} = first_user_state;
    fprintf('[add_ephys_trial_indicator] Row %d (last trialnum state) Tup set to %d.\n', ...
        last_trialnum_row, first_user_state);

    %% Redirect state_0 to trialnum sequence start (state 1)
    all_input_cols = cell2mat(sma.input_map(:,2))';
    for i = 1:length(all_input_cols)
        sma.states{1, all_input_cols(i)} = 1;
    end
    fprintf('[add_ephys_trial_indicator] State_0 redirected to 1 (was %d).\n', first_user_state);

    %% Restore current_state
    sma.current_state = orig_current_state;

end