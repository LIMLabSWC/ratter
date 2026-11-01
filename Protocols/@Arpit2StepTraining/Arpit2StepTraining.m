% Arpit2StepTraining
%
% Training protocol for the 2-step auditory categorization task.
%
% Task (stage 5 onwards): the rat holds its nose in the centre port while a
% noise (or tone) stimulus plays. At the go cue one side port is lit and the
% other is dark. The sound category tells the rat whether to go to the lit
% or the dark port (CueRule, e.g. Loud->Lit). The rewarded side is
% therefore reward side = lit side XOR category, and no single cue
% (side, light, sound alone) predicts the reward.
%
% Shaping (stages 1-4) teaches side pokes and the centre hold with
% UNINFORMATIVE side lights (both on or both off, either side pays), so the
% rat never learns "lit port = water".
%
% Main files
%   Arpit2StepTrainingSMA.m   state machine
%   SideSection.m             trial generation (4 cells), scoring, timing params
%   AntibiasSection.m         4-cell antibias (reward side x category)
%   StimulusSection.m         stimulus by category; Full / Discrete / Fixed / No Sound
%   TrainingStageSection.m    automatic stages and promotion criteria
%   PerformanceSection.m      performance incl. 4-cell table
%   PsychometricSection.m     P(responded loud) vs stimulus (Full, or >= 8 discrete levels)
%   PerformanceMonitorSection.m  remarks during the session; summary to comments and one
%                                e-mail after the session if something is flagged
%
% Based on ArpitSoundCategorization (1-step).

function [obj, varargout] = Arpit2StepTraining(varargin)

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
    set(value(myfig), 'Position', [485   144   850   680]);

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
    next_column(x); y = 5;

    [x, y] = SideSection(obj, 'init', x, y); %#ok<NASGU>
    next_row(y, 1.3);
    [x, y] = PerformanceSection(obj, 'init', x, y);
    next_row(y, 1.3);
    [x, y] = PerformanceMonitorSection(obj, 'init', x, y);
    [x, y] = PsychometricSection(obj, 'init', x, y);
    x = oldx; y = oldy;
    SessionDefinition(obj, 'init', x, y, value(myfig)); next_row(y, 2); %#ok<NASGU>

    % autosave every 20 trials (ephys sessions set 1 via set_setting_params)
    SavingSection(obj, 'set_autosave_frequency', 20);

    Arpit2StepTrainingSMA(obj, 'init');

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

   case 'psychometricUpdate_aftercrash'
        PsychometricSection(obj, 'reload_after_crash');

   %% prepare next trial
   case 'prepare_next_trial'
       % SideSection scores the last trial, runs TrainingStageSection and
       % draws the next trial (reward side, category, lit side).
       SideSection(obj, 'prepare_next_trial');
       PerformanceMonitorSection(obj, 'trial');   % remarks only; nothing is sent during the session
       StimulusSection(obj, 'prepare_next_trial');
       SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');

       [sma, prepare_next_trial_states] = Arpit2StepTrainingSMA(obj, 'prepare_next_trial'); %#ok<ASGLU>

       % Per-trial history of values that are not GUI parameters. Dispatcher
       % pushes the history of every GUI parameter (editable or display) once
       % per trial; plain SoloParamHandles only keep their final value, so
       % the trial-level ones are pushed here (one entry per trial).
       SideSection(obj, 'push_trial_history');
       StimulusSection(obj, 'push_trial_history');
       TrainingStageSection(obj, 'push_trial_history');

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
    TrainingStageSection(obj, 'close');
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

    % Stage bookkeeping and CP carry-over happen BEFORE the settings are saved
    TrainingStageSection(obj, 'end_of_session');
    PerformanceMonitorSection(obj, 'end_of_session');   % remarks into comments + one summary e-mail if flagged

    StimulusSection(obj, 'hide');
    PsychometricSection(obj, 'hide');
    TrainingStageSection(obj, 'hide');
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
        fprintf(2, 'Arpit2StepTraining: SQL summary failed: %s\n', ME.message);
    end

   %% used by PerformanceMonitorSection (same call in both 2-step protocols)
   case 'monitor_summary'
      out = TrainingStageSection(obj, 'get_summary');
      out.expert = (out.stage_no == 7) || (out.stage_no == 6 && out.s6_step >= 4);
      varargout{1} = out;

   otherwise
      warning('Unknown action! "%s"\n', action);
end

return;
