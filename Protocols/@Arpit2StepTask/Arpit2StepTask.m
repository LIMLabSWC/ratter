% Arpit2StepTask
%
% EXPERIMENT protocol (ephys / opto) for the 2-step auditory categorization
% task. Used once a rat has passed Arpit2StepTraining (stage 8, READY FOR
% TEST); the training protocol hands the rat over automatically (it writes
% the first Arpit2StepTask settings file with the rat's values).
%
% This is not a training protocol. The main experiments are switch sessions
% (Hard A <-> Hard B); performance is followed with the psychometric section,
% and 'Switch Distribution' (top of column 5) switches by hand.
% The experiment "groups" (ExperimentGroupSection, labelled Stage 1/2a/2b/3/4)
% are cohorts: the user decides, before the experiment, how much exposure to
% asymmetric distributions a rat gets (cohort 1: none). They are a session
% schedule, not training stages.
% The centre-poke controls (warm-up, hold growth, random hold) are only for
% re-training the hold, e.g. after surgery.
% StimulatorSection: StimLine 'none' = no experiment, 'Opto' (settings shown),
% 'Ephys' (no settings). The performance monitor runs only with 'none'.
%
% Task: the rat holds its nose in the centre port (hold drawn every trial in
% [cp_rand_min, cp_rand_max]) while a 0.4 s noise / tone stimulus plays. At
% the go cue one side port is lit and the other dark; the sound category
% says whether to go to the lit or the dark port (CueRule). Reward side =
% lit side XOR category. Wrong first poke: no water, error time-out.
%
% Differences from the training protocol
%   * no training stages, no shaping, no blocks, no CP growth
%   * ExperimentGroupSection: session schedule of the distribution
%     (group 1 uniform only / group 2 single asymmetric / group 3 switch)
%   * controls: Stimuli_State 'Fixed Stimuli' and 'No Sound' (matched trial
%     statistics, 50% reward), for comparing neural activity
%   * antibias is set by the user (default OFF), e.g. to fix a bias before experiments
%   * StimulatorSection (opto / ephys) and the ephys trial-number TTL
%
% Main files
%   Arpit2StepTaskSMA.m        state machine
%   SideSection.m              trial generation (4 cells), scoring, timing params
%   AntibiasSection.m          4-cell antibias (user controlled)
%   StimulusSection.m          stimulus by category; Full / Discrete / Fixed / No Sound
%   ExperimentGroupSection.m   distribution schedule per experimental group
%   StimulatorSection.m        opto / ephys
%   PerformanceSection.m, PsychometricSection.m, PerformanceMonitorSection.m
%
% The section and parameter names are the same as in Arpit2StepTraining so
% that a rat's values carry over at the handover.

function [obj, varargout] = Arpit2StepTask(varargin)

obj = class(struct, mfilename, pokesplot2, saveload, sessionmodel2, soundmanager, soundui, antibias, ...
   water, distribui, soundtable, comments, sqlsummary, bonsaicamera);

%---------------------------------------------------------------
%   BEGIN SECTION COMMON TO ALL PROTOCOLS, DO NOT MODIFY
%---------------------------------------------------------------

if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty'))
   return;
end

if isa(varargin{1}, mfilename)
   if length(varargin) < 2 || ~ischar(varargin{2})
      error(['If called with a "%s" object as first arg, a second arg, a ' ...
         'string specifying the action, is required\n']);
   else
       action = varargin{2}; varargin = varargin(3:end); %#ok<NASGU>
   end
else
   action = varargin{1}; varargin = varargin(2:end); %#ok<NASGU>
end

GetSoloFunctionArgs(obj);

switch action

   %% init
   case 'init'

    % The trial-number TTL is sent by our own SMA (exact timing per bit)
    dispatcher('unset_trialnum_indicator_flag');

    hackvar = 10; SoloFunctionAddVars('SessionModel', 'ro_args', 'hackvar'); %#ok<NASGU>
    SoloParamHandle(obj, 'myfig', 'saveable', 0); myfig.value = figure;

    name = mfilename;
    set(value(myfig), 'Name', name, 'Tag', name, ...
      'closerequestfcn', 'dispatcher(''close_protocol'')', 'MenuBar', 'none');
    set(value(myfig), 'Position', [380   144   1060   680]);   % five columns

    SoloParamHandle(obj, 'hit_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'hit_history'});
    SoloFunctionAddVars('SideSection', 'rw_args', 'hit_history');

    SoloParamHandle(obj, 'stimulus_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'stimulus_history'});
    SoloFunctionAddVars('StimulusSection', 'rw_args', 'stimulus_history');

    SoloParamHandle(obj, 'stimulus_distribution_history', 'value', cell(0));
    DeclareGlobals(obj, 'ro_args', {'stimulus_distribution_history'});
    SoloFunctionAddVars('StimulusSection', 'rw_args', 'stimulus_distribution_history');

    SoloParamHandle(obj, 'stimulus_left_distribution_history', 'value', cell(0));
    DeclareGlobals(obj, 'ro_args', {'stimulus_left_distribution_history'});
    SoloFunctionAddVars('StimulusSection', 'rw_args', 'stimulus_left_distribution_history');

    SoloParamHandle(obj, 'stimulus_right_distribution_history', 'value', cell(0));
    DeclareGlobals(obj, 'ro_args', {'stimulus_right_distribution_history'});
    SoloFunctionAddVars('StimulusSection', 'rw_args', 'stimulus_right_distribution_history');

    SoloParamHandle(obj, 'violation_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'violation_history'});
    SoloFunctionAddVars('SideSection', 'rw_args', 'violation_history');

    SoloParamHandle(obj, 'timeout_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'timeout_history'});
    SoloFunctionAddVars('SideSection', 'rw_args', 'timeout_history');

    SoundManagerSection(obj, 'init');

    x = 5; y = 5;
    [x, y] = SavingSection(obj, 'init', x, y);

    %% Water ramp: WaterAmount(t) = maxasymp + (minasymp/(1+(t/inflp)^slp).^assym)
    NumeditParam(obj, 'maxasymp', 30, x,y,'label','maxasymp','TooltipString',...
        'the water volume is controlled by a 5-parameter logistic function: WaterAmount(trialnum) = maxasymp + (minasymp/(1+(trialnum/inflp)^slp).^assym)');
    next_row(y);
    NumeditParam(obj, 'slp', 3, x,y,'label','slp','TooltipString','Water Modulation: Slope of the logistic function');
    next_row(y);
    NumeditParam(obj, 'inflp', 350, x,y,'label','inflp','TooltipString','Water Modulation: concentration at the inflection point');
    next_row(y);
    NumeditParam(obj, 'minasymp', -13, x,y,'label','minasymp','TooltipString','Water Modulation: minimum asymptote');
    next_row(y);
    NumeditParam(obj, 'assym', 0.7, x,y,'label','assym','TooltipString','Water Modulation: asymmetry factor');
    next_row(y);
    DispParam(obj, 'trial_1', 0, x, y, 'TooltipString', 'uL on first trial');
    next_row(y);
    DispParam(obj, 'trial_150', 0, x, y, 'TooltipString', 'uL on trial 150');
    next_row(y);
    DispParam(obj, 'trial_300', 0, x, y, 'TooltipString', 'uL on trial 300');
    next_row(y);
    set_callback({maxasymp;slp;inflp;minasymp;assym}, {mfilename, 'change_water_modulation_params'});
    feval(mfilename, obj, 'change_water_modulation_params');

    SoloFunctionAddVars('SideSection', 'ro_args', {'maxasymp';'slp';'inflp';'minasymp';'assym'});

    figpos = get(double(gcf), 'Position');
    [expmtr, rname] = SavingSection(obj, 'get_info');
    HeaderParam(obj, 'prot_title', [mfilename ': ' expmtr ', ' rname], x, y, 'position', [10 figpos(4)-25, 800 20]);

    [x, y] = WaterValvesSection(obj, 'init', x, y); next_row(y);
    [x, y] = CommentsSection(obj, 'init', x, y); next_row(y);
    [x, y] = BonsaiCameraInterface(obj, 'init', x, y, name, expmtr, rname); next_row(y);

    oldx = x; oldy = y;

    % Main window, five columns:
    %   1 saving, water, comments, camera (above)
    %   2 sides + antibias, stimulus / sound buttons
    %   3 trial timing and sound mode
    %   4 performance, monitor, centre-poke and trial-structure controls, lock
    %   5 (top to bottom) psychometric with Switch Distribution, session
    %     schedule (cohort), stimulator (opto settings only for Opto)
    next_column(x); y = 5;
    [x, y] = SideSection(obj, 'init', x, y);             % columns 2 and 3
    figure(value(myfig));
    next_column(x); next_column(x); y = 5;               % column 4
    [x, y] = PerformanceSection(obj, 'init', x, y);
    [x, y] = PerformanceMonitorSection(obj, 'init', x, y); next_row(y, 0.5);
    [x, y] = SideSection(obj, 'init_controls', x, y);
    [x, y] = SideSection(obj, 'init_lock', x, y); %#ok<ASGLU>
    next_column(x); y = 5;                               % column 5
    [x, y] = StimulatorSection(obj, 'init', x, y);       % none / opto / ephys (bottom)
    next_row(y, 0.5);
    [x, y] = ExperimentGroupSection(obj, 'init', x, y);
    figure(value(myfig));
    next_row(y, 0.5);
    [x, y] = PsychometricSection(obj, 'init', x, y); %#ok<ASGLU>
    figure(value(myfig));                                % (the psychometric windows took the focus)
    SideSection(obj, 'User_Control');
    x = oldx; y = oldy;
    SessionDefinition(obj, 'init', x, y, value(myfig)); next_row(y, 2); %#ok<NASGU>

    % autosave every 20 trials (ephys sessions set 1 via set_setting_params)
    SavingSection(obj, 'set_autosave_frequency', 20);

    Arpit2StepTaskSMA(obj, 'init');

    feval(mfilename, obj, 'prepare_next_trial');

   case 'change_water_modulation_params'
       display_guys = [1 150 300];
       for i = 1:numel(display_guys)
           t = display_guys(i);
           myvar = eval(sprintf('trial_%d', t));
           myvar.value = maxasymp + (minasymp/(1+(t/inflp)^slp).^assym);
       end

   %% called by runrats when the user presses Run
   case 'start_recording'
        BonsaiCameraInterface(obj, 'record_start');

   case 'set_setting_params' % used during ephys experiments when not using runrats
        SavingSection(obj, 'set', 'ratname', varargin{1});
        SavingSection(obj, 'set', 'experimenter', varargin{2});
        SavingSection(obj, 'set_setting_info', varargin{3}, varargin{4});
        SavingSection(obj, 'set_autosave_frequency', 1);
        BonsaiCameraInterface(obj, 'set_video_filepath', varargin{5});
        BonsaiCameraInterface(obj, 'camera_connection');

   case 'set_stim_distribution'
        if strcmpi(varargin{1}, 'random')
            if rand(1) > 0.5
                StimulusSection(obj, 'Pushbutton_SwitchDistribution', 'Hard B');
            else
                StimulusSection(obj, 'Pushbutton_SwitchDistribution', 'Hard A');
            end
        else
            StimulusSection(obj, 'Pushbutton_SwitchDistribution', varargin{1});
        end

   case 'psychometricUpdate_aftercrash'
        PsychometricSection(obj, 'reload_after_crash');

   %% prepare next trial
   case 'prepare_next_trial'
       % SideSection scores the last trial, runs ExperimentGroupSection and
       % draws the next trial (reward side, category, lit side).
       SideSection(obj, 'prepare_next_trial');
       PerformanceMonitorSection(obj, 'trial');   % remarks only; off with Opto / Ephys (StimulatorSection)
       StimulatorSection(obj, 'update_values');
       StimulusSection(obj, 'prepare_next_trial');
       SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');

       [sma, prepare_next_trial_states] = Arpit2StepTaskSMA(obj, 'prepare_next_trial'); %#ok<ASGLU>

       % Per-trial history of values that are not GUI parameters. Dispatcher
       % pushes the history of every GUI parameter (editable or display) once
       % per trial; plain SoloParamHandles only keep their final value, so
       % the trial-level ones are pushed here (one entry per trial).
       SideSection(obj, 'push_trial_history');
       StimulusSection(obj, 'push_trial_history');

       SavingSection(obj, 'autosave_data');

       CommentsSection(obj, 'clear_history');
       if n_done_trials == 1
            CommentsSection(obj, 'append_date'); CommentsSection(obj, 'append_line', '');
       end

   %% trial_completed
   case 'trial_completed'
       BonsaiCameraInterface(obj, 'next_trial');
       PerformanceSection(obj, 'evaluate');
       PsychometricSection(obj, 'update');
       feval(mfilename, 'update');

   %% update
   case 'update'
      if n_done_trials == 1
            [expmtr, rname] = SavingSection(obj, 'get_info');
            prot_title.value = [mfilename ' on rig ' get_hostname ' : ' expmtr ', ' rname '.  Started at ' datestr(now, 'HH:MM')];
      end

   %% close
   case 'close'
    SideSection(obj, 'close');
    StimulusSection(obj, 'close');
    ExperimentGroupSection(obj, 'close');
    PerformanceMonitorSection(obj, 'close');
    BonsaiCameraInterface(obj, 'close');
    if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
      delete(value(myfig));
    end
    delete_sphandle('owner', ['^@' class(obj) '$']);

   %% end_session
   case 'end_session'
      prot_title.value = [value(prot_title) ', Ended at ' datestr(now, 'HH:MM')];
      BonsaiCameraInterface(obj, 'stop');

   %% pre_saving_settings (runrats calls this before saving tomorrow's settings)
   case 'pre_saving_settings'

    SideSection(obj, 'end_of_session');                 % hold reached today (warm-up target)
    PerformanceMonitorSection(obj, 'end_of_session');   % remarks into comments + one summary e-mail if flagged

    StimulusSection(obj, 'hide');
    PsychometricSection(obj, 'hide');
    ExperimentGroupSection(obj, 'hide');
    SessionDefinition(obj, 'run_eod_logic_without_saving');

    try
        perf = PsychometricSection(obj, 'evaluate');
    catch
        perf{1,1}.start_trial = 1;
        perf{1,1}.end_trial = n_done_trials;
        perf{1,1}.valid_trials = -1;
        perf{1,1}.distribution_type = '';
        perf{1,1}.calculated_boundary = nan;
        perf{1,1}.total_hit_percent = -1;
        perf{1,1}.total_violations_percent = -1;
        perf{1,1}.right_correct_percent = -1;
        perf{1,1}.left_correct_percent = -1;
    end

    try
        SoundCatContextSwitchSummary(obj, 'protocol_data', perf);
    catch ME
        fprintf(2, 'Arpit2StepTask: SQL summary failed: %s\n', ME.message);
    end

   %% used by PerformanceMonitorSection (same call in both 2-step protocols)
   case 'monitor_summary'
      out.stage_no = 9;   % after training stage 8: all session checks apply
      out.stage_name = ['Experiment, schedule ' ExperimentGroupSection(obj, 'get_group')];
      out.s6_step = NaN; out.stage_sessions = 0; out.s6_step_sessions = 0;
      out.expert = true;  % all strategy / performance checks are active
      varargout{1} = out;

   otherwise
      warning('Unknown action! "%s"\n', action);
end

return;
