function [obj, varargout] = VirtualRat(varargin)
% VirtualRat   Test any BControl protocol with a simulated rat, no rig needed.
%
% The rat runs inside the software state machine (@SoftSMMarkII). It reads
% each trial's state matrix and finds out by itself which pokes lead to
% water, so it needs nothing from the protocol. Sessions run faster than
% real time and are saved the way runrats saves them (without the svn
% commit). Nothing here is used on a rig: the emulator is only switched on
% for this MATLAB session, Settings_Custom.conf is not touched.
%
% QUICK START (MATLAB, from ExperPort):
%   Bpod('EMU');   newstartup;                        % as usual, no Bpod needed
%   VirtualRat('launch', 'Arpit2StepTraining', 'ratname', 'VR01');
%   VirtualRat('run', 'sessions', 5, 'trials', 300);  % blocks until done
%   VirtualRat('restore');  % or just restart MATLAB before running real rats
%
% ACTIONS
%   'launch', protocol, ...   switch this MATLAB session to the emulator,
%                             open dispatcher + protocol, load the rat's
%                             latest settings, attach the rat, open the
%                             control window. Options (name, value):
%        'experimenter'  'VirtualRat'  test experimenter name
%        'ratname'       'VR01'        test rat name (use a fake one!)
%        'speed'         10            emulator speed factor (1 = real time)
%        'strategy'      'perfect'     see STRATEGIES
%        plus any rat parameter (see PARAMETERS)
%   'run', ...                run sessions back to back. Options:
%        'sessions'  1      number of sessions
%        'trials'    300    trials per session
%        'params'    {}     protocol parameters to set at the start of every
%                           session: {'name', value; ...} (any protocol
%                           SoloParamHandle by name, e.g. lower thresholds)
%   'stop'                    end the current session (it is saved) and stop
%   'set', name, value, ...   change rat parameters or 'speed' on the fly
%   'status'                  print (and return) what the rat has done
%   'window'                  (re)open the control window
%   'restore'                 detach the rat, speed 1, back to the rig's
%                             own settings (then re-open dispatcher)
%   'selftest'                checks the emulator and the rat, no protocol
%                             needed: [~, ok] = VirtualRat('selftest')
%   'attach', sm              attach the rat to an emulator object directly
%
% STRATEGIES (what the rat does at a "choice": pokes into different ports
% that lead to different outcomes). Outside choices every rat does what
% leads to water soonest: initiates, holds, collects.
%   'perfect'   always the best port
%   'noisy'     best port with probability 'accuracy', otherwise another
%   'learner'   accuracy rises from 0.5 to 'accuracy' over ~'learn_tau'
%               trials (across sessions); breaks fixation more early on
%   'random'    any port
%   'side'      'bias_port' (default L) with probability 'bias'
%   'light'     a port whose LED is on (random if none)
%   'wsls'      win-stay / lose-shift on the last trial's choice
%   custom      'custom', @f   f(cand, info, history) returns the index into
%               cand (struct: port, name, dist, lit) or [] for the strategy
%
% PARAMETERS (emulator seconds)
%   'accuracy' 0.9  'bias' 0.8  'bias_port' 'L'  'impulsivity' 0 (chance to
%   break a hold)  'rt_min' 0.15  'rt_mean' 0.2  'travel' 0.25
%   'pause_prob' 0.03  'pause_mean' 5  'learn_tau' 1500  'seed' []
%
% EXAMPLE: Arpit2StepTraining through all stages in a few short sessions
%   fast = {'S1_trials',30; 'S1_switches',10; 'S1_go_start',10; 'S2_trials',30;
%     'S2_switches',10; 'S2_RColl_max',20; 'S3_min_trials',20; 'S3_frac_increase',0.05;
%     'S4_frac_increase',0.02; 'S4_min_session_trials',30; 'recent_window',20;
%     'S5_window',60; 'S5_min_per_cell',8; 'BL_min_trials',15; 'BL_switch_n',4;
%     'BL_cap',60; 'S6_window',60; 'S6_min_per_cell',8; 'S6_min_trials',40;
%     'S7_min_trials',60; 'S7_sessions',2; 'persist_trials',30;
%     'min_valid_trials',20; 'stall_sessions',3};
%   VirtualRat('run', 'sessions', 12, 'trials', 250, 'params', fast);
%
% NOTES
%   - Time spent waiting for dispatcher in check_next_trial_ready is
%     stretched by the speed factor (dispatcher polls in real time), so
%     recorded inter-trial gaps are longer than on a rig.
%   - Sounds are muted when speed > 1. Sounds triggered by scheduled waves
%     do not play in the emulator (StateMachineAssembler/send.m drops their
%     sound id for it); trial logic is not affected.
%   - Tests the BControl side (protocol, state matrices, saving). The Bpod
%     translation (sendSM2Bpod, HiFi, LED levels) is not exercised.

obj = class(struct, mfilename);
varargout = {};
if nargin == 0, return; end
if isa(varargin{1}, mfilename), varargin = varargin(2:end); end
if isempty(varargin), return; end
action = lower(varargin{1});
args = varargin(2:end);

switch action
    case 'launch',   launch(args{:});
    case 'run',      run_sessions(args{:});
    case 'stop',     stop_now();
    case 'set',      set_params(args{:});
    case 'status',   varargout = {status()};
    case 'window',   control_window();
    case 'restore',  restore();
    case 'selftest', varargout = {selftest()};
    case 'attach',   attach(args{:});
    case 'get_state',varargout = {getappdata(0, 'VirtualRat')};
    case 'gui',      gui_callback(args{:});
    otherwise
        error('VirtualRat: unknown action "%s". See help VirtualRat.', action);
end
return;


% ======================================================================
%   LAUNCH
% ======================================================================
function launch(protocol, varargin)
if nargin < 1 || ~ischar(protocol), error('VirtualRat(''launch'', protocolname, ...)'); end
S = new_state(varargin{:});
S.protocol = protocol;
setappdata(0, 'VirtualRat', S);

use_emulator(S.speed);

try dispatcher('close'); catch, end %#ok<CTCH>  (not open)
dispatcher('init');
open_session(S);
control_window();
fprintf(['VirtualRat: %s is running on the emulator for rat %s/%s at %gx.\n' ...
    '  VirtualRat(''run'', ''sessions'', N, ''trials'', T) to start.\n'], ...
    protocol, S.experimenter, S.ratname, S.speed);
return;


function S = new_state(varargin)
p = struct('experimenter', 'VirtualRat', 'ratname', 'VR01', 'speed', 10, ...
    'strategy', 'perfect', 'accuracy', 0.9, 'bias', 0.8, 'bias_port', 'L', ...
    'impulsivity', 0, 'rt_min', 0.15, 'rt_mean', 0.2, 'travel', 0.25, ...
    'pause_prob', 0.03, 'pause_mean', 5, 'learn_tau', 1500, 'seed', [], 'custom', []);
p = parse_pairs(p, varargin);
if ~isempty(p.seed)
    if exist('rng', 'file') || exist('rng', 'builtin'), rng(p.seed); else rand('twister', p.seed); end %#ok<RAND>
end

S.active = 0;
S.protocol = '';
S.experimenter = p.experimenter;
S.ratname = p.ratname;
S.speed = p.speed;
S.port_names = {'C', 'L', 'R'};          % emulator lines (dispatcher fixes these for fake_rp_box 3)
[S.water_mask, S.led_mask] = dio_masks(S.port_names);
S.params = rat_params(p, S.port_names);
S.model = [];
S.busy_until = -Inf;
S.next_wake = -Inf;
S.trial = struct('active', 0, 'choice', 0, 'rewarded', 0, 'start', 0);
S.history = zeros(0, 2);
S.n_total = 0;
S.n_started = 0;
S.target_trials = 0;
S.stop_requested = 0;
S.abort = 0;
S.on_target = [];
S.stats = new_stats(numel(S.port_names));
S.sessions = struct('n', {}, 'trials', {}, 'rewarded', {}, 'choices', {}, 'wall', {}, 'file', {});
S.saved = struct();
return;


function P = rat_params(p, port_names)
P = rmfield(p, {'experimenter', 'ratname', 'speed', 'seed'});
if ischar(P.bias_port)
    k = find(strcmpi(port_names, P.bias_port));
    if isempty(k), error('VirtualRat: unknown bias_port %s', P.bias_port); end
    P.bias_port = k;
end
known = {'perfect', 'noisy', 'learner', 'random', 'side', 'light', 'wsls'};
if ~ismember(P.strategy, known)
    error('VirtualRat: unknown strategy "%s" (one of %s)', P.strategy, sprintf('%s ', known{:}));
end
return;


function st = new_stats(nL)
st = struct('trials', 0, 'rewarded', 0, 'choices', zeros(1, nL));
return;


function [water, led] = dio_masks(port_names)
water = 0; led = zeros(1, numel(port_names));
try
    d = bSettings('get', 'DIOLINES', 'all');
catch %#ok<CTCH>
    d = {};
end
if isempty(d) || ~iscell(d)
    d = {'center1water', 1; 'center1led', 2; 'left1water', 4; 'left1led', 8; 'right1water', 16; 'right1led', 32};
end
prefixes = {'center', 'left', 'right'};
for i = 1:size(d, 1)
    nm = lower(d{i, 1}); v = d{i, 2};
    if ~isnumeric(v) || isnan(v), continue; end
    if ~isempty(strfind(nm, 'water')), water = bitor(water, v); end
    if ~isempty(strfind(nm, 'led'))
        for k = 1:3
            if strncmp(nm, prefixes{k}, numel(prefixes{k})), led(k) = bitor(led(k), v); end
        end
    end
end
return;


% Switch this MATLAB session to the emulator without touching any file
% in the repository: an extra settings file in tempdir is loaded on top.
function use_emulator(speed)
global fake_rp_box softsound_play_sounds
S = getappdata(0, 'VirtualRat');
if ~isfield(S.saved, 'fake_rp_box')
    S.saved.fake_rp_box = fake_rp_box;
    S.saved.softsound_play_sounds = softsound_play_sounds;
end
f = fullfile(tempdir, 'VirtualRat_emulator.conf');
fid = fopen(f, 'w');
if fid < 0, error('VirtualRat: cannot write %s', f); end
fprintf(fid, '%% Written by VirtualRat for this MATLAB session only.\nRIGS; fake_rp_box; 3;\n');
fclose(fid);
[err, msg] = bSettings('load', f);
if err, error('VirtualRat: could not switch settings to the emulator: %s', msg); end
fake_rp_box = 3;
if speed > 1, softsound_play_sounds = 0; end
setappdata(0, 'VirtualRat', S);
return;


% ======================================================================
%   SESSIONS
% ======================================================================
function open_session(S)
% Fresh protocol, the rat's newest settings, rat attached.
dispatcher('set_protocol', '');
dispatcher('set_protocol', S.protocol);
obj = dispatcher('get_protocol_object');
SavingSection(obj, 'set_info', S.experimenter, S.ratname);
f = newest_settings_file(S);
if ~isempty(f)
    dispatcher('runstart_disable');
    ok = load_solouiparamvalues(S.ratname, 'experimenter', S.experimenter, ...
        'owner', S.protocol, 'interactive', 0, 'settings_file', f);
    if ok
        SavingSection(obj, 'set_setting_info', f, now);
        pop_history(class(obj), 'include_non_gui', 1);
        feval(class(obj), obj, 'prepare_next_trial');
    end
    dispatcher('runstart_enable');
    [~, n] = fileparts(f);
    fprintf('VirtualRat: loaded settings %s\n', n);
else
    fprintf('VirtualRat: no settings yet for %s/%s, using protocol defaults\n', S.experimenter, S.ratname);
end
attach(dispatcher('get_state_machine'));
return;


function f = newest_settings_file(S)
% runrats only loads files dated today or earlier; back-to-back virtual
% sessions need the one just saved (dated tomorrow), so take the newest.
global Solo_datadir
f = '';
base = Solo_datadir;
if isempty(base), base = bSettings('get', 'GENERAL', 'Main_Data_Directory'); end
d = fullfile(base, 'Settings', S.experimenter, S.ratname);
u = dir(fullfile(d, ['settings_@' S.protocol '_' S.experimenter '_' S.ratname '_*.mat']));
if isempty(u), return; end
names = sort({u.name});
names = names(cellfun(@isempty, strfind(names, '_ASV')));
if isempty(names), return; end
f = fullfile(d, names{end});
return;


function attach(sm)
S = getappdata(0, 'VirtualRat');
if isempty(S), S = new_state(); end
if ~isa(sm, 'SoftSMMarkII')
    error('VirtualRat: dispatcher is not running the emulator (got %s).', class(sm));
end
S.model = [];
S.busy_until = -Inf;
S.next_wake = -Inf;
S.active = 1;
setappdata(0, 'VirtualRat', S);
SetSpeed(sm, S.speed);
SetRatCallback(sm, @rat_brain);
return;


function run_sessions(varargin)
o = parse_pairs(struct('sessions', 1, 'trials', 300, 'params', {{}}), varargin);
S = getappdata(0, 'VirtualRat');
if isempty(S) || isempty(S.protocol), error('VirtualRat: launch a protocol first.'); end
S.abort = 0;
setappdata(0, 'VirtualRat', S);
old_period = faster_polling(S.speed);
for k = 1:o.sessions
    S = getappdata(0, 'VirtualRat');
    if S.abort, break; end
    if k > 1 || S.n_started > 0, open_session(S); S = getappdata(0, 'VirtualRat'); end
    set_protocol_params(S.protocol, o.params);
    S.n_started = 0; S.stop_requested = 0; S.target_trials = o.trials;
    S.stats = new_stats(numel(S.port_names));
    S.trial.active = 0;
    setappdata(0, 'VirtualRat', S);
    fprintf('VirtualRat: session %d/%d (%d trials) ...\n', k, o.sessions, o.trials);
    t0 = tic;
    dispatcher('Run');                                % returns when stopped (use_timers 0)
    while dispatcher('is_running'), pause(0.25); end  % (use_timers 1)
    wall = toc(t0);
    sfile = end_session(S.protocol);
    S = getappdata(0, 'VirtualRat');
    S.sessions(end+1) = struct('n', numel(S.sessions) + 1, 'trials', S.stats.trials, ...
        'rewarded', S.stats.rewarded, 'choices', S.stats.choices, 'wall', wall, 'file', sfile);
    setappdata(0, 'VirtualRat', S);
    fprintf('VirtualRat: session %d done: %d trials, %.0f%% rewarded, %.0f s (%.2f s/trial)\n', ...
        k, S.stats.trials, 100 * S.stats.rewarded / max(1, S.stats.trials), wall, wall / max(1, S.stats.trials));
    update_window();
end
restore_polling(old_period);
return;


function sfile = end_session(protocol)
% As runrats('end_continued'), without the svn add/commit.
obj = dispatcher('get_protocol_object');
try
    feval(protocol, obj, 'end_session');
catch err
    fprintf(2, 'VirtualRat: end_session: %s\n', err.message);
end
sfile = SavingSection(obj, 'savedata', 'interactive', 0, 'commit', 0);
try
    feval(protocol, obj, 'pre_saving_settings');
catch err
    fprintf(2, 'VirtualRat: pre_saving_settings failed: %s\n', err.message);
end
SavingSection(obj, 'savesets', 'interactive', 0, 'commit', 0);
return;


function set_protocol_params(protocol, params)
if isempty(params), return; end
if isstruct(params), params = [fieldnames(params) struct2cell(params)]; end
for i = 1:size(params, 1)
    h = get_sphandle('owner', ['^@' protocol '$'], 'name', ['^' params{i, 1} '$']);
    if isempty(h)
        fprintf(2, 'VirtualRat: protocol has no parameter "%s"\n', params{i, 1});
    else
        h{1}.value = params{i, 2};
    end
end
return;


function old = faster_polling(speed)
% Poll the emulator more often when it runs fast (dispatcher's UpdatePeriod, ms).
old = [];
h = get_sphandle('owner', 'dispatcher', 'name', '^UpdatePeriod$');
if isempty(h), return; end
old = value(h{1});
if speed > 1, h{1}.value = 100; end
return;


function restore_polling(old)
if isempty(old), return; end
h = get_sphandle('owner', 'dispatcher', 'name', '^UpdatePeriod$');
if ~isempty(h), h{1}.value = old; end
return;


function stop_now()
S = getappdata(0, 'VirtualRat');
if isempty(S), return; end
S.abort = 1;
setappdata(0, 'VirtualRat', S);
try dispatcher('Stop'); catch, end %#ok<CTCH>
return;


function set_params(varargin)
global softsound_play_sounds
S = getappdata(0, 'VirtualRat');
if isempty(S), S = new_state(); end
for i = 1:2:numel(varargin) - 1
    nm = varargin{i}; v = varargin{i + 1};
    if strcmp(nm, 'speed')
        S.speed = v;
        setappdata(0, 'VirtualRat', S);
        try SetSpeed(dispatcher('get_state_machine'), v); catch, end %#ok<CTCH>
        if v > 1, softsound_play_sounds = 0; elseif isfield(S.saved, 'softsound_play_sounds'), softsound_play_sounds = S.saved.softsound_play_sounds; end
    elseif isfield(S.params, nm)
        p = S.params; p.(nm) = v;
        if strcmp(nm, 'bias_port') && ischar(v), p.bias_port = find(strcmpi(S.port_names, v)); end
        q = p; q.bias_port = S.port_names{p.bias_port};
        q.experimenter = ''; q.ratname = ''; q.speed = 1; q.seed = [];
        S.params = rat_params(q, S.port_names);
    else
        error('VirtualRat: unknown parameter "%s"', nm);
    end
end
setappdata(0, 'VirtualRat', S);
update_window();
return;


function st = status()
S = getappdata(0, 'VirtualRat');
st = S;
if isempty(S), fprintf('VirtualRat: not launched.\n'); return; end
fprintf('VirtualRat: %s  rat %s/%s  strategy %s  speed %gx\n', S.protocol, S.experimenter, S.ratname, S.params.strategy, S.speed);
fprintf('  this session: %d trials, %d rewarded', S.stats.trials, S.stats.rewarded);
for k = 1:numel(S.port_names), fprintf(', %s %d', S.port_names{k}, S.stats.choices(k)); end
fprintf('\n  all sessions: %d trials over %d saved sessions\n', S.n_total, numel(S.sessions));
return;


function restore()
global fake_rp_box softsound_play_sounds
S = getappdata(0, 'VirtualRat');
try
    sm = dispatcher('get_state_machine');
    if isa(sm, 'SoftSMMarkII'), SetRatCallback(sm, []); SetSpeed(sm, 1); end
catch %#ok<CTCH>
end
try dispatcher('close'); catch, end %#ok<CTCH>
% reload the rig's own settings (defaults + Settings_Custom.conf)
code = bSettings('get', 'GENERAL', 'Main_Code_Directory');
if ~ischar(code) || isempty(code), code = pwd; end
bSettings('load', fullfile(code, 'Settings', 'Settings_Default.conf'), fullfile(code, 'Settings', 'Settings_Custom.conf'));
if ~isempty(S) && isfield(S.saved, 'fake_rp_box')
    fake_rp_box = S.saved.fake_rp_box;
    softsound_play_sounds = S.saved.softsound_play_sounds;
else
    fake_rp_box = bSettings('get', 'RIGS', 'fake_rp_box');
end
if ~isempty(S) && isfield(S, 'fig') && ishandle(S.fig), delete(S.fig); end
rmappdata_safe();
fprintf('VirtualRat: emulator off, rig settings back (fake_rp_box = %g). Restart dispatcher/runrats.\n', fake_rp_box);
return;


function rmappdata_safe()
if isappdata(0, 'VirtualRat'), rmappdata(0, 'VirtualRat'); end
return;


% ======================================================================
%   CONTROL WINDOW
% ======================================================================
function control_window()
S = getappdata(0, 'VirtualRat');
if isempty(S), error('VirtualRat: launch a protocol first.'); end
if isfield(S, 'fig') && ~isempty(S.fig) && ishandle(S.fig), figure(S.fig); update_window(); return; end
f = figure('Name', 'VirtualRat', 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Position', [60 60 360 250], 'Resize', 'off');
strategies = {'perfect', 'noisy', 'learner', 'random', 'side', 'light', 'wsls'};
mk = @(style, str, pos, varargin) uicontrol(f, 'Style', style, 'String', str, 'Units', 'pixels', 'Position', pos, varargin{:});
mk('text', 'Strategy', [10 215 80 20], 'HorizontalAlignment', 'left');
H.strategy = mk('popupmenu', strategies, [100 218 120 20], 'Value', find(strcmp(strategies, S.params.strategy)), ...
    'Callback', @(h, e) VirtualRat('gui', 'strategy'));
mk('text', 'Speed', [10 185 80 20], 'HorizontalAlignment', 'left');
H.speed = mk('edit', num2str(S.speed), [100 188 60 20], 'Callback', @(h, e) VirtualRat('gui', 'speed'));
mk('text', 'Sessions', [10 155 80 20], 'HorizontalAlignment', 'left');
H.sessions = mk('edit', '1', [100 158 60 20]);
mk('text', 'Trials/session', [10 125 90 20], 'HorizontalAlignment', 'left');
H.trials = mk('edit', '300', [100 128 60 20]);
H.run = mk('pushbutton', 'Run sessions', [240 160 110 40], 'Callback', @(h, e) VirtualRat('gui', 'run'), ...
    'BackgroundColor', [0.6 1 0.6]);
H.stop = mk('pushbutton', 'Stop', [240 115 110 35], 'Callback', @(h, e) VirtualRat('stop'), ...
    'BackgroundColor', [1 0.7 0.7]);
H.info = mk('text', '', [10 10 340 100], 'HorizontalAlignment', 'left');
S.fig = f; S.H = H;
setappdata(0, 'VirtualRat', S);
update_window();
return;


function gui_callback(what)
S = getappdata(0, 'VirtualRat');
switch what
    case 'strategy'
        list = get(S.H.strategy, 'String');
        set_params('strategy', list{get(S.H.strategy, 'Value')});
    case 'speed'
        v = str2double(get(S.H.speed, 'String'));
        if isfinite(v) && v > 0, set_params('speed', v); else set(S.H.speed, 'String', num2str(S.speed)); end
    case 'run'
        n = str2double(get(S.H.sessions, 'String')); t = str2double(get(S.H.trials, 'String'));
        if ~(n >= 1 && t >= 1), return; end
        set(S.H.run, 'Enable', 'off');
        try
            run_sessions('sessions', round(n), 'trials', round(t));
        catch err
            fprintf(2, 'VirtualRat: %s\n', err.message);
        end
        S = getappdata(0, 'VirtualRat');
        if ishandle(S.H.run), set(S.H.run, 'Enable', 'on'); end
end
return;


function update_window()
S = getappdata(0, 'VirtualRat');
if isempty(S) || ~isfield(S, 'fig') || isempty(S.fig) || ~ishandle(S.fig), return; end
lines = {sprintf('%s   rat %s/%s', S.protocol, S.experimenter, S.ratname), ...
    sprintf('This session: %d trials, %d rewarded', S.stats.trials, S.stats.rewarded), ...
    sprintf('Saved sessions: %d   (%d trials in all)', numel(S.sessions), S.n_total)};
if ~isempty(S.sessions)
    l = S.sessions(end);
    lines{end+1} = sprintf('Last: %d trials, %.0f%% rewarded, %.2f s/trial', l.trials, 100 * l.rewarded / max(1, l.trials), l.wall / max(1, l.trials));
end
set(S.H.info, 'String', lines);
drawnow;
return;


% ======================================================================
function p = parse_pairs(p, args)
if mod(numel(args), 2), error('VirtualRat: options must be name/value pairs'); end
for i = 1:2:numel(args)
    if ~isfield(p, args{i}), error('VirtualRat: unknown option "%s"', args{i}); end
    p.(args{i}) = args{i + 1};
end
return;
