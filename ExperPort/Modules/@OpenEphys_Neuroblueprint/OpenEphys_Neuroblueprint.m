function [obj, varargout] = OpenEphys_Neuroblueprint(varargin)
% This is a class-based version of the GUI controller, structured similarly
% to runrats.m. It manages the experimental workflow through different
% 'actions' called via a switch statement.
%
% PRE-REQUISITES:
% 1. 'open-ephys-matlab-tools' must be in the MATLAB path.
% 2. The Bpod/ratter/ExperPort environment, including all its dependencies 
%    (dispatcher, bSettings, etc.), must be fully configured and in the MATLAB path.

% --- Boilerplate for class definition and action handling ---
obj = class(struct, mfilename);
varargout = {}; % Initialize varargout for actions that return values
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty')), 
   return; 
end;
if isa(varargin{1}, mfilename),
  if length(varargin) < 2 || ~ischar(varargin{2}), 
    error(['If called with a "%s" object as first arg, a second arg, a ' ...
      'string specifying the action, is required\n']);
  else action = varargin{2}; varargin = varargin(3:end);
  end;
else
       action = varargin{1}; varargin = varargin(2:end);
end;
if ~ischar(action), error('The action parameter must be a string'); end;
GetSoloFunctionArgs(obj);
% --- End of boilerplate ---


switch action
    % =========================================================================
    %       CASE INIT
    % =========================================================================
    case 'init'
        % This case is called once to create the GUI and initialize all parameters.
        
        % Start Bpod if not already running
        if evalin('base', 'exist(''BpodSystem'', ''var'')')
            if evalin('base', '~isempty(BpodSystem)'), newstartup; else, flush; end
        else, Bpod('COM5');newstartup;
        end
        
        % --- State Variables as SoloParamHandles ---
        SoloParamHandle(obj, 'currentState', 'value', 'Load');
        SoloParamHandle(obj, 'oe_controller', 'value', []);
        SoloParamHandle(obj, 'behav_obj', 'value', []);
        SoloParamHandle(obj, 'blinking_timer', 'value', []);
        SoloParamHandle(obj, 'monitor_timer', 'value', []);
        SoloParamHandle(obj, 'current_params', 'value', []);
        SoloParamHandle(obj, 'session_base_path', 'value', '');
        SoloParamHandle(obj,'is_running','value',0);
        scr = timer;
        set(scr,'Period', 0.2,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
            'BusyMode','drop','TimerFcn',[mfilename,'(''End_Continued'')']);
        SoloParamHandle(obj, 'stopping_complete_timer', 'value', scr);

        % --- Create the GUI Figure ---
        SoloParamHandle(obj, 'myfig', 'saveable', 0);
        myfig.value = figure('Name', 'Open Ephys & BControl Controller',...
                     'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none',...
                     'Units', 'normalized', 'Position', [0.1, 0.1, 0.6, 0.8],...
                     'Color', [0.94, 0.94, 0.94], ...
                     'CloseRequestFcn', {@(h,e) feval(mfilename, obj, 'close')});
        
        % --- UI Creation ---
        handles = struct();

        % Log Panel
        uipanel('Title', 'Activity Log', 'FontSize', 12, 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.64, 0.03, 0.34, 0.94]);
        handles.log_box = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [0.65, 0.05, 0.32, 0.89], 'String', {'Log started...'}, 'Max', 10, 'Min', 1, 'HorizontalAlignment', 'left', 'Enable', 'inactive', 'BackgroundColor', [1, 1, 1]);
        
        % Panel 1: Behavior
        p1 = uipanel('Title', '1. Behavior', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.78, 0.6, 0.2]);
        uicontrol(p1, 'Style', 'text', 'String', 'Protocol Name:', 'Units', 'normalized', 'Position', [0.05, 0.75, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.protocol_edit = uicontrol(p1, 'Style', 'edit', 'String', 'ArpitSoundCatContinuous', 'Units', 'normalized', 'Position', [0.3, 0.75, 0.5, 0.2]);
        handles.manual_test = uicontrol(p1, 'Style', 'checkbox', 'String', 'Manual Test', 'Value', 1, 'Units', 'normalized', 'Position', [0.81, 0.75, 0.18, 0.2]);
        uicontrol(p1, 'Style', 'text', 'String', 'Experimenter:', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.exp_edit = uicontrol(p1, 'Style', 'edit', 'String', 'lida', 'Units', 'normalized', 'Position', [0.3, 0.5, 0.65, 0.2]);
        uicontrol(p1, 'Style', 'text', 'String', 'Rat Name:', 'Units', 'normalized', 'Position', [0.05, 0.25, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.rat_name_edit = uicontrol(p1, 'Style', 'edit', 'String', 'LP12', 'Units', 'normalized', 'Position', [0.3, 0.25, 0.65, 0.2]);
        uicontrol(p1, 'Style', 'text', 'String', 'Behav Code Path:', 'Units', 'normalized', 'Position', [0.01, 0.01, 0.28, 0.18], 'HorizontalAlignment', 'right');
        handles.behav_edit = uicontrol(p1, 'Style', 'edit', 'String', 'C:\ratter', 'Units', 'normalized', 'Position', [0.3, 0.01, 0.5, 0.2]);
        handles.behav_browse = uicontrol(p1, 'Style', 'pushbutton', 'String', 'Browse...', 'Units', 'normalized', 'Position', [0.81, 0.01, 0.16, 0.22], 'Callback', {@(h,e) feval(mfilename, obj, 'browse_path', 'behav')});

        % Panel 2: NeuroBlueprint Format
        p2 = uipanel('Title', '2. NeuroBlueprint Format', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.38, 0.6, 0.38]);
        uicontrol(p2, 'Style', 'text', 'String', 'Project Name (Root):', 'Units', 'normalized', 'Position', [0.01, 0.85, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.proj_edit = uicontrol(p2, 'Style', 'edit', 'String', 'sound_cat_rat', 'Units', 'normalized', 'Position', [0.3, 0.85, 0.65, 0.12]);
        uicontrol(p2, 'Style', 'text', 'String', 'Subject ID:', 'Units', 'normalized', 'Position', [0.01, 0.7, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.sub_edit = uicontrol(p2, 'Style', 'edit', 'String', '002', 'Units', 'normalized', 'Position', [0.3, 0.7, 0.65, 0.12]);
        uicontrol(p2, 'Style', 'text', 'String', 'Local Path:', 'Units', 'normalized', 'Position', [0.01, 0.55, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.local_edit = uicontrol(p2, 'Style', 'edit', 'String', 'C:\Ephys_Experiment_Data', 'Units', 'normalized', 'Position', [0.3, 0.55, 0.5, 0.12]);
        handles.local_browse = uicontrol(p2, 'Style', 'pushbutton', 'String', 'Browse...', 'Units', 'normalized', 'Position', [0.81, 0.55, 0.16, 0.13], 'Callback', {@(h,e) feval(mfilename, obj, 'browse_path', 'local')});
        uicontrol(p2, 'Style', 'text', 'String', 'Central Path (for checking only):', 'Units', 'normalized', 'Position', [0.01, 0.4, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.central_edit = uicontrol(p2, 'Style', 'edit', 'String', 'Z:\_projects', 'Units', 'normalized', 'Position', [0.3, 0.4, 0.5, 0.12]);
        handles.central_browse = uicontrol(p2, 'Style', 'pushbutton', 'String', 'Browse...', 'Units', 'normalized', 'Position', [0.81, 0.4, 0.16, 0.13], 'Callback', {@(h,e) feval(mfilename, obj, 'browse_path', 'central')});
        uicontrol(p2, 'Style', 'text', 'String', 'Subfolders to Create:', 'Units', 'normalized', 'Position', [0.05, 0.2, 0.9, 0.1], 'HorizontalAlignment', 'left');
        handles.cb_ephys = uicontrol(p2, 'Style', 'checkbox', 'String', 'ephys', 'Value', 1, 'Units', 'normalized', 'Position', [0.05, 0.05, 0.2, 0.15]);
        handles.cb_behav = uicontrol(p2, 'Style', 'checkbox', 'String', 'behav', 'Value', 1, 'Units', 'normalized', 'Position', [0.28, 0.05, 0.2, 0.15]);
        handles.cb_anat = uicontrol(p2, 'Style', 'checkbox', 'String', 'anat', 'Value', 1, 'Units', 'normalized', 'Position', [0.51, 0.05, 0.2, 0.15]);
        handles.cb_funcimg = uicontrol(p2, 'Style', 'checkbox', 'String', 'funcimg', 'Value', 0, 'Units', 'normalized', 'Position', [0.74, 0.05, 0.25, 0.15]);

        % Panel 3: OpenEphys Settings
        p3 = uipanel('Title', '3. OpenEphys Settings', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.15, 0.6, 0.21]);
        uicontrol(p3, 'Style', 'text', 'String', 'GUI IP Address:', 'Units', 'normalized', 'Position', [0.05, 0.65, 0.3, 0.2], 'HorizontalAlignment', 'right');
        handles.ip_edit = uicontrol(p3, 'Style', 'edit', 'String', '127.0.0.1', 'Units', 'normalized', 'Position', [0.38, 0.65, 0.25, 0.25]);
        uicontrol(p3, 'Style', 'text', 'String', 'Processor ID:', 'Units', 'normalized', 'Position', [0.05, 0.35, 0.3, 0.2], 'HorizontalAlignment', 'right');
        handles.proc_node_edit = uicontrol(p3, 'Style', 'edit', 'String', '100', 'Units', 'normalized', 'Position', [0.38, 0.35, 0.25, 0.25]);
        uicontrol(p3, 'Style', 'text', 'String', 'Record Node ID:', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.3, 0.2], 'HorizontalAlignment', 'right');
        handles.rec_node_edit = uicontrol(p3, 'Style', 'edit', 'String', '101', 'Units', 'normalized', 'Position', [0.38, 0.05, 0.25, 0.25]);
        
        % Main Control Button
        handles.control_button = uicontrol('Style', 'pushbutton', 'String', 'Load',...
            'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', ...
            'Position', [0.02, 0.03, 0.6, 0.1],...
            'BackgroundColor', [0.2, 0.6, 0.8], 'Callback', {@(h,e) feval(mfilename, obj, 'main_control_callback')});
        
        % Store the UI handles struct in an SPH for consistent access
        SoloParamHandle(obj, 'ui_handles', 'value', handles);
        
    % =========================================================================
    %       CASE MAIN_CONTROL_CALLBACK
    % =========================================================================
    case 'main_control_callback'
        switch value(currentState)
            case 'Load', feval(mfilename, obj, 'load_sequence');
            case 'Run',  feval(mfilename, obj, 'run_sequence');
            case 'Stop', feval(mfilename, obj, 'stop_sequence');
        end

    % =========================================================================
    %       WORKFLOW ACTIONS
    % =========================================================================
    case 'load_sequence'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- LOAD sequence initiated ---');
        set(handles.control_button, 'Enable', 'off', 'String', 'Loading...');
        
        params = get_all_params(handles);
        if ~validate_inputs(handles, params)
            feval(mfilename, obj, 'reset_to_load_state');
            return; 
        end
        
        current_params.value = params;
        
        try
            log_message(handles, 'Connecting to Open Ephys GUI...');
            oe_controller.value = OpenEphysHTTPServer(params.gui_ip, 37497);
            log_message(handles, 'Connection successful.');
        catch ME
            log_message(handles, ['ERROR: Failed to connect to OE. Is it running? Details: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg('Failed to connect to Open Ephys GUI.', 'Connection Error');
            feval(mfilename, obj, 'reset_to_load_state');
            return;
        end
        
        [session_path, oe_save_path] = construct_paths(handles, params);
        if isempty(session_path) || ~create_directories(handles, params, session_path)
            feval(mfilename, obj, 'reset_to_load_state');
            return;
        end
        session_base_path.value = session_path;

        if get(handles.cb_ephys, 'Value')
            try
                log_message(handles, ['Setting OE record path to: ' oe_save_path]);
                value(oe_controller).setRecordPath(params.rec_node_id, oe_save_path);
                log_message(handles, 'Successfully set OE record path.');
            catch ME
                log_message(handles, ['ERROR setting OE path: ' ME.message]);
                getReport(ME, 'extended', 'hyperlinks', 'on');
                errordlg('Could not set Open Ephys record path.', 'API Error');
                feval(mfilename, obj, 'reset_to_load_state');
                return;
            end
        end
        
        feval(mfilename, obj, 'initialize_behavior_system');

    case 'initialize_behavior_system'
        params = value(current_params);
        try
            log_message(feval(mfilename, obj, 'get_ui_handles'), 'Initializing behavior control system...');
            behav_obj.value = dispatcher('init');
            h=get_sphandle('owner','dispatcher','name','myfig');
            set(value(h{1}), 'Visible','Off');

            if params.do_manual_test
                feval(mfilename, obj, 'behav_control', 'manual_test');
            else
                feval(mfilename, obj, 'continue_load_after_manual_test');
            end
        catch ME
            log_message(feval(mfilename, obj, 'get_ui_handles'), ['FATAL ERROR initializing behavior system: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg(['Failed to initialize behavior system. Check path and logs. Error: ' ME.message], 'Behavior System Error');
            feval(mfilename, obj, 'reset_to_load_state');
        end

    case 'manual_test_stopping'

        handles = value(ui_handles);
        log_message(handles, 'Manual rig test complete. Cleaning up...');
        dispatcher(value(behav_obj), 'Stop');

        %Let's pause until we know dispatcher is done running
        set(value(stopping_complete_timer), 'TimerFcn', {@(h,e) feval(mfilename, obj, 'manual_test_stopped')});
        start(value(stopping_complete_timer));

    case 'manual_test_stopped'

        if value(stopping_process_completed) %This is provided by RunningSection
            stop(value(stopping_complete_timer)); %Stop looping.
            dispatcher('set_protocol', '');
            is_running.value = 0;
            feval(mfilename, obj, 'continue_load_after_manual_test');
        end

    case 'continue_load_after_manual_test'
        
        params = value(current_params);
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);

        video_save_dir = fullfile(params.local_path, value(session_base_path), 'behav');
        try
            log_message(handles, 'Loading main behavioral protocol...');
            feval(mfilename, obj, 'behav_control', 'load_main_protocol', params.experimenter, params.rat_name, params.protocol_name, video_save_dir, params.behav_path);
            log_message(handles, 'Behavior system loaded and ready.');
            log_message(handles, '--- LOAD sequence complete. Ready to run. ---');
            currentState.value = 'Run';
            set(handles.control_button, 'Enable', 'on', 'String', 'Run', 'BackgroundColor', [0.4, 0.8, 0.4]);
        catch ME
            log_message(handles, ['FATAL ERROR loading main protocol: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg(['Failed to load main protocol. Error: ' ME.message], 'Behavior System Error');
            feval(mfilename, obj, 'reset_to_load_state');
        end

    case 'run_sequence'
        params = value(current_params);
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- RUN sequence initiated ---');
        
        if get(handles.cb_ephys, 'Value')
            try
                log_message(handles, 'Starting OE acquisition and recording...');
                value(oe_controller).acquire();
                pause(1);
                value(oe_controller).record();
                log_message(handles, 'Open Ephys recording is LIVE.');
            catch ME
                log_message(handles, ['ERROR starting OE recording: ' ME.message]);
                getReport(ME, 'extended', 'hyperlinks', 'on');
                errordlg('Failed to start Open Ephys recording.', 'API Error');
                return;
            end
        else
            log_message(handles, 'Ephys checkbox not selected. No OE recording started.');
        end
        
        currentState.value = 'Stop';
        set(handles.control_button, 'String', 'Stop');
        feval(mfilename, obj, 'start_blinking');
        feval(mfilename, obj, 'start_monitoring');
        
        try
            log_message(handles, 'Starting behavioral protocol...');
            feval(mfilename, obj, 'behav_control', 'run', params.protocol_name);
            log_message(handles, 'Behavioral protocol is LIVE.');
        catch ME
            log_message(handles, ['FATAL ERROR starting behavior protocol: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg(['Failed to start behavior protocol. Check logs. Error: ' ME.message], 'Behavior System Error');
        end

    case 'stop_sequence'
        params = value(current_params);
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- STOP sequence initiated ---');
        feval(mfilename, obj, 'stop_blinking');
        
        try
            log_message(handles, 'Ending behavioral session (saving data)...');
            feval(mfilename, obj, 'behav_control', 'end', params.protocol_name, params.behav_path);
            log_message(handles, 'Behavioral data saved successfully.');
        catch ME
            log_message(handles, ['FATAL ERROR ending behavioral session: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg(['Failed to save behavioral data. Check logs. Error: ' ME.message], 'Behavior System Error');
        end
        
        if get(handles.cb_ephys, 'Value') && ~isempty(value(oe_controller))
            try
                log_message(handles, 'Stopping OE recording and acquisition...');
                value(oe_controller).idle();
                log_message(handles, 'Open Ephys recording stopped.');
            catch ME
                log_message(handles, ['ERROR stopping OE recording: ' ME.message]);
                getReport(ME, 'extended', 'hyperlinks', 'on');
                errordlg('Failed to stop Open Ephys recording.', 'API Error');
            end
        end
        
        log_message(handles, '--- Experiment finished. Ready for new session. ---');
        feval(mfilename, obj, 'reset_to_load_state');

    % =========================================================================
    %       BEHAVIOR CONTROL ACTIONS
    % =========================================================================
    case 'behav_control'
        sub_action = varargin{1};
        args = varargin(2:end);
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        
        switch sub_action
           case 'load_main_protocol'
               experimenter = args{1}; ratname = args{2}; protocol_name = args{3}; 
               video_save_dir = args{4}; behav_path = args{5};
               log_message(handles, ['Loading protocol: ' protocol_name]);
               dispatcher('set_protocol', protocol_name);
               rath = get_sphandle('name', 'ratname', 'owner', protocol_name);
               exph = get_sphandle('name', 'experimenter', 'owner', protocol_name);
               rath{1}.value = ratname; exph{1}.value = experimenter;
               protobj = eval(protocol_name);
               log_message(handles, ['Loading settings for ' ratname]);
               [~, sfile] = load_solouiparamvalues(ratname, 'experimenter', experimenter, 'owner', class(protobj), 'interactive', 0);
               if ~dispatcher('is_running'), pop_history(class(protobj), 'include_non_gui', 1); feval(protocol_name, protobj, 'prepare_next_trial'); end
               feval(protocol_name, protobj, 'set_setting_params', ratname, experimenter, sfile, char(datetime('now')), video_save_dir);

            case 'load_protocol_after_crash'
               experimenter = args{1}; ratname = args{2}; protocol_name = args{3}; 
               video_save_dir = args{4}; behav_path = args{5};
               log_message(handles, ['Loading protocol: ' protocol_name]);
               dispatcher('set_protocol', protocol_name);
               rath = get_sphandle('name', 'ratname', 'owner', protocol_name);
               exph = get_sphandle('name', 'experimenter', 'owner', protocol_name);
               rath{1}.value = ratname; exph{1}.value = experimenter;
               protobj = eval(protocol_name);
               % Loading the temporary saved Data file
               today_date = char(datetime('now','format','yyMMdd'));
               temp_data_dir = fullfile(behav_path,'SoloData','Data',experimenter,ratname);
               temp_data_file = sprintf('data_@%s_%s_%s_%s_ASV.mat',protocol_name,experimenter,ratname,today_date);
               if isfile(fullfile(temp_data_dir,temp_data_file))
                   dispatcher('runstart_disable');
                   load_soloparamvalues(ratname, 'experimenter', experimenter,...
                       'owner', protobj, 'interactive', 0,'data_file',fullfile(temp_data_dir,temp_data_file));
                   dispatcher('runstart_enable');
               end
               % [sfile, ~] = SavingSection(protobj, 'get_set_filename');
               if ~dispatcher('is_running'), pop_history(class(protobj), 'include_non_gui', 1); feval(protocol_name, protobj, 'prepare_next_trial'); end
               % feval(protocol_name, protobj, 'set_setting_params', ratname, experimenter, sfile, char(datetime('now')), video_save_dir);

           case 'crashed'
                log_message(handles, '--- BEHAVIOR CRASH RECOVERY INITIATED ---');
                params = value(current_params);
                feval(mfilename, obj, 'behav_control', 'load_protocol_after_crash', params.experimenter, params.rat_name, params.protocol_name, fullfile(params.local_path, value(session_base_path), 'behav'), params.behav_path);
                feval(mfilename, obj, 'behav_control', 'run', params.protocol_name);
                log_message(handles, '--- RECOVERY COMPLETE: Behavior protocol restarted ---');

           case 'run'
                protocol_name = args{1}; protobj = eval(protocol_name);
                log_message(handles, 'Starting video recording via protocol...');
                feval(protocol_name, protobj, 'start_recording');
                log_message(handles, 'Starting dispatcher to run trials...');
                is_running.value = 1;
                dispatcher(value(behav_obj), 'Run');

               
            case 'end'
                protocol_name = args{1}; root_dir = args{2};
                log_message(handles, 'Stopping dispatcher...');
                dispatcher(value(behav_obj), 'Stop');

                %Let's pause until we know dispatcher is done running
               set(value(stopping_complete_timer), 'Period', 2,'TimerFcn', {@(h,e) feval(mfilename, obj, 'behav_control','end_continued',protocol_name, root_dir)});
                %set(value(stopping_complete_timer),'TimerFcn',[mfilename,obj,'behav_control','(''end_continued'');']);
                start(value(stopping_complete_timer));

            case 'end_continued'
                %% end_continued
                if value(stopping_process_completed) %This is provided by RunningSection
                    protocol_name = args{1}; root_dir = args{2};
                    stop(value(stopping_complete_timer)); %Stop looping.                    
                    is_running.value = 0;
                    feval(mfilename, obj, 'behav_control', 'send_empty_state_machine');
                    protobj = eval(protocol_name);
                    log_message(handles, 'Ending session via protocol...');
                    feval(protocol_name, protobj, 'end_session');
                    log_message(handles, 'Saving data and settings...');
                    data_file = SavingSection(protobj, 'savedata', 'interactive', 0);
                    try, feval(protocol_name, protobj, 'pre_saving_settings'); catch, log_message(handles, 'Protocol does not have a pre_saving_settings section.'); end
                    [settings_file, ~] = SavingSection(protobj, 'get_set_filename');
                    SavingSection(protobj, 'savesets', 'interactive', 0);
                    log_message(handles, 'Committing data and settings to SVN...');
                    commit_to_svn(handles, data_file, root_dir);
                    commit_to_svn(handles, settings_file, root_dir);
                    dispatcher('set_protocol', '');
                end

            case 'create_svn_data_dir'
                experimenter = args{1}; ratname = args{2}; behav_dir = args{3}; dir_name = args{4};
                dirCurrent = cd;
                settings_path = fullfile(behav_dir, 'SoloData', dir_name);
                exp_path = fullfile(settings_path, experimenter);
                rat_path = fullfile(exp_path, ratname);
                if ~isfolder(settings_path), mkdir(settings_path); system(['svn add ' dir_name]); end
                if ~isfolder(exp_path), cd(settings_path); mkdir(experimenter); system(['svn add ' experimenter]); end
                if ~isfolder(rat_path), cd(exp_path); mkdir(ratname); system(['svn add ' ratname]); end
                cd(dirCurrent);
                log_message(handles, ['Created SVN directory structure for ' ratname]);

            case 'send_empty_state_machine'
                state_machine_server = bSettings('get', 'RIGS', 'state_machine_server');
                server_slot = bSettings('get', 'RIGS', 'server_slot'); if isnan(server_slot), server_slot = 0; end
                card_slot = bSettings('get', 'RIGS', 'card_slot'); if isnan(card_slot), card_slot = 0; end
                sm = BpodSM(state_machine_server, 3333, server_slot); sm = Initialize(sm);
                [inL, outL] = MachinesSection(dispatcher, 'determine_io_maps');
                sma = StateMachineAssembler('full_trial_structure');
                sma = add_state(sma, 'name', 'vapid_state_in_vapid_matrix');
                send(sma, sm, 'run_trial_asap', 0, 'input_lines', inL, 'dout_lines', outL, 'sound_card_slot', int2str(card_slot));

           case 'manual_test'
               log_message(handles, 'Loading manual rig test protocol...');
               dispatcher('set_protocol', 'Rigtest_singletrial');
               %Hide protocol window.
               h=get_sphandle('owner','Rigtest_singletrial','name', 'myfig');
               for i=1:numel(h); set(value(h{i}),'Visible','Off'); end

               is_running.value = 1;
               log_message(handles, 'Starting manual rig test. Please complete the one-trial test.');
               dispatcher(value(behav_obj), 'Run');
        end
        
    case 'browse_path'
        type = varargin{1};
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, ['Opening browse dialog for ' type ' path...']);
        folder_path = uigetdir;
        if folder_path ~= 0
            if strcmp(type, 'local'), set(handles.local_edit, 'String', folder_path);
            elseif strcmp(type, 'central'), set(handles.central_edit, 'String', folder_path);
            elseif strcmp(type, 'behav'), set(handles.behav_edit, 'String', folder_path);
            end
            log_message(handles, [type ' path set.']);
        else, log_message(handles, 'Path selection cancelled.'); end

    case 'is_running'
            
        obj = logical(value(is_running));
        
    % =========================================================================
    %       OTHER ACTIONS (CLOSE, RESET, etc.)
    % =========================================================================
    case 'reset_to_load_state'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        currentState.value = 'Load';
        set(handles.control_button, 'Enable', 'on', 'String', 'Load', 'BackgroundColor', [0.2, 0.6, 0.8]);
        oe_controller.value = [];
        behav_obj.value = [];
        current_params.value = [];
    
    case 'close'
        feval(mfilename, obj, 'stop_blinking');
        if ishandle(value(myfig)), delete(value(myfig)); end
        delete_sphandle('owner', ['^@' mfilename '$']);
        
    case 'get_ui_handles'
        varargout{1} = value(ui_handles);
        
    case 'start_blinking'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        blinking_timer.value = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, 'TimerFcn', {@toggle_button_color, handles.control_button});
        start(value(blinking_timer));

    case 'stop_blinking'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        if ~isempty(value(blinking_timer)) && isvalid(value(blinking_timer))
            stop(value(blinking_timer));
            delete(value(blinking_timer));
            blinking_timer.value = [];
        end
        set(handles.control_button, 'BackgroundColor', [1, 0.4, 0.4]);
           

    case 'crash_detected'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        if ~strcmp(value(currentState), 'Stop') || isempty(value(behav_obj)), return; end

        log_message(handles, '!!! CRASH DETECTED: Behavior system is not running. Attempting recovery...');
        try
            feval(mfilename, obj, 'behav_control', 'crashed');

        catch ME
            log_message(handles, sprintf('FATAL: Recovery attempt failed: %s', ME.message));
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg('Automatic recovery failed. Please stop the experiment manually.', 'Recovery Failed');
        end
        
end

return;

% =========================================================================
%       SUB-FUNCTIONS
% =========================================================================

function commit_to_svn(handles, file_path_data,file_path_settings, root_dir)
    
if isempty(file_path_data), return; end
    if isempty(file_path_settings), return; end
    [pname_data, fname_data, ext_data] = fileparts(file_path_data);
    [pname_settings, fname_settings, ext_settings] = fileparts(file_path_settings);
    
    configFilePath = fullfile(root_dir,'PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat');
    if ~exist(configFilePath, 'file')
        log_message(handles, ['SVN commit failed: Password config file not found at ' configFilePath]);
        return;
    end
    load(configFilePath, 'svn_user', 'svn_password');
    logmsg = char(strcat('automated commit from GUI for data and settings for ', {' '} ,fname_data,{'@'}));
    % current_dir = cd;
    cd(pname_data);
    add_cmd_data = char(strcat('svn add', {' '}, fname_data, '.mat',{'@'}));
    system(add_cmd_data);

    cd(pname_settings);
    add_cmd_settings = char(strcat('svn add', {' '}, fname_settings, '.mat',{'@'}));
    system(add_cmd_settings);

    commit_cmd = sprintf('svn ci --username="%s" --password="%s" -m "%s"', svn_user, svn_password, logmsg);
    [status, ~] = system(commit_cmd);
    
    if status == 0
        log_message(handles, ['SVN commit successful for ' fname_data]);
    else
        log_message(handles, ['SVN commit FAILED for ' fname_data '.']);
    end
    
    cd(fullfile(root_dir,'ExperPort'));


function params = get_all_params(handles)
    params.protocol_name = get(handles.protocol_edit, 'String');
    params.do_manual_test = get(handles.manual_test, 'Value');
    params.experimenter = get(handles.exp_edit, 'String');
    params.rat_name = get(handles.rat_name_edit, 'String');
    params.behav_path = get(handles.behav_edit, 'String');
    params.project_name = get(handles.proj_edit, 'String');
    params.subject_id = get(handles.sub_edit, 'String');
    params.local_path = get(handles.local_edit, 'String');
    params.central_path = get(handles.central_edit, 'String');
    params.gui_ip = get(handles.ip_edit, 'String');
    params.proc_node_id = get(handles.proc_node_edit, 'String');
    params.rec_node_id = get(handles.rec_node_edit, 'String');


function log_message(handles, logStr)
    if ~isfield(handles, 'log_box') || ~isvalid(handles.log_box), return; end
    current_text = get(handles.log_box, 'String');
    timestamp = datestr(now, '[HH:MM:SS] ');
    new_line = [timestamp, logStr];
    new_text = [current_text; {new_line}];
    set(handles.log_box, 'String', new_text, 'Value', numel(new_text));
    drawnow;


function is_valid = validate_inputs(handles, params)
    is_valid = false; fields = fieldnames(params);
    for i = 1:length(fields)
        if strcmp(fields{i}, 'central_path') && isempty(params.(fields{i})), continue; end
        if isempty(params.(fields{i}))
            msg = ['Field "' strrep(fields{i}, '_', ' ') '" cannot be empty.'];
            log_message(handles, ['ERROR: ' msg]); errordlg(msg, 'Input Error');
            return;
        end
    end
    if ~get(handles.cb_ephys, 'Value') && ~get(handles.cb_behav, 'Value') && ~get(handles.cb_anat, 'Value') && ~get(handles.cb_funcimg, 'Value')
        msg = 'At least one subfolder must be selected.';
        log_message(handles, ['ERROR: ' msg]); errordlg(msg, 'Input Error');
        return;
    end
    is_valid = true;


function [session_base, oe_path] = construct_paths(handles, params)
    subject_name = sprintf('sub-%s_id-%s_expmtr-%s', params.subject_id, params.rat_name, params.experimenter);
    subject_base_path = fullfile(params.project_name, 'rawdata', subject_name);
    local_subject_dir = fullfile(params.local_path, subject_base_path);
    central_subject_dir = fullfile(params.central_path, subject_base_path);
    new_ses_num = max(find_max_session_number(local_subject_dir), find_max_session_number(central_subject_dir)) + 1;
    log_message(handles, sprintf('Last session found: %d. Creating new session: %d.', new_ses_num - 1, new_ses_num));
    session_datetime_str = char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'));
    session_folder_name = sprintf('ses-%02d_date-%s_dtype-ephys', new_ses_num, session_datetime_str);
    session_base = fullfile(subject_base_path, session_folder_name);
    oe_path = fullfile(params.local_path, session_base, 'ephys');
    log_message(handles, ['New session path determined: ' session_base]);


function max_ses = find_max_session_number(base_path)
    max_ses = 0; if ~exist(base_path, 'dir'), return; end
    dir_contents = dir(fullfile(base_path, 'ses-*'));
    if isempty(dir_contents), return; end
    session_numbers = [];
    for i = 1:length(dir_contents)
        if dir_contents(i).isdir
            token = regexp(dir_contents(i).name, '^ses-(\d+)', 'tokens');
            if ~isempty(token), session_numbers(end+1) = str2double(token{1}{1}); end
        end
    end
    if ~isempty(session_numbers), max_ses = max(session_numbers); end

function success = create_directories(handles, params, session_base_path)
    success = false;
    subfolders.ephys = get(handles.cb_ephys, 'Value');
    subfolders.behav = get(handles.cb_behav, 'Value');
    subfolders.anat = get(handles.cb_anat, 'Value');
    subfolders.funcimg = get(handles.cb_funcimg, 'Value');
    selected_folders = fieldnames(subfolders)';
    selected_folders = selected_folders([subfolders.ephys, subfolders.behav, subfolders.anat, subfolders.funcimg] == 1);
    try
        for i = 1:length(selected_folders)
            local_target_path = fullfile(params.local_path, session_base_path, selected_folders{i});
            log_message(handles, ['Creating local directory: ' local_target_path]);
            if ~exist(local_target_path, 'dir'), mkdir(local_target_path); end
        end
        log_message(handles, 'All selected local directories created successfully.');
        success = true;
    catch ME
        msg = sprintf('Failed to create directories: %s', ME.message);
        getReport(ME, 'extended', 'hyperlinks', 'on');
        log_message(handles, ['ERROR: ' msg]); errordlg(msg, 'Directory Error');
    end


function toggle_button_color(~, ~, button_handle)
    if ~isvalid(button_handle), return; end
    currentColor = get(button_handle, 'BackgroundColor');
    if isequal(currentColor, [1, 0.4, 0.4]), set(button_handle, 'BackgroundColor', [1, 0.7, 0.4]);
    else, set(button_handle, 'BackgroundColor', [1, 0.4, 0.4]); end
