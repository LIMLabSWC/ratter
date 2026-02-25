% [sma] = add_ephys_trial_indicator(sma, trialnum, ...)
%
% Sends a binary trial number signal on a DIO line for synchronisation with
% neural recording systems (e.g. Neuropixels via Open Ephys or SpikeGLX).
%
% This is a replacement for add_trialnum_indicator that correctly handles
% Bpod/BControl implementations where full_trial_structure pre-allocates
% more than 39 framework states (user states begin at position > 40).
% The original function hardcoded a jump to state 40 which is incorrect
% for systems where user states begin at position 59.
%
% Signal format on DIO line:
%   - Preamble: one or more HIGH bits (sync marker)
%   - 15-bit binary representation of trialnum, MSB first
%   - Total states added: length(preamble) + 15
%   - Default time per state: 1ms (800us requested, rounded up by FSM clock)
%
% USAGE:
%   sma = add_ephys_trial_indicator(sma, trialnum)
%   sma = add_ephys_trial_indicator(sma, trialnum, 'time_per_state', 1e-3)
%   sma = add_ephys_trial_indicator(sma, trialnum, 'preamble', [1 1])
%   sma = add_ephys_trial_indicator(sma, trialnum, 'DIOLINE', 32)
%
% REQUIRED ARGUMENTS:
%   sma        - StateMachineAssembler object, must use full_trial_structure
%   trialnum   - positive integer, trial number to encode (max 2^15 - 1 = 32767)
%
% OPTIONAL ARGUMENTS:
%   'time_per_state'   Time in seconds per bit state. Default 800e-6 (rounds
%                      to 1ms on FSM clock). Minimum reliable value is 500e-6.
%
%   'preamble'         Numeric vector of HIGH/LOW values sent before trialnum
%                      bits. Default [1] (single HIGH sync pulse).
%                      Use [1 0 1] for a 3-bit sync pattern etc.
%
%   'indicator_states_name'   Name assigned to all added states.
%                             Default 'sending_trialnum'.
%
%   'DIOLINE'          DIO line bitmask for output. Default 'from_settings'
%                      reads DIOLINES; trialnum_indicator from bSettings.
%                      Override with a numeric value e.g. 32 (= DIO line 6).
%
% RETURNS:
%   sma        - Updated StateMachineAssembler with trialnum states inserted
%                before the first user state. All user states are unchanged.
%
% KEY DIFFERENCE FROM add_trialnum_indicator:
%   Uses orig_current_state (dynamically determined) as the jump target
%   after the trialnum sequence, instead of the hardcoded value 40.
%   This correctly handles Bpod implementations where user states start
%   at positions other than 40 (e.g. position 59 in newer Bpod firmware).
%
% Written by Arpit, based on add_trialnum_indicator by Carlos Brody.
% Fixed: dynamic jump target instead of hardcoded state 40.

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
        error('add_ephys_trial_indicator: Need at least two arguments: sma and trialnum.');
    end

    if ~is_full_trial_structure(sma)
        error(['add_ephys_trial_indicator: Can only be used with StateMachineAssemblers ' ...
               'initialized with the ''full_trial_structure'' flag.']);
    end

    if ~isnumeric(trialnum) || trialnum < 1 || trialnum ~= floor(trialnum)
        error('add_ephys_trial_indicator: trialnum must be a positive integer.');
    end

    nbits = 15;
    if trialnum >= 2^nbits
        warning('add_ephys_trial_indicator: trialnum %d exceeds %d-bit max (%d). Will wrap.', ...
            trialnum, nbits, 2^nbits - 1);
    end

    if time_per_state <= 0
        error('add_ephys_trial_indicator: time_per_state must be positive.');
    end

    %% Resolve DIO line
    if strcmp(DIOLINE, 'from_settings')
        try
            DIOLINE = bSettings('get', 'DIOLINES', 'trialnum_indicator');
        catch
            warning('add_ephys_trial_indicator: Could not read trialnum_indicator from bSettings. No DOut will be generated.');
            DIOLINE = 0;
        end
    end

    if isnan(DIOLINE)
        warning('add_ephys_trial_indicator: DIOLINE is NaN, defaulting to 0. No DOut will be generated.');
        DIOLINE = 0;
    end

    %% Save current state pointer — this is the first user state (e.g. wait_for_cpoke)
    % This is the KEY fix: orig_current_state is where we jump BACK to after
    % the trialnum sequence, replacing the hardcoded value of 40 in the
    % original add_trialnum_indicator which assumed user states always
    % start at position 40. In newer Bpod firmware they start at 59.
    orig_current_state = sma.current_state;

    % fprintf('[add_ephys_trial_indicator] Trial %d: first user state at position %d, adding %d states.\n', ...
    %     trialnum, orig_current_state, length(preamble) + nbits);

    %% Move state pointer to position 1 to insert trialnum states at the start
    sma.current_state = 1;

    %% Add preamble states (sync signal before the binary trialnum)
    for i = 1:length(preamble)
        dout = preamble(i);
        if i == 1
            % First preamble state is named for identification
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

    %% Add 15 binary bit states encoding trialnum
    % Convert trialnum to 15-bit binary string, MSB first
    trialnum_bin = dec2bin(trialnum);
    trialnum_bin = [repmat('0', 1, nbits - length(trialnum_bin)) trialnum_bin];

    for i = 1:length(trialnum_bin)
        dout = str2double(trialnum_bin(i));
        sma = add_state(sma, ...
            'self_timer', time_per_state, ...
            'input_to_statechange', {'Tup', 'current_state+1'}, ...
            'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
    end

    %% Fix last state: jump to first user state instead of current_state+1
    % THE KEY FIX: use orig_current_state (e.g. 59) not hardcoded 40
    TupCol = find(strcmp('Tup', sma.input_map(:,1)));
    TupCol = sma.input_map{TupCol, 2};
    sma.states{sma.current_state, TupCol} = orig_current_state;

    %% Redirect state_0 to jump to state 1 (start of trialnum sequence)
    % This ensures the trialnum sequence fires at the very beginning of
    % each trial before the user FSM starts
    all_input_cols = cell2mat(sma.input_map(:,2))';
    for i = 1:length(all_input_cols)
        sma.states{1, all_input_cols(i)} = 1;
    end

    %% Restore state pointer to original position
    sma.current_state = orig_current_state;

    % fprintf('[add_ephys_trial_indicator] Done. Last trialnum state jumps to state %d.\n', ...
    %     orig_current_state);

end