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
%   Uses scheduled waves triggered simultaneously from a single state.
%   Consecutive HIGH bits are merged into a single longer wave to minimise
%   wave count. This is critical because Bpod supports a limited number of
%   scheduled waves per trial (16-20 depending on hardware version).
%
%   Example - Trial 510 = 000000111111110 (7 consecutive HIGHs at slots 9-15):
%     Without merging: 8 waves (1 sync + 7 individual bit waves)
%     With merging:    2 waves (1 sync + 1 merged wave covering slots 9-15)
%
%   Worst case wave count after merging = number of separate HIGH runs + 1 sync
%   e.g. trial 21845 = 101010101010101 = 8 runs → 9 waves maximum
%
% SIGNAL FORMAT:
%   Slot 1      : always HIGH (sync/preamble marker)
%   Slots 2-16  : 15-bit binary encoding of trialnum, MSB first
%   Total duration : 16 x time_per_state (default 16 x 50ms = 800ms)
%
%   Decoder uses pulse onset time to determine start slot and pulse
%   duration to determine how many consecutive HIGH slots the pulse covers.
%
% CALL ORDER — must be called BEFORE any add_state calls:
%   sma = StateMachineAssembler('full_trial_structure','use_happenings',1);
%   % ... add_scheduled_wave calls ...
%   sma = add_ephys_trial_indicator(sma, n_done_trials+1, 'time_per_state', 50e-3);
%   sma = add_state(sma, 'name', 'wait_for_cpoke', ...);
%
% REQUIRED ARGUMENTS:
%   sma        StateMachineAssembler with full_trial_structure
%   trialnum   Positive integer (max 32767 = 2^15-1)
%
% OPTIONAL ARGUMENTS:
%   'time_per_state'   Seconds per bit slot. Default 50e-3 (50ms).
%                      Total burst = 16 x 50ms = 800ms default.
%                      Must be long enough for Neuropixels to detect reliably.
%                      Minimum recommended: 5e-3 (5ms).
%   'preamble'         Number of sync slots before data bits. Default 1.
%   'wave_name_prefix' Prefix for scheduled wave names. Default 'tni'.
%   'state_name'       Name of the triggering state. Default 'send_trialnum'.
%   'DIOLINE'          DIO bitmask. Default 'from_settings'.
%
% Written by Arpit, based on add_trialnum_indicator concept by Carlos Brody.
% Key optimisation: consecutive HIGH bits merged into single longer waves.

function [sma] = add_ephys_trial_indicator(sma, trialnum, varargin)

    %% Parse arguments
    pairs = { ...
        'time_per_state',  50e-3            ; ...
        'preamble',        1                ; ...
        'wave_name_prefix','tni'            ; ...
        'state_name',      'send_trialnum'  ; ...
        'DIOLINE',         'from_settings'  ; ...
    };
    parseargs(varargin, pairs);

    %% Validate inputs
    if nargin < 2
        error('add_ephys_trial_indicator: Need at least sma and trialnum.');
    end
    if ~is_full_trial_structure(sma)
        error('add_ephys_trial_indicator: Requires full_trial_structure flag.');
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

    %% Build full bit sequence: preamble HIGH bits + 15 data bits
    trialnum_bin  = dec2bin(trialnum);
    trialnum_bin  = [repmat('0', 1, nbits - length(trialnum_bin)) trialnum_bin];
    preamble_bits = ones(1, preamble);
    data_bits     = arrayfun(@(c) str2double(c), trialnum_bin);
    all_bits      = [preamble_bits, data_bits];  % length = preamble + 15

    total_slots   = length(all_bits);
    total_duration = total_slots * time_per_state;

    % fprintf('[add_ephys_trial_indicator] Trial %d | DIOLINE=%d | %d slots | %.0fms/slot | %.0fms total\n', ...
    %     trialnum, DIOLINE, total_slots, time_per_state*1000, total_duration*1000);
    % fprintf('[add_ephys_trial_indicator] Bits: %s\n', num2str(all_bits));

    %% Find runs of consecutive HIGH bits and merge into single waves
    % This minimises wave count: worst case = number of separate HIGH runs + 0
    % (preamble is always the first run)
    waves_to_add = [];  % struct array: preamble_time, sustain_time, wave_name

    slot = 1;
    run_count = 0;
    while slot <= total_slots
        if all_bits(slot) == 1
            % Start of a HIGH run — find how long it lasts
            run_start = slot;
            run_length = 0;
            while slot <= total_slots && all_bits(slot) == 1
                run_length = run_length + 1;
                slot = slot + 1;
            end
            run_count = run_count + 1;

            % One wave covers the entire run
            wave_preamble = (run_start - 1) * time_per_state;
            wave_sustain  = run_length * time_per_state;
            wave_name     = sprintf('%s_r%02d', wave_name_prefix, run_count);

            waves_to_add(end+1).wave_name     = wave_name;   %#ok<AGROW>
            waves_to_add(end).wave_preamble   = wave_preamble;
            waves_to_add(end).wave_sustain    = wave_sustain;
            waves_to_add(end).run_start_slot  = run_start;
            waves_to_add(end).run_length      = run_length;

            % fprintf('[add_ephys_trial_indicator] Wave %s: slots %d-%d | preamble=%.0fms | sustain=%.0fms\n', ...
            %     wave_name, run_start, run_start+run_length-1, ...
            %     wave_preamble*1000, wave_sustain*1000);
        else
            % fprintf('[add_ephys_trial_indicator] Slot %02d: LOW\n', slot);
            slot = slot + 1;
        end
    end

    % fprintf('[add_ephys_trial_indicator] Total waves needed: %d\n', length(waves_to_add));

    %% Check wave count against Bpod limit
    n_existing_waves = size(sma.sched_waves, 1);
    n_new_waves      = length(waves_to_add);
    n_total_waves    = n_existing_waves + n_new_waves;
    bpod_wave_limit  = 16;  % Bpod state machine r2 supports 20 scheduled waves

    % fprintf('[add_ephys_trial_indicator] Existing waves: %d | New: %d | Total: %d / %d\n', ...
    %     n_existing_waves, n_new_waves, n_total_waves, bpod_wave_limit);

    if n_total_waves > bpod_wave_limit
        warning(['[add_ephys_trial_indicator] Trial %d requires %d waves but only %d slots available ' ...
            '(%d existing + %d new = %d > %d limit). ' ...
            'Skipping trialnum indicator for this trial. ' ...
            'Use EphysTrig 400ms pulse for trial boundary detection instead.'], ...
            trialnum, n_new_waves, bpod_wave_limit - n_existing_waves, ...
            n_existing_waves, n_new_waves, n_total_waves, bpod_wave_limit);

        % Add a single dummy state so state count stays consistent
        % wait_for_cpoke still lands at same position every trial
        sma = add_state(sma, 'name', state_name, ...
            'self_timer', 0.001, ...
            'input_to_statechange', {'Tup', 'current_state+1'});

        % fprintf('[add_ephys_trial_indicator] Dummy state added. wait_for_cpoke at %d.\n', ...
        %     sma.current_state);
        return;
    end

    %% Add scheduled waves
    wave_names_to_trigger = {};
    for w = 1:length(waves_to_add)
        sma = add_scheduled_wave(sma, ...
            'name',     waves_to_add(w).wave_name, ...
            'preamble', waves_to_add(w).wave_preamble, ...
            'sustain',  waves_to_add(w).wave_sustain, ...
            'DOut',     DIOLINE, ...
            'loop',     0);
        wave_names_to_trigger{end+1} = waves_to_add(w).wave_name; %#ok<AGROW>
    end

    %% Build trigger string
    trigger_string = wave_names_to_trigger{1};
    for k = 2:length(wave_names_to_trigger)
        trigger_string = [trigger_string '+' wave_names_to_trigger{k}]; %#ok<AGROW>
    end

    % fprintf('[add_ephys_trial_indicator] Trigger string: %s\n', trigger_string);

    %% Add single triggering state
    sma = add_state(sma, 'name', state_name, ...
        'self_timer', total_duration + 0.001, ...
        'output_actions', {'SchedWaveTrig', trigger_string}, ...
        'input_to_statechange', {'Tup', 'current_state+1'});

    % fprintf('[add_ephys_trial_indicator] Done. Triggering state at pos %d, wait_for_cpoke at %d.\n', ...
    %     sma.current_state - 1, sma.current_state);

end