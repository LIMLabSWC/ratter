function [ok] = selftest()
% ok = selftest()   Checks of the emulator and the virtual rat, no protocol
% needed. Run with VirtualRat('selftest') after newstartup. It switches
% this MATLAB session to the emulator if needed and switches back after.
% Each check prints PASS or FAIL; ok is true if all pass.

global fake_rp_box
saved_rp = fake_rp_box;
switched = ~isequal(bSettings('get', 'RIGS', 'fake_rp_box'), 3);
if switched
    f = fullfile(tempdir, 'VirtualRat_emulator.conf');
    fid = fopen(f, 'w'); fprintf(fid, 'RIGS; fake_rp_box; 3;\n'); fclose(fid);
    bSettings('load', f);
    fake_rp_box = 3;
end
old_rat = [];
if isappdata(0, 'VirtualRat'), old_rat = getappdata(0, 'VirtualRat'); rmappdata(0, 'VirtualRat'); end

results = {};
try
    results(end+1, :) = check('state matrices are accepted (classic and happenings)', @t_accept);
    results(end+1, :) = check('happenings give the same trial as the classic matrix', @t_same);
    results(end+1, :) = check('level happenings (Chi, wave _Hi/_Lo) fire like on Bpod', @t_levels);
    results(end+1, :) = check('perfect rat is rewarded on every trial (20x speed)', @t_perfect);
    results(end+1, :) = check('light-chasing rat follows the LED; random rat is ~50%', @t_strategies);
catch err
    results(end+1, :) = {'selftest crashed', false, err.message};
end

% restore
if isappdata(0, 'VirtualRat'), rmappdata(0, 'VirtualRat'); end
if ~isempty(old_rat), setappdata(0, 'VirtualRat', old_rat); end
if switched
    code = bSettings('get', 'GENERAL', 'Main_Code_Directory');
    if ~ischar(code) || isempty(code), code = pwd; end
    bSettings('load', fullfile(code, 'Settings', 'Settings_Default.conf'), fullfile(code, 'Settings', 'Settings_Custom.conf'));
    fake_rp_box = saved_rp;
end

fprintf('\nVirtualRat selftest\n');
for i = 1:size(results, 1)
    if results{i, 2}, tag = 'PASS'; else tag = 'FAIL'; end
    fprintf('  %s  %s  %s\n', tag, results{i, 1}, results{i, 3});
end
ok = all([results{:, 2}]);
return;


function r = check(name, fn)
try
    [pass, msg] = fn();
catch err
    pass = false; msg = ['error: ' err.message];
end
r = {name, pass, msg};
close_emulators();
return;


function close_emulators()
figs = findall(0, 'Type', 'figure');
for i = 1:numel(figs)
    nm = get(figs(i), 'Name');
    if ischar(nm) && strncmp(nm, 'State Machine Emulator', 22), delete(figs(i)); end
end
return;


% ======================================================================
function [pass, msg] = t_accept()
for happ = [0 1]
    sm = new_sm();
    [~, ~, sm] = send(task_sma(happ, 'L'), sm, 'run_trial_asap', 0); %#ok<ASGLU>
end
pass = true; msg = '';
return;


function [pass, msg] = t_same()
seq = cell(1, 2);
for happ = [0 1]
    sm = new_sm();
    sma = task_sma(happ, 'L');
    [~, ~, sm] = send(sma, sm, 'run_trial_asap', 0);
    sm = Run(sm); sm = ForceState0(sm);
    t0 = GetTime(sm);
    sm = ScheduleInput(sm, [1 1 2 2], [1 0 1 0], t0 + [0.3 1.0 1.3 1.8]);
    pump(sm, 2.2 / 1);
    ev = GetEvents2(sm, 1, GetEventCounter(sm));
    p = disassemble(sma, ev, 'parsed_structure', 1);
    seq{happ+1} = [round(1000 * (p.states.hold - t0)) ; round(1000 * (p.states.hit - t0))];
end
pass = isequal(seq{1}, seq{2}) && ~isempty(seq{1});
msg = sprintf('hold/hit entry-exit (ms): %s', mat2str(seq{2}(:)'));
return;


function [pass, msg] = t_levels()
sm = new_sm();
sma = StateMachineAssembler('full_trial_structure', 'use_happenings', 1);
sma = add_scheduled_wave(sma, 'name', 'w', 'preamble', 0.3, 'sustain', 0.3);
sma = add_state(sma, 'name', 'pre', 'self_timer', 0.4, 'input_to_statechange', {'Tup', 'a'});
sma = add_state(sma, 'name', 'a',   'input_to_statechange', {'Chi', 'b'});
sma = add_state(sma, 'name', 'b',   'output_actions', {'SchedWaveTrig', 'w'}, 'input_to_statechange', {'Clo', 'x', 'w_Hi', 'd'});
sma = add_state(sma, 'name', 'd',   'input_to_statechange', {'w_Lo', 'e'});
sma = add_state(sma, 'name', 'e',   'self_timer', 0.1, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
sma = add_state(sma, 'name', 'x',   'self_timer', 0.1, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
[~, ~, sm] = send(sma, sm, 'run_trial_asap', 0);
sm = Run(sm); sm = ForceState0(sm);
sm = ScheduleInput(sm, 1, 1, GetTime(sm) + 0.1);
pump(sm, 1.5);
ev = GetEvents2(sm, 1, GetEventCounter(sm));
d = disassemble(sma, ev);
path = d(~strcmp(d(:,1), d(:,4)), 4)';
want = {'pre', 'a', 'b', 'd', 'e', 'check_next_trial_ready'};
got = path(find(strcmp(path, 'pre'), 1):end);
pass = numel(got) >= numel(want) && isequal(got(1:numel(want)), want);
msg = sprintf('path: %s', sprintf('%s ', got{:}));
return;


function [pass, msg] = t_perfect()
[st, wall, holds] = run_rat('perfect', 20, 20, 1);
pass = st.trials >= 20 && st.rewarded == st.trials && all(abs(holds - holds(1)) < 1e-6);
msg = sprintf('%d/%d rewarded, %.1f s wall (%.2f s/trial)', st.rewarded, st.trials, wall, wall / max(1, st.trials));
return;


function [pass, msg] = t_strategies()
stl = run_rat('light', 20, 20, 1);
str = run_rat('random', 40, 20, 0);
pass = stl.rewarded == stl.trials && str.rewarded > 0.2 * str.trials && str.rewarded < 0.8 * str.trials;
msg = sprintf('light %d/%d, random %d/%d', stl.rewarded, stl.trials, str.rewarded, str.trials);
return;


% ======================================================================
function [st, wall, holds] = run_rat(strategy, ntrials, speed, happ)
VirtualRat('set', 'strategy', strategy, 'speed', speed);
sm = new_sm();
S = getappdata(0, 'VirtualRat');
S.target_trials = ntrials; S.n_started = 0; S.stop_requested = 0;
S.stats = struct('trials', 0, 'rewarded', 0, 'choices', zeros(1, 3));
S.on_target = @() [];
setappdata(0, 'VirtualRat', S);
VirtualRat('attach', sm);
sides = 'LR';
side = sides(ceil(2 * rand));
sma = task_sma(happ, side);
[~, ~, sm] = send(sma, sm, 'run_trial_asap', 0);
sm = Run(sm); sm = ForceState0(sm);
t0 = tic; sent = 0; all_holds = [];
while toc(t0) < 120
    FlushQueue(sm);
    ev = GetEvents2(sm, 1, GetEventCounter(sm));
    S = getappdata(0, 'VirtualRat');
    if S.stop_requested, break; end
    n35 = sum(ev(:,4) == 35 & ev(:,1) ~= 35);
    if n35 > sent        % trial over: send the next one (like prepare_next_trial)
        side = sides(ceil(2 * rand));
        sma = task_sma(happ, side);
        [~, ~, sm] = send(sma, sm, 'run_trial_asap', 1);
        sent = n35;
    end
    pause(0.1);
end
wall = toc(t0);
S = getappdata(0, 'VirtualRat');
st = S.stats;
% hold durations: entry->exit of the 'hold' state (same in every trial)
ev = GetEvents2(sm, 1, GetEventCounter(sm));
pp = disassemble(task_sma(happ, side), ev, 'parsed_structure', 1);
holds = diff(pp.states.hold, 1, 2); holds = holds(~isnan(holds));
if isempty(holds), holds = 0; end
SetRatCallback(sm, []);
return;


function sm = new_sm()
close_emulators();
sm = SoftSMMarkII; sm = Initialize(sm);
return;


function pump(sm, secs)
t = tic;
while toc(t) < secs, FlushQueue(sm); pause(0.03); end
return;


function sma = task_sma(happ, side)
% centre hold 0.5 s -> LED on the rewarded side -> poke it for water
[water, led] = masks();
if side == 'L', k = 2; else k = 3; end
sma = StateMachineAssembler('full_trial_structure', 'use_happenings', happ);
sma = add_scheduled_wave(sma, 'name', 'stim', 'preamble', 0.1, 'sustain', 0.2);
sma = add_state(sma, 'name', 'wait_c', 'input_to_statechange', {'Cin', 'hold'});
sma = add_state(sma, 'name', 'hold', 'self_timer', 0.5, 'output_actions', {'SchedWaveTrig', 'stim'}, ...
    'input_to_statechange', {'Tup', 'choice', 'Cout', 'viol'});
if side == 'L', ok = 'Lin'; bad = 'Rin'; else ok = 'Rin'; bad = 'Lin'; end
sma = add_state(sma, 'name', 'choice', 'output_actions', {'DOut', led(k)}, ...
    'input_to_statechange', {ok, 'hit', bad, 'miss'});
sma = add_state(sma, 'name', 'hit', 'self_timer', 0.1, 'output_actions', {'DOut', water(k)}, ...
    'input_to_statechange', {'Tup', 'check_next_trial_ready'});
sma = add_state(sma, 'name', 'miss', 'self_timer', 0.5, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
sma = add_state(sma, 'name', 'viol', 'self_timer', 0.5, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
return;


function [water, led] = masks()
water = [1 4 16]; led = [2 8 32];   % C L R defaults
names = {'center1water', 'left1water', 'right1water'; 'center1led', 'left1led', 'right1led'};
for k = 1:3
    v = bSettings('get', 'DIOLINES', names{1, k}); if isnumeric(v) && ~isnan(v), water(k) = v; end
    v = bSettings('get', 'DIOLINES', names{2, k}); if isnumeric(v) && ~isnan(v), led(k) = v; end
end
return;
