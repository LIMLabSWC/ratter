% ArpitCentrePokeTraining protocol
% Arpit, 12 March 2025

function [obj] = ArpitCentrePokeTraining(varargin)

% Default object is of our own class (mfilename);
% we inherit only from Plugins

obj = class(struct, mfilename, pokesplot2, saveload, sessionmodel2, soundmanager, soundui, ...
  water, distribui,comments, soundtable, sqlsummary, bonsaicamera);

%---------------------------------------------------------------
%   BEGIN SECTION COMMON TO ALL PROTOCOLS, DO NOT MODIFY
%---------------------------------------------------------------

% If creating an empty object, return without further ado:
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty'))
   return;
end

if isa(varargin{1}, mfilename) % If first arg is an object of this class itself, we are
   % Most likely responding to a callback from a SoloParamHandle defined in this mfile.
   if length(varargin) < 2 || ~ischar(varargin{2})
      error(['If called with a "%s" object as first arg, a second arg, a ' ...
         'string specifying the action, is required\n']);
   else 
       action = varargin{2}; varargin = varargin(3:end); %#ok<NASGU>
   end
else % Ok, regular call with first param being the action string.
   action = varargin{1}; varargin = varargin(2:end); %#ok<NASGU>
end

GetSoloFunctionArgs(obj);


%---------------------------------------------------------------
%   END OF SECTION COMMON TO ALL PROTOCOLS, MODIFY AFTER THIS LINE
%---------------------------------------------------------------

% ---- From here on is where you can put the code you like.
%
% Your protocol will be called, at the appropriate times, with the
% following possible actions:
%
%   'init'     To initialize -- make figure windows, variables, etc.
%
%   'update'   Called periodically within a trial
%
%   'prepare_next_trial'  Called when a trial has ended and your protocol is expected
%              to produce the StateMachine diagram for the next trial;
%              i.e., somewhere in your protocol's response to this call, it
%              should call "dispatcher('send_assembler', sma,
%              prepare_next_trial_set);" where sma is the
%              StateMachineAssembler object that you have prepared and
%              prepare_next_trial_set is either a single string or a cell
%              with elements that are all strings. These strings should
%              correspond to names of states in sma.
%                 Note that after the prepare_next_trial call, further
%              events may still occur while your protocol is thinking,
%              before the new StateMachine diagram gets sent. These events
%              will be available to you when 'state0' is called on your
%              protocol (see below).
%
%   'trial_completed'   Called when the any of the prepare_next_trial set
%              of states is reached.
%
%   'close'    Called when the protocol is to be closed.
%
%
% VARIABLES THAT DISPATCHER WILL ALWAYS INSTANTIATE FOR YOU AS READ_ONLY
% GLOBALS IN YOUR PROTOCOL:
%
% n_done_trials     How many trials have been finished; when a trial reaches
%                   one of the prepare_next_trial states for the first
%                   time, this variable is incremented by 1.
%
% n_started_trials  How many trials have been started. This variable gets
%                   incremented by 1 every time the state machine goes
%                   through state 0.
%
% parsed_events     The result of running disassemble.m, with the
%                   parsed_structure flag set to 1, on all events from the
%                   start of the current trial to now.
%
% latest_parsed_events     The result of running disassemble.m, with the
%                   parsed_structure flag set to 1, on all new events from
%                   the last time 'update' was called to now.
%
% raw_events        All the events obtained in the current trial, not parsed
%                   or disassembled, but raw as gotten from the State
%                   Machine object.
%
% current_assembler The StateMachineAssembler object that was used to
%                   generate the State Machine diagram in effect in the
%                   current trial.
%
% Trial-by-trial history of parsed_events, raw_events, and
% current_assembler, are automatically stored for you in your protocol by
% dispatcher.m.

switch action
   
   %% init
   case 'init'
 
    hackvar = 10; SoloFunctionAddVars('SessionModel', 'ro_args', 'hackvar'); %#ok<NASGU>
    SoloParamHandle(obj, 'myfig', 'saveable', 0); myfig.value = figure;

    % Make the title of the figure be the protocol name, and if someone tries
    % to close this figure, call dispatcher's close_protocol function, so it'll know
    % to take it off the list of open protocols.
    name = mfilename;
    set(value(myfig), 'Name', name, 'Tag', name, ...
      'closerequestfcn', 'dispatcher(''close_protocol'')', 'MenuBar', 'none');
    % At this point we have one SoloParamHandle, myfig
    % Let's put the figure where we want it and give it a reasonable size:
    set(value(myfig), 'Position', [485   144   850   680]);

    SoloParamHandle(obj, 'violation_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'violation_history'});
    SoloFunctionAddVars('ParamsSection', 'rw_args', 'violation_history');
    
    SoloParamHandle(obj, 'timeout_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'timeout_history'});
    SoloFunctionAddVars('ParamsSection', 'rw_args', 'timeout_history');
   
    SoloParamHandle(obj, 'stimulus_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'stimulus_history'});
    SoloFunctionAddVars('StimulusSection', 'rw_args', 'stimulus_history');
    
    SoloParamHandle(obj, 'hit_history', 'value', []);
    DeclareGlobals(obj, 'ro_args', {'hit_history'});
    SoloFunctionAddVars('ParamsSection', 'rw_args', 'hit_history');

    SoundManagerSection(obj, 'init');
    x = 5; y = 5;             % Initial position on main GUI window
    [x, y] = SavingSection(obj,       'init', x, y); 
    
    %% slow ramp up of water amount		
    %%the water volume is controlled by a 5-parameter logistic function: WaterAmount(t) = maxasymp + (minasymp/(1+(t/inflp)^slp).^assym)
    NumeditParam(obj, 'maxasymp', 38, x,y,'label','maxasymp','TooltipString',...
        'the water volume is controlled by a 5-parameter logistic function: WaterAmount(trialnum) = maxasymp + (minasymp/(1+(trialnum/inflp)^slp).^assym)');
	next_row(y);
	NumeditParam(obj, 'slp', 3, x,y,'label','slp','TooltipString','Water Modulation: Slope of the logistic function');	
	next_row(y);
	NumeditParam(obj, 'inflp', 350, x,y,'label','inflp','TooltipString','Water Modulation: concentration at the inflection point');	
	next_row(y);
    NumeditParam(obj, 'minasymp', -21, x,y,'label','inflp','TooltipString','Water Modulation: minimum asymptote');	
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
	
    SoloFunctionAddVars('ParamsSection', 'ro_args', ...
			{'maxasymp';'slp';'inflp';'minasymp';'assym'});
     
    figpos = get(double(gcf), 'Position');
    [expmtr, rname]=SavingSection(obj, 'get_info');
    HeaderParam(obj, 'prot_title', [mfilename ': ' expmtr ', ' rname], x, y, 'position', [10 figpos(4)-25, 800 20]);
    
    [x, y] = WaterValvesSection(obj,  'init', x, y); next_row(y);
    [x, y] = PokesPlotSection(obj, 'init', x, y); 
    next_row(y);
    [x, y] = CommentsSection(obj, 'init', x, y); 
    next_row(y);
    oldx=x; oldy=y;
   
    next_column(x); y=5; 

	[x, y] = ParamsSection(obj,  'init', x, y); %#ok<NASGU>   
    [x, y] = SoundSection(obj,'init',x,y);   
    [x, y] = StimulusSection(obj,'init',x,y);
    
    next_row(y);next_row(y);    
	 
    [x, y] = PerformanceSummarySection(obj, 'init', x, y);next_row(y);
    [x, y] = SessionPerformanceSection(obj, 'init', x, y);
    
    next_row(y);next_row(y);
    
    [x, y] = BonsaiCameraInterface(obj,'init',x,y,name,expmtr,rname);

    % Before the TrainingStageParamsSection, let's first check if
    % the setting file exist for this rat and only load the training stage
    % from there.
    % Problem: Loading settings in later stages fails because the stage-dependent
    % TrainingStageParamsSection's solohandles are not visible after initial setup.
    % Solution: This section handles a specific scenario for loading setting files during initialization.
    % Although also invoked in Runrats, calling it here is crucial. The
    % TrainingStageParamsSection's parameters are initially set at stage 1 and are visible.
    % However, they become stage-dependent. Subsequent stages lack visible solohandles for
    % these parameters, preventing proper loading. This initialization provides a workaround
    % to avoid significant changes required to load stage-specific solohandles and maintain
    % broader compatibility.

    set_training_stage_last_setting_file(name,expmtr,rname)

    next_column(x); y=5;
    [stage_fig_x,stage_fig_y] = TrainingStageParamsSection(obj, 'init', x, y);
    SoloParamHandle(obj, 'stage_fig_x', 'value', stage_fig_x);
    SoloFunctionAddVars('ParamsSection', 'rw_args', 'stage_fig_x');
    SoloParamHandle(obj, 'stage_fig_y', 'value', stage_fig_y);
    SoloFunctionAddVars('ParamsSection', 'rw_args', 'stage_fig_y');
  
    ArpitCentrePokeTrainingSMA(obj, 'init');
    

    x=oldx; y=oldy;
    SessionDefinition(obj, 'init', x, y, value(myfig)); %#ok<NASGU>
    
    %%%
    
% Problem: Loading settings in later stages fails because the stage-dependent
% TrainingStageParamsSection's solohandles are not visible after initial setup.
% Solution: This section handles a specific scenario for loading setting files during initialization.
% Although also invoked in Runrats, calling it here is crucial. The
% TrainingStageParamsSection's parameters are initially set at stage 1 and are visible.
% However, they become stage-dependent. Subsequent stages lack visible solohandles for
% these parameters, preventing proper loading. This initialization provides a workaround
% to avoid significant changes required to load stage-specific solohandles and maintain
% broader compatibility.
    
%     try
%         [~, ~]=load_solouiparamvalues(rname,'experimenter',expmtr,...
%             'owner',name,'interactive',0);
%     catch
%     end
     %%
    % feval(mfilename, obj, 'prepare_next_trial'); % Commented out because it is also run by Runrats(while loading the protocol)
          
    %%% 

   
   %% change_water_modulation_params
   case 'change_water_modulation_params'
	   display_guys = [1 150 300];
       for i=1:numel(display_guys)
           t = display_guys(i);

           myvar = eval(sprintf('trial_%d', t));
           myvar.value = maxasymp + (minasymp/(1+(t/inflp)^slp).^assym);
       end
	
   %% when user presses run on runrats then then is called
    case 'start_recording'

        BonsaiCameraInterface(obj,'record_start');

   %% prepare next trial
   case 'prepare_next_trial'

       ParamsSection(obj, 'prepare_next_trial');

    % push_helper_vars_tosql(obj,n_done_trials); 
       
       SessionDefinition(obj, 'next_trial');
       
       StimulusSection(obj,'prepare_next_trial');
       SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
       [~, ~] = ArpitCentrePokeTrainingSMA(obj, 'prepare_next_trial');

    % Default behavior of following call is that every 20 trials, the data
    % gets saved, not interactive, no commit to CVS.
       SavingSection(obj, 'autosave_data');
    
       CommentsSection(obj, 'clear_history'); % Make sure we're not storing unnecessary history
       if n_done_trials==1  % Auto-append date for convenience.
            CommentsSection(obj, 'append_date'); CommentsSection(obj, 'append_line', '');
       end

   %% trial_completed
   case 'trial_completed'
    
       % Change the video trial  
        BonsaiCameraInterface(obj,'next_trial');
    
    % Update the Metrics Calculated, Instead being Calculated in SessionDefinition and commented out

    % PerformanceSummarySection(obj,'evaluate');
    % SessionPerformanceSection(obj, 'evaluate');
    
    % Do any updates in the protocol that need doing:
       feval(mfilename, 'update');

   %% update
   case 'update'
      % PokesPlotSection(obj, 'update');
      if n_done_trials==1
            [expmtr, rname]=SavingSection(obj, 'get_info');
            prot_title.value=[mfilename ' on rig ' get_hostname ' : ' expmtr ', ' rname  '.  Started at ' datestr(now, 'HH:MM')];
       end
      
   %% close
   case 'close'
    PokesPlotSection(obj, 'close');
	ParamsSection(obj, 'close');
    StimulusSection(obj,'close');
    BonsaiCameraInterface(obj,'close');
    if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
      delete(value(myfig));
    end
    delete_sphandle('owner', ['^@' class(obj) '$']);

      
      %% end_session
   case 'end_session'
      prot_title.value = [value(prot_title) ', Ended at ' datestr(now, 'HH:MM')];
      BonsaiCameraInterface(obj,'stop') % Stopping the cameras
      
      %% pre_saving_settings
   case 'pre_saving_settings'
    
    StimulusSection(obj,'hide');   
    SessionDefinition(obj, 'run_eod_logic_without_saving');

    % Sending protocol data as structure is causing error in saving bdata,
    % instead not sending it asif required can be taken from session data
    
    % sendsummary(obj);
    perf = struct([]);
    perf = PerformanceSummarySection(obj, 'evaluate');
    [perf.violation_percent,perf.timeout_percent] = SessionPerformanceSection(obj, 'evaluate');

    [perf.stage_no,perf.CP_Duration]  = ParamsSection(obj,'get_stage');
    stage_name_list = {'Familiarize with Reward Side Pokes','Timeout Rewarded Side Pokes'...
        'Introduce Centre Poke','Introduce Violation for Centre Poke',...
        'Introduce Stimuli Sound during Centre Poke','Vary Stimuli location during Centre Poke'...
        'Variable Stimuli Go Cue location during Centre Poke','User Setting'};
    perf.stage_name = stage_name_list{perf.stage_no};
    
    perf.video_filepath = BonsaiCameraInterface(obj,'video_filepath');
    
    CentrePoketrainingsummary(obj,'protocol_data',perf);
    
% 	CommentsSection(obj, 'append_line', ...
% 		sprintf(['ntrials = %d, violations = %.2f, timeouts=%.2f, hits = %.2f\n', ...
% 		'pre-Go cue went from %.3f to %.3f  (delta=%.3f)\n', ...
%         'Low = %.2f, High = %.2f'], ...
% 		perf(1), perf(2), perf(3), perf(6), cp_durs(1), cp_durs(end), cp_durs(end)-cp_durs(1), classperf(1),classperf(2)));
      
      %% otherwise
    otherwise
      warning('Unknown action! "%s"\n', action);
end

return;

