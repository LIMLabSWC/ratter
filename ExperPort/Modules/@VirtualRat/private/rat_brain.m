function [acts] = rat_brain(info)
% acts = rat_brain(info)   The virtual rat (called by @SoftSMMarkII).
%
% Called in emulator time each time a new state is entered and after the
% rat's last poke has been applied (see SoftSMMarkII/SetRatCallback.m).
% Returns the pokes to make: N x 3 [emulator_time line value].
%
% The rat knows nothing about the protocol. From the state matrix it
% works out, for every state and poke position, how many steps it is from
% a state that opens a water valve (DIOLINES *water*, directly or through
% a scheduled wave). It then waits when waiting gets it there soonest and
% otherwise pokes. Where it can poke into different ports that lead to
% different outcomes (a "choice"), the strategy decides which port; see
% VirtualRat.m for the strategies.

acts = [];
S = getappdata(0, 'VirtualRat');
if isempty(S) || ~isfield(S, 'active') || ~S.active, return; end

ts = info.ts;

% ---------------------------------------------------------------- model
if isempty(S.model) || (strcmp(info.reason, 'state') && info.state == 0) || ...
        ~isequal(size(S.model.matrix), size(info.matrix)) || ...
        S.model.use_happ ~= info.use_happenings
    S.model = build_model(info, S);
end
M = S.model;
s = info.state;

% ------------------------------------------------------ trial bookkeeping
if strcmp(info.reason, 'state')
    if s == 0
        if S.trial.active
            S = finish_trial(S);
        end
        S.trial = struct('active', 1, 'choice', 0, 'rewarded', 0, 'start', ts);
        S.n_started = S.n_started + 1;
        if S.target_trials > 0 && S.n_started > S.target_trials && ~S.stop_requested
            S.stop_requested = 1;
            setappdata(0, 'VirtualRat', S);
            request_stop(S);
            S = getappdata(0, 'VirtualRat');
        end
    elseif s+1 <= numel(M.reward) && M.reward(s+1)
        S.trial.rewarded = 1;
    end
end

% still carrying out the last decision?
if ts < S.busy_until - 1e-9
    setappdata(0, 'VirtualRat', S);
    return;
end
if S.stop_requested
    setappdata(0, 'VirtualRat', S);
    return;
end

P = S.params;
b = bits_of(info.input_state, M.nL);
c = current_port(b, M.nL);

% ------------------------------------------------------- possible moves
% waits: things that happen without the rat (Tup, waves)
W = wait_moves(M, s, b);
% acts: go to port p (leaving the current one first), leave, re-poke
A = act_moves(M, s, b, c);

dW = inf(1, numel(W)); for k = 1:numel(W), dW(k) = 1 + M.D(node(M, W(k).s, W(k).b)); end
dA = inf(1, numel(A)); for k = 1:numel(A), dA(k) = 1 + M.D(node(M, A(k).s, A(k).b)); end
if M.reward(s+1), dW(end+1) = 0; W(end+1) = struct('s', s, 'b', b); end  % already rewarded

bestW = min([dW Inf]); bestA = min([dA Inf]);

if isinf(bestW) && isinf(bestA)
    % Nothing in this matrix leads to water from here. If something will
    % happen by itself, wait; otherwise try something (stops deadlocks).
    if ~isempty(W) || M.timer(s+1) > 0
        acts = wake_if_needed(S, M, s, ts);
    else
        moving = find([A.s] ~= s);
        if ~isempty(moving)
            k = moving(ceil(rand * numel(moving)));
            acts = pokes_for(A(k), c, ts + 1 + 2*rand, P);
        else
            acts = wake(ts + 5);
        end
    end
    S = commit(S, acts);
    setappdata(0, 'VirtualRat', S);
    return;
end

if bestW <= bestA
    % Waiting is best (e.g. holding in the centre during fixation).
    acts = [];
    imp = P.impulsivity;
    if strcmp(P.strategy, 'learner'), imp = imp + 0.3 * exp(-S.n_total / P.learn_tau); end
    if c > 0 && imp > 0 && rand < imp
        lv = find(strcmp({A.kind}, 'leave'));
        if ~isempty(lv) && dA(lv) > bestW
            T = M.timer(s+1); if T <= 0, T = 1; end
            acts = [ts + 0.05 + rand * T, c, 0];       % breaks fixation
        end
    end
    if isempty(acts), acts = wake_if_needed(S, M, s, ts); end
    S = commit(S, acts);
    setappdata(0, 'VirtualRat', S);
    return;
end

% ------------------------------------------------------------- acting
best = find(dA == bestA, 1);
% a choice: going to different ports leads to different states (at least
% one of them on the way to water, since bestA is finite here)
go = find(strcmp({A.kind}, 'go') & [A.s] ~= s);
choice_point = numel(unique([A(go).s])) >= 2 && any(go == best);
k = best;
if choice_point && ~isempty(go)
    k = choose(S, P, A, go, best, info, M);
end

pause_t = 0;
if isempty(W) && c == 0 && P.pause_prob > 0 && rand < P.pause_prob
    pause_t = -P.pause_mean * log(rand);              % takes a break before starting
end
acts = pokes_for(A(k), c, ts + pause_t, P);
if choice_point && S.trial.choice == 0 && strcmp(A(k).kind, 'go')
    S.trial.choice = A(k).port;
end
S = commit(S, acts);
setappdata(0, 'VirtualRat', S);
return;


% ======================================================================
function [k] = choose(S, P, A, go, best, info, M)
ports = [A(go).port];
if ~isempty(P.custom)
    cand = struct('port', num2cell(ports), 'name', M.port_names(ports), ...
        'dist', num2cell(arrayfun(@(i) 1 + M.D(node(M, A(i).s, A(i).b)), go)), ...
        'lit', num2cell(arrayfun(@(p) bitand(info.dout, M.led(p)) ~= 0, ports)));
    try
        j = feval(P.custom, cand, info, S.history);
        if ~isempty(j) && j >= 1 && j <= numel(go), k = go(j); return; end
    catch err
        fprintf(2, 'VirtualRat: custom strategy failed: %s\n', err.message);
    end
end
others = go(go ~= best);
pick = @(v) v(ceil(rand * numel(v)));
switch P.strategy
    case 'perfect'
        k = best;
    case {'noisy', 'learner'}
        acc = P.accuracy;
        if strcmp(P.strategy, 'learner')
            acc = 0.5 + (P.accuracy - 0.5) * (1 - exp(-S.n_total / P.learn_tau));
        end
        if rand < acc || isempty(others), k = best; else k = pick(others); end
    case 'random'
        k = pick(go);
    case 'side'
        j = go(ports == P.bias_port);
        if ~isempty(j) && rand < P.bias, k = j(1); else k = pick(go); end
    case 'light'
        lit = arrayfun(@(p) bitand(info.dout, M.led(p)) ~= 0, ports);
        if any(lit), k = pick(go(lit)); else k = pick(go); end
    case 'wsls'
        if isempty(S.history), k = pick(go); return; end
        last = S.history(end, :);
        same = go(ports == last(1));
        diff = go(ports ~= last(1));
        if last(2) && ~isempty(same), k = same(1);
        elseif ~last(2) && ~isempty(diff), k = pick(diff);
        else k = pick(go);
        end
    otherwise
        k = best;
end
return;


function [acts] = pokes_for(mv, c, t0, P)
rt = P.rt_min - P.rt_mean * log(rand);
t = t0 + rt;
acts = zeros(0, 3);
if c > 0
    acts(end+1, :) = [t c 0];
    t = t + P.travel;
end
if mv.port > 0
    acts(end+1, :) = [t mv.port 1];
end
return;


function [S] = commit(S, acts)
if ~isempty(acts)
    real = acts(acts(:,2) > 0, 1);
    if ~isempty(real), S.busy_until = max(real); end
    wk = acts(acts(:,2) == 0, 1);
    if ~isempty(wk), S.next_wake = max(wk); end
end
return;


function [acts] = wake_if_needed(S, M, s, ts)
% Waiting on something with no state timer (a wave, a level): ask to be
% woken up later, in case nothing happens.
acts = [];
if M.timer(s+1) <= 0 && S.next_wake < ts, acts = wake(ts + 3); end
return;


function [acts] = wake(t)
acts = [t 0 0];      % line 0 = no poke, just call the rat again
return;


function [S] = finish_trial(S)
S.history(end+1, :) = [S.trial.choice S.trial.rewarded];
S.n_total = S.n_total + 1;
S.stats.trials = S.stats.trials + 1;
S.stats.rewarded = S.stats.rewarded + S.trial.rewarded;
if S.trial.choice > 0
    S.stats.choices(S.trial.choice) = S.stats.choices(S.trial.choice) + 1;
end
S.trial.active = 0;
return;


function [] = request_stop(S)
if ~isempty(S.on_target)
    feval(S.on_target);
    return;
end
try
    t = timer('StartDelay', 0.05, 'TimerFcn', @(varargin) dispatcher('Stop'), ...
        'StopFcn', @(tt, varargin) delete(tt));
    start(t);
catch
    dispatcher('Stop');
end
return;


% ======================================================================
%   STATE-MATRIX MODEL
% ======================================================================
function [M] = build_model(info, S)
M.matrix   = info.matrix;
M.use_happ = info.use_happenings;
M.nL       = max(3, numel(info.input_state));
M.NB       = 2^M.nL;
M.port_names = S.port_names;
M.led      = S.led_mask;
nS = size(info.matrix, 1);
ie = info.input_events;
M.ie = ie;
tc = info.tup_col;
M.tup   = info.matrix(:, tc);
M.timer = info.matrix(:, tc + 1);
nIn = numel(ie);

% outputs
dout = zeros(nS, 1); swtrig = zeros(nS, 1);
for i = 1:numel(info.output_routing)
    col = nIn + 2 + i;
    if col > size(info.matrix, 2), continue; end
    switch info.output_routing{i}.type
        case 'dout',       dout   = info.matrix(:, col);
        case 'sched_wave', swtrig = info.matrix(:, col);
    end
end
water_waves = [];
for i = 1:numel(info.sched_waves)
    w = info.sched_waves(i);
    if w.dioLine >= 0 && bitand(2^w.dioLine, S.water_mask), water_waves(end+1) = w.id; end %#ok<AGROW>
end
M.reward = false(nS, 1);
for st = 1:nS
    r = bitand(uint32(abs(dout(st))), uint32(S.water_mask)) ~= 0;
    if ~r && swtrig(st) > 0
        for id = water_waves, if bitand(uint32(swtrig(st)), uint32(2^id)), r = true; end; end
    end
    M.reward(st) = r;
end

% transitions on input edges, waits and levels
if ~M.use_happ
    M.wavecols = find(ie == 0);
else
    spec = info.happ_spec;
    names = {spec.name};
    dets  = {spec.detectorFunctionName};
    code  = zeros(1, numel(spec));
    code(strcmp(dets, 'line_in'))   = 1; code(strcmp(dets, 'line_out'))  = 2;
    code(strcmp(dets, 'line_high')) = 3; code(strcmp(dets, 'line_low'))  = 4;
    code(strcmp(dets, 'wave_in'))   = 5; code(strcmp(dets, 'wave_out'))  = 6;
    code(strcmp(dets, 'wave_high')) = 7; code(strcmp(dets, 'wave_low'))  = 8;
    num = zeros(1, numel(spec));
    for i = 1:numel(spec), if isnumeric(spec(i).inputNumber) && ~isempty(spec(i).inputNumber), num(i) = spec(i).inputNumber(1); end; end
    M.H = cell(nS, 1);   % per state: [code num dest] rows
    for st = 1:min(nS, numel(info.happ_list))
        L = info.happ_list{st};
        rows = zeros(0, 3);
        for j = 1:2:numel(L) - 1
            k = find(strcmp(names, L{j}));
            if isempty(k), continue; end
            k = k(end);
            rows(end+1, :) = [code(k) num(k) L{j+1}]; %#ok<AGROW>
        end
        M.H{st} = rows;
    end
end

% distance to water for every (state, poke bits) node: backward BFS
nN = nS * M.NB;
succ = cell(nN, 1);
for st = 0:nS-1
    for bb = 0:M.NB-1
        n = st * M.NB + bb + 1;
        nx = zeros(0, 1);
        Wm = wait_moves(M, st, bb);
        for k = 1:numel(Wm), nx(end+1, 1) = node(M, Wm(k).s, Wm(k).b); end %#ok<AGROW>
        Am = act_moves(M, st, bb, current_port(bb, M.nL));
        for k = 1:numel(Am), nx(end+1, 1) = node(M, Am(k).s, Am(k).b); end %#ok<AGROW>
        succ{n} = unique(nx);
    end
end
pred = cell(nN, 1);
for n = 1:nN, for m = succ{n}', pred{m} = [pred{m} n]; end; end
D = inf(nN, 1);
queue = [];
for st = 0:nS-1
    if M.reward(st+1)
        idx = st * M.NB + (0:M.NB-1) + 1;
        D(idx) = 0; queue = [queue idx]; %#ok<AGROW>
    end
end
head = 1;
while head <= numel(queue)
    n = queue(head); head = head + 1;
    for m = pred{n}
        if isinf(D(m)), D(m) = D(n) + 1; queue(end+1) = m; end %#ok<AGROW>
    end
end
M.D = D;
return;


function [n] = node(M, s, b)
n = s * M.NB + b + 1;
return;


function [b] = bits_of(input_state, nL)
b = 0;
for l = 1:min(nL, numel(input_state)), if input_state(l), b = b + 2^(l-1); end; end
return;


function [c] = current_port(b, nL)
c = 0;
for l = 1:nL, if bitand(b, 2^(l-1)), c = l; return; end; end
return;


function [W] = wait_moves(M, s, b)
W = struct('s', {}, 'b', {});
if M.timer(s+1) > 0 && M.tup(s+1) ~= s
    W(end+1) = struct('s', level_chain(M, M.tup(s+1), b), 'b', b);
end
if ~M.use_happ
    for col = M.wavecols
        d = M.matrix(s+1, col);
        if d ~= s, W(end+1) = struct('s', d, 'b', b); end %#ok<AGROW>
    end
else
    R = M.H{s+1};
    for k = 1:size(R, 1)
        if R(k, 1) >= 5 && R(k, 3) ~= s
            W(end+1) = struct('s', level_chain(M, R(k, 3), b), 'b', b); %#ok<AGROW>
        end
    end
end
return;


function [A] = act_moves(M, s, b, c)
A = struct('kind', {}, 'port', {}, 's', {}, 'b', {});
s1 = s; b1 = b;
if c > 0
    s1 = model_input(M, s, b, c, 0);
    b1 = b - 2^(c-1);
    A(end+1) = struct('kind', 'leave', 'port', 0, 's', s1, 'b', b1);
end
for p = 1:M.nL
    s2 = model_input(M, s1, b1, p, 1);
    if p == c, kind = 'repoke'; else kind = 'go'; end
    A(end+1) = struct('kind', kind, 'port', p, 's', s2, 'b', double(bitor(uint32(b1), uint32(2^(p-1))))); %#ok<AGROW>
end
return;


function [d] = model_input(M, s, b, line, val)
% state after input `line` goes to val, with poke bits b before the edge
d = s;
if ~M.use_happ
    if val, col = find(M.ie == line, 1); else col = find(M.ie == -line, 1); end
    if ~isempty(col), d = M.matrix(s+1, col); end
    return;
end
if val, b2 = bitor(b, 2^(line-1)); cd = 1; else b2 = bitand(b, bitcmp(uint32(2^(line-1)))); cd = 2; end
b2 = double(b2);
R = M.H{s+1};
for k = size(R, 1):-1:1
    if R(k, 1) == cd && R(k, 2) == line, d = R(k, 3); break; end
end
d = level_chain(M, d, b2);
return;


function [s] = level_chain(M, s, b)
if ~M.use_happ, return; end
for guard = 1:5
    R = M.H{s+1}; moved = 0;
    for k = 1:size(R, 1)
        if (R(k, 1) == 3 || R(k, 1) == 4) && R(k, 3) ~= s
            hi = R(k, 2) >= 1 && bitand(b, 2^(R(k, 2) - 1)) ~= 0;
            if (R(k, 1) == 3 && hi) || (R(k, 1) == 4 && ~hi)
                s = R(k, 3); moved = 1; break;
            end
        end
    end
    if ~moved, return; end
end
return;
