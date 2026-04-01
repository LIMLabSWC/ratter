% [sma] = add_ephys_trial_indicator(sma, trialnum, ...)
%
% Sends a binary trial number signal on a DIO line at the START of each
% trial for synchronisation with Neuropixels recordings via Open Ephys or
% SpikeGLX.
%
% DESIGN:
%   This function must be called BEFORE any add_state calls in
%   prepare_next_trial. It appends 16 states (1 sync + 15 binary bits)
%   directly into user state space (positions 40-55), immediately before
%   wait_for_cpoke. state_0 already points to position 40 via the
%   full_trial_structure framework, so the trialnum sequence fires
%   automatically at trial start with no state_0 manipulation needed.
%
%   Trial flow:
%     state_0 (pos 40) → trialnum states (pos 40-55) → wait_for_cpoke (pos 56) → ...
%
%   This is fundamentally different from add_trialnum_indicator which
%   inserted states at framework positions 1-16. Bpod does not execute
%   DOut actions for framework states, so those pulses were never sent.
%   This version inserts states in user space where Bpod executes DOut.
%
% DUMMY STATE NOTE:
%   No dummy/padding states are needed. This function always adds exactly
%   length(preamble) + 15 states (default = 16) unconditionally, so there
%   is no branch-dependent count mismatch. All subsequent user states
%   (wait_for_cpoke onwards) are simply shifted up by 16 positions, which
%   is handled automatically by add_state.
%
% USAGE:
%   % Must be called BEFORE any add_state calls in prepare_next_trial:
%   sma = add_ephys_trial_indicator(sma, n_done_trials+1, 'time_per_state', 5e-3);
%   sma = add_state(sma, 'name', 'wait_for_cpoke', ...);
%   ...
%
% REQUIRED ARGUMENTS:
%   sma        StateMachineAssembler with full_trial_structure, no user
%              states added yet (current_state must equal first user slot)
%   trialnum   Positive integer to encode (max 32767 = 2^15 - 1)
%
% OPTIONAL ARGUMENTS:
%   'time_per_state'          Seconds per bit state. Default 5e-3 (5ms).
%                             Total burst = 16 x 5ms = 80ms.
%                             Minimum reliable value for Neuropixels: 1e-3.
%   'preamble'                Numeric vector of HIGH/LOW before trialnum bits.
%                             Default [1] (single HIGH sync pulse).
%   'indicator_states_name'   Name for the first added state only.
%                             Default 'sending_trialnum'.
%   'DIOLINE'                 DIO bitmask. Default 'from_settings' reads
%                             DIOLINES; trialnum_indicator from bSettings.
%
% RETURNS:
%   sma   Updated SMA with trialnum states appended at current position.
%         current_state is advanced by length(preamble)+15 (= 16 default).
%
% Written by Arpit, based on add_trialnum_indicator by Carlos Brody.
% Key fix: states inserted in user space (40+) not framework space (1-16).

% function [sma] = add_ephys_trial_indicator(sma, trialnum, varargin)
% 
%     %% Parse arguments
%     pairs = { ...
%         'time_per_state',        5e-3                ; ...
%         'preamble',              [1]                 ; ...
%         'indicator_states_name', 'sending_trialnum'  ; ...
%         'DIOLINE',               'from_settings'     ; ...
%     };
%     parseargs(varargin, pairs);
% 
%     %% Validate inputs
%     if nargin < 2
%         error('add_ephys_trial_indicator: Need at least sma and trialnum.');
%     end
%     if ~is_full_trial_structure(sma)
%         error(['add_ephys_trial_indicator: Requires StateMachineAssembler ' ...
%                'initialized with full_trial_structure flag.']);
%     end
%     if ~isnumeric(trialnum) || trialnum < 1 || trialnum ~= floor(trialnum)
%         error('add_ephys_trial_indicator: trialnum must be a positive integer.');
%     end
%     nbits = 15;
%     if trialnum >= 2^nbits
%         warning('add_ephys_trial_indicator: trialnum %d exceeds 15-bit max (%d).', ...
%             trialnum, 2^nbits - 1);
%     end
%     if time_per_state <= 0
%         error('add_ephys_trial_indicator: time_per_state must be positive.');
%     end
% 
%     %% Resolve DIO line
%     if ischar(DIOLINE) && strcmp(DIOLINE, 'from_settings')
%         try
%             DIOLINE = bSettings('get', 'DIOLINES', 'trialnum_indicator');
%         catch
%             warning('add_ephys_trial_indicator: Could not read trialnum_indicator. No DOut.');
%             DIOLINE = 0;
%         end
%     end
%     if isnan(DIOLINE)
%         warning('add_ephys_trial_indicator: DIOLINE is NaN, defaulting to 0.');
%         DIOLINE = 0;
%     end
% 
%     fprintf('[add_ephys_trial_indicator] default_DOut=%d | DIOLINE=%d | first bit DOut=%d | zero bit DOut=%d\n', ...
%     sma.default_DOut, DIOLINE, ...
%     sma.default_DOut + 1*DIOLINE, ...   % what HIGH bit sends
%     sma.default_DOut + 0*DIOLINE);      % what LOW bit sends
% 
%     %% Guard: must be called before any user states are added
%     % current_state should equal the first user slot (40 in this framework).
%     % If it is higher, user states have already been added and the trialnum
%     % sequence will not fire at trial start.
%     expected_first_user_state = 40;  % full_trial_structure constant for this framework
%     if sma.current_state ~= expected_first_user_state
%         warning(['add_ephys_trial_indicator: current_state = %d, expected %d. ' ...
%                  'This function should be called before any add_state calls. ' ...
%                  'Trialnum states will not fire at trial start.'], ...
%                  sma.current_state, expected_first_user_state);
%     end
% 
%     % fprintf('[add_ephys_trial_indicator] Trial %d | pos=%d | DIOLINE=%d | n_states=%d | %.0fms/state\n', ...
%     %     trialnum, sma.current_state, DIOLINE, length(preamble)+nbits, time_per_state*1000);
% 
%     %% Build binary string for trialnum (15 bits, MSB first)
%     trialnum_bin = dec2bin(trialnum);
%     trialnum_bin = [repmat('0', 1, nbits - length(trialnum_bin)) trialnum_bin];
% 
%     %% Add preamble states
%     % These are appended at current_state (= 40) in user space.
%     % Bpod executes DOut here — this is what was missing before.
%     for i = 1:length(preamble)
%         dout = preamble(i);
%         if i == 1
%             % First state is named for identification in state_name_list
%             sma = add_state(sma, 'name', indicator_states_name, ...
%                 'self_timer', time_per_state, ...
%                 'input_to_statechange', {'Tup', 'current_state+1'}, ...
%                 'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
%         else
%             sma = add_state(sma, ...
%                 'self_timer', time_per_state, ...
%                 'input_to_statechange', {'Tup', 'current_state+1'}, ...
%                 'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
%         end
%     end
% 
%     %% Add 15 binary bit states (MSB first)
%     for i = 1:nbits
%         dout = str2double(trialnum_bin(i));
%         sma = add_state(sma, ...
%             'self_timer', time_per_state, ...
%             'input_to_statechange', {'Tup', 'current_state+1'}, ...
%             'output_actions', {'DOut', sma.default_DOut + dout * DIOLINE});
%     end
% 
%     % After this, current_state = 56 (= 40 + 16).
%     % The next add_state call (wait_for_cpoke) will land at position 56.
%     % current_state+1 on the last trialnum state naturally falls into
%     % wait_for_cpoke — no manual Tup fix needed.
% 
%     % fprintf('[add_ephys_trial_indicator] Done. wait_for_cpoke will be at pos %d.\n', ...
%     %     sma.current_state);
% 
% end

% [sma] = add_ephys_trial_indicator(sma, trialnum, ...)
%
% Sends a binary trial number signal on a DIO line at the START of each
% trial for synchronisation with Neuropixels recordings (Open Ephys/SpikeGLX).
%
% IMPLEMENTATION:
%   Uses scheduled waves (not state DOut output_actions) to generate DIO
%   pulses. This is necessary because Bpod does not reliably execute DOut
%   output_actions from state transitions in this BControl implementation.
%   Scheduled waves use a separate direct hardware path — the same mechanism
%   used by the working 400ms EphysTrig pulse.
%
%   One scheduled wave is added per HIGH bit in the trialnum sequence.
%   Each wave has a staggered preamble so pulses fire sequentially:
%     bit 0 (sync):  preamble=0,             sustain=time_per_state
%     bit 1:         preamble=time_per_state, sustain=time_per_state (if HIGH)
%     bit 2:         preamble=2*time_per_state, ...
%   All waves are triggered simultaneously from a single state at trial start.
%
%   LOW bits produce no pulse. The decoder uses timing (position within the
%   80ms window) to determine bit value: pulse present = 1, absent = 0.
%
% SIGNAL FORMAT:
%   Slot 0  : always HIGH (sync/preamble marker)
%   Slots 1-15 : 15-bit binary encoding of trialnum, MSB first
%   Total duration : 16 x time_per_state (default 16 x 5ms = 80ms)
%
% CALL ORDER — must be called BEFORE any add_state calls:
%   sma = StateMachineAssembler('full_trial_structure','use_happenings',1);
%   % ... add_scheduled_wave calls ...
%   sma = add_ephys_trial_indicator(sma, n_done_trials+1, 'time_per_state', 5e-3);
%   sma = add_state(sma, 'name', 'wait_for_cpoke', ...);
%
% REQUIRED ARGUMENTS:
%   sma        StateMachineAssembler with full_trial_structure
%   trialnum   Positive integer (max 32767 = 2^15-1)
%
% OPTIONAL ARGUMENTS:
%   'time_per_state'   Seconds per bit slot. Default 5e-3 (5ms).
%                      Total burst = 16 x time_per_state = 80ms default.
%                      Minimum reliable for Neuropixels detection: 1e-3.
%   'preamble'         Number of sync pulses before trialnum bits.
%                      Default 1. Increase for more robust sync detection.
%   'wave_name_prefix' Prefix for scheduled wave names.
%                      Default 'tni' (trial number indicator).
%   'state_name'       Name of the single triggering state.
%                      Default 'send_trialnum'.
%   'DIOLINE'          DIO bitmask. Default 'from_settings' reads
%                      DIOLINES; trialnum_indicator from bSettings.
%
% Written by Arpit, based on add_trialnum_indicator concept by Carlos Brody.
% Key fix: scheduled waves instead of state DOut output_actions.

function [sma] = add_ephys_trial_indicator(sma, trialnum, varargin)

    %% Parse arguments
    pairs = { ...
        'time_per_state',  5e-3         ; ...
        'preamble',        1            ; ...
        'wave_name_prefix','tni'        ; ...
        'state_name',      'send_trialnum' ; ...
        'DIOLINE',         'from_settings' ; ...
    };
    parseargs(varargin, pairs);

    %% Validate inputs
    if nargin < 2
        error('add_ephys_trial_indicator: Need at least sma and trialnum.');
    end
    if ~is_full_trial_structure(sma)
        error(['add_ephys_trial_indicator: Requires full_trial_structure flag.']);
    end
    if ~isnumeric(trialnum) || trialnum < 1 || trialnum ~= floor(trialnum)
        error('add_ephys_trial_indicator: trialnum must be a positive integer.');
    end
    nbits = 15;
    if trialnum >= 2^nbits
        warning('add_ephys_trial_indicator: trialnum %d exceeds 15-bit max.', trialnum);
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

    %% Build binary string (15 bits MSB first)
    trialnum_bin = dec2bin(trialnum);
    trialnum_bin = [repmat('0', 1, nbits - length(trialnum_bin)) trialnum_bin];

    %% Build full bit sequence: preamble HIGH bits + 15 trialnum bits
    % preamble is always HIGH, trialnum bits are 0 or 1
    preamble_bits = ones(1, preamble);
    data_bits = arrayfun(@(c) str2double(c), trialnum_bin);
    all_bits = [preamble_bits, data_bits];  % length = preamble + 15

    total_slots = length(all_bits);
    total_duration = total_slots * time_per_state;

    % fprintf('[add_ephys_trial_indicator] Trial %d | DIOLINE=%d | %d slots | %.0fms total\n', ...
    %     trialnum, DIOLINE, total_slots, total_duration * 1000);
    % fprintf('[add_ephys_trial_indicator] Bits: %s\n', num2str(all_bits));

    %% Add one scheduled wave per HIGH bit
    % Each wave fires at its slot's start time (staggered preamble)
    % and stays HIGH for exactly one slot duration
    wave_names_to_trigger = {};

    for slot = 1:total_slots
        if all_bits(slot) == 1
            wave_name = sprintf('%s_%02d', wave_name_prefix, slot);
            slot_preamble = (slot - 1) * time_per_state;

            sma = add_scheduled_wave(sma, ...
                'name',    wave_name, ...
                'preamble', slot_preamble, ...
                'sustain',  time_per_state, ...
                'DOut',     DIOLINE, ...
                'loop',     0);

            wave_names_to_trigger{end+1} = wave_name; %#ok<AGROW>
            % fprintf('[add_ephys_trial_indicator] Wave %s: preamble=%.0fms HIGH\n', ...
            %     wave_name, slot_preamble*1000);
        else
            % fprintf('[add_ephys_trial_indicator] Slot %02d: LOW (no wave)\n', slot);
        end
    end

    %% Build trigger string: 'tni_01+tni_03+tni_05+...'
    trigger_string = strjoin(wave_names_to_trigger, '+');

    % fprintf('[add_ephys_trial_indicator] Trigger string: %s\n', trigger_string);

    %% Add single triggering state
    % Self-timer covers full burst duration + small margin
    sma = add_state(sma, 'name', state_name, ...
        'self_timer', total_duration + 0.001, ...
        'output_actions', {'SchedWaveTrig', trigger_string}, ...
        'input_to_statechange', {'Tup', 'current_state+1'});

    % After this, current_state+1 naturally falls into wait_for_cpoke

    % fprintf('[add_ephys_trial_indicator] Done. Triggering state at pos %d, wait_for_cpoke at %d.\n', ...
    %     sma.current_state - 1, sma.current_state);

end