% 
function [obj, varargout] = OpenEphys_Neuroblueprint_GUI(varargin)
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
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty')) 
   return; 
end

if isa(varargin{1}, mfilename)
  if length(varargin) < 2 || ~ischar(varargin{2})
    error(['If called with a "%s" object as first arg, a second arg, a ' ...
      'string specifying the action, is required\n']);
  else action = varargin{2}; varargin = varargin(3:end);
  end
else
       action = varargin{1}; varargin = varargin(2:end);
end
if ~ischar(action), error('The action parameter must be a string'); end
GetSoloFunctionArgs(obj);
% --- End of boilerplate ---


switch action
    % =========================================================================
    %       CASE INIT
    % =========================================================================
    case 'init'
        % This case is called once to create the GUI and initialize all parameters.
        
        % So that only the CPU-based software renderer instead of your graphics card
        % opengl software;

        % Start Bpod if not already running
        if evalin('base', 'exist(''BpodSystem'', ''var'')')
            if evalin('base', '~isempty(BpodSystem)'), newstartup; else, flush; end
        else, Bpod('COM5');newstartup;
        end
        
        % --- State Variables as SoloParamHandles ---
        SoloParamHandle(obj, 'currentState', 'value', 'Load');
        SoloParamHandle(obj, 'behavState', 'value', 'Run'); % States for individual buttons
        SoloParamHandle(obj, 'ephysState', 'value', 'Run');
        SoloParamHandle(obj, 'oe_controller', 'value', []);
        SoloParamHandle(obj, 'behav_obj', 'value', []);
        SoloParamHandle(obj, 'blinking_timer', 'value', []);
        SoloParamHandle(obj, 'current_params', 'value', []);
        SoloParamHandle(obj, 'session_base_path', 'value', '');
        SoloParamHandle(obj,'is_running','value',0);
        SoloParamHandle(obj, 'probe_settings', 'value', struct('version', '2.0', 'reference', 'Tip', 'bank', 0, 'imro_path', ''));
        SoloParamHandle(obj, 'probe_gui_handles', 'value', []);

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
        p1 = uipanel('Title', '1. Behavior', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.82, 0.6, 0.16]);
        uicontrol(p1, 'Style', 'text', 'String', 'Protocol Name:', 'Units', 'normalized', 'Position', [0.05, 0.75, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.protocol_edit = uicontrol(p1, 'Style', 'edit', 'String', 'ArpitSoundCatContinuous', 'Units', 'normalized', 'Position', [0.3, 0.75, 0.5, 0.2]);
        handles.manual_test = uicontrol(p1, 'Style', 'checkbox', 'String', 'Manual Test', 'Value', 1, 'Units', 'normalized', 'Position', [0.81, 0.75, 0.18, 0.2]);
        uicontrol(p1, 'Style', 'text', 'String', 'Experimenter:', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.exp_edit = uicontrol(p1, 'Style', 'edit', 'String', 'lida', 'Units', 'normalized', 'Position', [0.3, 0.5, 0.65, 0.2], 'Callback', {@(h,e) feval(mfilename, obj, 'update_subject_id')});
        uicontrol(p1, 'Style', 'text', 'String', 'Rat Name:', 'Units', 'normalized', 'Position', [0.05, 0.25, 0.22, 0.18], 'HorizontalAlignment', 'right');
        handles.rat_name_edit = uicontrol(p1, 'Style', 'edit', 'String', 'LP12', 'Units', 'normalized', 'Position', [0.3, 0.25, 0.65, 0.2], 'Callback', {@(h,e) feval(mfilename, obj, 'update_subject_id')});
        uicontrol(p1, 'Style', 'text', 'String', 'Behav Code Path:', 'Units', 'normalized', 'Position', [0.01, 0.01, 0.28, 0.18], 'HorizontalAlignment', 'right');
        handles.behav_edit = uicontrol(p1, 'Style', 'edit', 'String', 'C:\ratter', 'Units', 'normalized', 'Position', [0.3, 0.01, 0.5, 0.2]);
        handles.behav_browse = uicontrol(p1, 'Style', 'pushbutton', 'String', 'Browse...', 'Units', 'normalized', 'Position', [0.81, 0.01, 0.16, 0.22], 'Callback', {@(h,e) feval(mfilename, obj, 'browse_path', 'behav')});

        % Panel 2: NeuroBlueprint Format
        p2 = uipanel('Title', '2. NeuroBlueprint Format', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.42, 0.6, 0.38]);
        uicontrol(p2, 'Style', 'text', 'String', 'Project Name (Root):', 'Units', 'normalized', 'Position', [0.01, 0.85, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.proj_edit = uicontrol(p2, 'Style', 'edit', 'String', 'sound_cat_rat', 'Units', 'normalized', 'Position', [0.3, 0.85, 0.65, 0.12]);
        uicontrol(p2, 'Style', 'text', 'String', 'Subject ID:', 'Units', 'normalized', 'Position', [0.01, 0.7, 0.28, 0.1], 'HorizontalAlignment', 'right');
        handles.sub_edit = uicontrol(p2, 'Style', 'edit', 'String', '000', 'Units', 'normalized', 'Position', [0.3, 0.7, 0.65, 0.12]);
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

        % Panel 3: Pre-Experiment Sampling
        p3 = uipanel('Title', '3. Pre/Post-Experiment Sampling', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.28, 0.6, 0.12]);
        uicontrol(p3, 'Style', 'text', 'String', 'Duration/Bank (s):', 'Units', 'normalized', 'Position', [0.01, 0.6, 0.25, 0.25], 'HorizontalAlignment', 'right');
        handles.sample_duration = uicontrol(p3, 'Style', 'edit', 'String', '60', 'Units', 'normalized', 'Position', [0.27, 0.6, 0.1, 0.3]);
        handles.target_display = uicontrol(p3, 'Style', 'text', 'String', 'Target: Bank 0', 'Units', 'normalized', 'Position', [0.38, 0.6, 0.3, 0.25], 'HorizontalAlignment', 'right', 'FontWeight', 'bold');
        handles.probe_button = uicontrol(p3, 'Style', 'pushbutton', 'String', 'Probe Setting', 'Units', 'normalized', 'Position', [0.7, 0.55, 0.28, 0.4], 'FontSize', 10, 'Callback', {@(h,e) feval(mfilename, obj, 'open_probe_gui')});
        handles.sample_button = uicontrol(p3, 'Style', 'pushbutton', 'String', 'Start Sample Recording', 'Units', 'normalized', 'Position', [0.05, 0.1, 0.9, 0.4], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.8, 0.7, 1], 'Callback', {@(h,e) feval(mfilename, obj, 'sample_recording_wrapper')});

        % Panel 4: OpenEphys Settings
        p4 = uipanel('Title', '4. OpenEphys Settings', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.15, 0.6, 0.11]);
        uicontrol(p4, 'Style', 'text', 'String', 'GUI IP:', 'Units', 'normalized', 'Position', [0.01, 0.3, 0.15, 0.4], 'HorizontalAlignment', 'right');
        handles.ip_edit = uicontrol(p4, 'Style', 'edit', 'String', '127.0.0.1', 'Units', 'normalized', 'Position', [0.17, 0.25, 0.15, 0.5]);
        uicontrol(p4, 'Style', 'text', 'String', 'Proc ID:', 'Units', 'normalized', 'Position', [0.33, 0.3, 0.15, 0.4], 'HorizontalAlignment', 'right');
        handles.proc_node_edit = uicontrol(p4, 'Style', 'edit', 'String', '100', 'Units', 'normalized', 'Position', [0.49, 0.25, 0.15, 0.5]);
        uicontrol(p4, 'Style', 'text', 'String', 'Rec ID:', 'Units', 'normalized', 'Position', [0.65, 0.3, 0.15, 0.4], 'HorizontalAlignment', 'right');
        handles.rec_node_edit = uicontrol(p4, 'Style', 'edit', 'String', '101', 'Units', 'normalized', 'Position', [0.81, 0.25, 0.15, 0.5]);
        
        % --- Control Buttons Panel ---
        p5 = uipanel('Title', 'Controls', 'FontSize', 12, 'FontWeight', 'bold', 'BorderType', 'etchedin', 'BorderWidth', 1, 'Units', 'normalized', 'Position', [0.02, 0.02, 0.6, 0.11]);
        handles.control_button = uicontrol(p5, 'Style', 'pushbutton', 'String', 'Load', 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', 'Position', [0.02, 0.1, 0.3, 0.8], 'BackgroundColor', [0.2, 0.6, 0.8], 'Callback', {@(h,e) feval(mfilename, obj, 'main_control_callback')});
        handles.behav_button = uicontrol(p5, 'Style', 'pushbutton', 'String', 'Run Behav', 'Units', 'normalized', 'FontSize', 12, 'Position', [0.35, 0.1, 0.3, 0.8], 'BackgroundColor', [1, 0.8, 0.6], 'Callback', {@(h,e) feval(mfilename, obj, 'behav_control_callback')});
        handles.ephys_button = uicontrol(p5, 'Style', 'pushbutton', 'String', 'Run Ephys', 'Units', 'normalized', 'FontSize', 12, 'Position', [0.68, 0.1, 0.3, 0.8], 'BackgroundColor', [0.8, 0.6, 1], 'Callback', {@(h,e) feval(mfilename, obj, 'ephys_control_callback')});

        % Store the UI handles struct in an SPH for consistent access
        SoloParamHandle(obj, 'ui_handles', 'value', handles);
        
        % Run initial subject ID check on startup
        feval(mfilename, obj, 'update_subject_id');

    % =========================================================================
    %       CASE MAIN_CONTROL_CALLBACK
    % =========================================================================
    case 'main_control_callback'
        switch value(currentState)
            case 'Load', feval(mfilename, obj, 'load_sequence');
            case 'Run',  feval(mfilename, obj, 'run_sequence');
            case 'Stop', feval(mfilename, obj, 'stop_sequence');
            case 'PostExperiment', feval(mfilename, obj, 'reset_to_load_state');
        end

    % =========================================================================
    %       WORKFLOW ACTIONS
    % =========================================================================
    case 'load_sequence'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- LOAD sequence initiated ---');
        set(handles.control_button, 'Enable', 'off', 'String', 'Loading...');
        set(handles.sample_button, 'Enable', 'off');
        
        params = get_all_params(handles);
        if ~validate_inputs(handles, params)
            feval(mfilename, obj, 'reset_to_load_state');
            return; 
        end
        
        current_params.value = params;
        
        

        [session_path, oe_save_path] = construct_paths(handles, params);
        if isempty(session_path) || ~create_directories(handles, params, session_path)
            feval(mfilename, obj, 'reset_to_load_state');
            return;
        end
        session_base_path.value = session_path;

        % if get(handles.cb_ephys, 'Value')
        %     try
        %         log_message(handles, ['Setting OE record path to: ' oe_save_path]);
        %         value(oe_controller).setRecordPath(params.rec_node_id, oe_save_path);
        %         log_message(handles, 'Successfully set OE record path.');
        %     catch ME
        %         log_message(handles, ['ERROR setting OE path: ' ME.message]);
        %         getReport(ME, 'extended', 'hyperlinks', 'on');
        %         errordlg('Could not set Open Ephys record path.', 'API Error');
        %         feval(mfilename, obj, 'reset_to_load_state');
        %         return;
        %     end
        % end
        
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
        set(handles.sample_button, 'Enable', 'off');
        
        % --- EPHYS CONNECTION ---
        if get(handles.cb_ephys, 'Value')
            try
                if isempty(value(oe_controller))
                    log_message(handles, 'Connecting to Open Ephys GUI...');
                    oe_controller.value = OpenEphysHTTPServer(params.gui_ip, 37497);
                    if isempty(value(oe_controller)), error('Failed to create OE controller.'); end
                end
                
                log_message(handles, 'Applying probe settings for main experiment...');
                settings = value(probe_settings);
                value(oe_controller).setParameters(params.proc_node_id, 0, 'Reference', settings.reference);
                if ~isempty(settings.imro_path)
                    value(oe_controller).config(params.proc_node_id, ['LOADIMRO ' settings.imro_path]);
                else
                    value(oe_controller).setParameters(params.proc_node_id, 0, 'bank', settings.bank);
                end

                main_ephys_path = fullfile(params.local_path, value(session_base_path), 'ephys');
                log_message(handles, ['Confirming main record path: ' main_ephys_path]);
                value(oe_controller).setRecordPath(params.rec_node_id, main_ephys_path);
                pause(1);
                log_message(handles, 'Starting OE acquisition and recording...');
                value(oe_controller).acquire();
                pause(1);
                value(oe_controller).record();
                log_message(handles, 'Open Ephys recording is LIVE.');
                ephysState.value = 'Stop';
                set(handles.ephys_button, 'String', 'Stop Ephys', 'BackgroundColor', [1 0.6 0.6]);

            catch ME
                log_message(handles, ['ERROR starting OE recording: ' ME.message]);
                getReport(ME, 'extended', 'hyperlinks', 'on');
                errordlg('Failed to start Open Ephys recording. Check command window for details.', 'API Error');
                return;
            end
        else
            log_message(handles, 'Ephys checkbox not selected. No OE recording started.');
        end

        currentState.value = 'Stop';
        set(handles.control_button, 'String', 'Stop');
        feval(mfilename, obj, 'start_blinking');
        
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
        behav_save_dir = fullfile(params.local_path, value(session_base_path), 'behav');

        try
            log_message(handles, 'Ending behavioral session (saving data)...');
            feval(mfilename, obj, 'behav_control', 'end', params.protocol_name, params.behav_path,behav_save_dir);
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
        
        log_message(handles, '--- Experiment finished. Post-session sampling is now available. ---');
        
        currentState.value = 'PostExperiment';
        set(handles.control_button, 'String', 'Start New Experiment', 'BackgroundColor', [0.2, 0.8, 0.6]);
        set(handles.sample_button, 'Enable', 'on');


    % =========================================================================
    %       INDIVIDUAL CONTROL CALLBACKS
    % =========================================================================
    case 'behav_control_callback'
        switch value(behavState)
            case 'Run', feval(mfilename, obj, 'behav_control', 'load_run');
            case 'Stop', feval(mfilename, obj, 'behav_control', 'end');
        end
        
    case 'ephys_control_callback'
        switch value(ephysState)
            case 'Run', feval(mfilename, obj, 'run_ephys_only');
            case 'Stop', feval(mfilename, obj, 'stop_ephys_only');
        end
        
    case 'run_ephys_only'
        params = value(current_params);
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- Starting Ephys Recording Individually ---');
        set(handles.ephys_button, 'Enable', 'off');

        try
            if isempty(value(oe_controller)), oe_controller.value = OpenEphysHTTPServer(params.gui_ip, 37497); end
            log_message(handles, 'Connected to Open Ephys GUI...');
                      
            % Apply probe settings
            log_message(handles, 'Applying probe settings...');
            settings = value(probe_settings);
            log_message(handles, ['- Setting Reference to: ' settings.reference]);
            value(oe_controller).setParameters(params.proc_node_id, 0, 'Reference', settings.reference);
            if ~isempty(settings.imro_path)
                log_message(handles, ['- Loading IMRO file: ' settings.imro_path]);
                config_string = ['LOADIMRO ' settings.imro_path];
                value(oe_controller).config(params.proc_node_id, config_string);
            else
                log_message(handles, ['- Setting Bank to: ' num2str(settings.bank)]);
                value(oe_controller).setParameters(params.proc_node_id, 0, 'bank', settings.bank);
            end
            log_message(handles, 'Probe settings applied successfully.');

            main_ephys_path = fullfile(params.local_path, value(session_base_path), 'ephys');
            
            % Set Record Path and Start Recording
            value(oe_controller).setRecordPath(params.rec_node_id, main_ephys_path); pause(1);
            value(oe_controller).acquire(); pause(1); value(oe_controller).record();
            log_message(handles, 'Ephys recording is LIVE.');
            ephysState.value = 'Stop';
            set(handles.ephys_button, 'String', 'Stop Ephys', 'BackgroundColor', [1 0.6 0.6]);
        catch ME
            log_message(handles, ['ERROR starting ephys: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
        end
        set(handles.ephys_button, 'Enable', 'on');
        
    case 'stop_ephys_only'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, '--- Stopping Ephys Recording Individually ---');
        set(handles.ephys_button, 'Enable', 'off');
        try
            if ~isempty(value(oe_controller)), value(oe_controller).idle(); end
            log_message(handles, 'Ephys recording stopped.');
            ephysState.value = 'Run';
            set(handles.ephys_button, 'String', 'Run Ephys', 'BackgroundColor', [0.8, 0.6, 1]);
        catch ME
            log_message(handles, ['ERROR stopping ephys: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
        end
        set(handles.ephys_button, 'Enable', 'on');

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
               try
                   log_message(handles, ['Loading previous data for ' ratname]);
                   today_date = char(datetime('now','format','yyMMdd'));
                   temp_data_dir = fullfile(behav_path,'SoloData','Data',experimenter,ratname);
                   temp_data_file = sprintf('data_@%s_%s_%s_%s_ASV.mat',protocol_name,experimenter,ratname,today_date);
                   if isfile(fullfile(temp_data_dir,temp_data_file))
                       dispatcher('runstart_disable');
                       load_soloparamvalues(ratname, 'experimenter', experimenter,...
                           'owner', protocol_name, 'interactive', 0,'data_file',fullfile(temp_data_dir,temp_data_file));
                       dispatcher('runstart_enable');
                   end
                   if ~dispatcher('is_running'), pop_history(class(protobj), 'include_non_gui', 1); feval(protocol_name, protobj, 'prepare_next_trial'); end
               catch % else loading the saved setting file
                   log_message(handles, ['Loading settings for ' ratname]);
                   [~, sfile] = load_solouiparamvalues(ratname, 'experimenter', experimenter, 'owner', class(protobj), 'interactive', 0);
                   feval(protocol_name, protobj, 'set_setting_params', ratname, experimenter, sfile, char(datetime('now')), video_save_dir);
                   if ~dispatcher('is_running'), pop_history(class(protobj), 'include_non_gui', 1); feval(protocol_name, protobj, 'prepare_next_trial'); end                   
               end

           case 'load_run'
                set(handles.behav_button, 'Enable', 'off');
                log_message(handles, '--- STARTING BEHAV PROTOCOL ---');
                params = value(current_params);                
                video_save_dir = fullfile(params.local_path, value(session_base_path), 'behav');
                feval(mfilename, obj, 'behav_control', 'load_protocol_after_crash', params.experimenter, params.rat_name, params.protocol_name, video_save_dir, params.behav_path);
                feval(mfilename, obj, 'behav_control', 'run', params.protocol_name);
                log_message(handles, '--- START COMPLETE: Behavior protocol started ---');
                set(handles.behav_button, 'Enable', 'on');

           case 'crashed'
                log_message(handles, '--- BEHAVIOR CRASH RECOVERY INITIATED ---');
                params = value(current_params);
                video_save_dir = fullfile(params.local_path, value(session_base_path), 'behav');
                feval(mfilename, obj, 'behav_control', 'load_protocol_after_crash', params.experimenter, params.rat_name, params.protocol_name, video_save_dir, params.behav_path);
                feval(mfilename, obj, 'behav_control', 'run', params.protocol_name);
                log_message(handles, '--- RECOVERY COMPLETE: Behavior protocol restarted ---');

           case 'run'
                protocol_name = args{1}; protobj = eval(protocol_name);
                log_message(handles, 'Starting video recording via protocol...');
                feval(protocol_name, protobj, 'start_recording');
                log_message(handles, 'Starting dispatcher to run trials...');
                is_running.value = 1;
                behavState.value = 'Stop';
                set(handles.behav_button, 'String', 'Stop Behav', 'BackgroundColor', [1 0.6 0.6]);
                dispatcher(value(behav_obj), 'Run');

               
            case 'end'
                set(handles.behav_button, 'Enable', 'off');
                protocol_name = args{1}; root_dir = args{2}; behav_copy_dir = args{3};
                log_message(handles, 'Stopping dispatcher...');
                dispatcher(value(behav_obj), 'Stop');

                %Let's pause until we know dispatcher is done running
               set(value(stopping_complete_timer), 'Period', 0.8,'TimerFcn', {@(h,e) feval(mfilename, obj, 'behav_control','end_continued',protocol_name, root_dir,behav_copy_dir)});
                start(value(stopping_complete_timer));

            case 'end_continued'
                %% end_continued
                if value(stopping_process_completed) %This is provided by RunningSection
                    protocol_name = args{1}; root_dir = args{2}; destination_path = args{3};
                    stop(value(stopping_complete_timer)); %Stop looping.                    
                    is_running.value = 0;
                    feval(mfilename, obj, 'behav_control', 'send_empty_state_machine');
                    protobj = eval(protocol_name);
                    log_message(handles, 'Ending session via protocol...');
                    feval(protocol_name, protobj, 'end_session');
                    log_message(handles, 'Saving data and settings...');
                    data_file = SavingSection(protobj, 'savedata', 'interactive', 0);
                    try 
                        feval(protocol_name, protobj, 'pre_saving_settings'); 
                    catch 
                        log_message(handles, 'Protocol does not have a pre_saving_settings section.'); 
                    end
                    [settings_file, ~] = SavingSection(protobj, 'get_set_filename');
                    SavingSection(protobj, 'savesets', 'interactive', 0);
                    log_message(handles, 'Committing data and settings to SVN...');
                    commit_to_svn(handles, data_file, settings_file, root_dir);
                    dispatcher('set_protocol', '');
                 
                    data_file = [data_file '.mat'];
                    % Copy the data file to the folder saving ephys data                    
                    [status, msg] = copyfile(data_file, destination_path);
                    % Check if the copy was successful
                    if status
                        log_message(handles,'Data File copied successfully.');
                    else
                        log_message(handles,['Error copying Data file: ' msg]);
                    end

                    behavState.value = 'Run';
                    set(handles.behav_button, 'String', 'Run Behav', 'BackgroundColor', [1, 0.8, 0.6]);

                    % Saving the Log file
                    feval(mfilename, obj, 'save_log_file'); % Save the log file
                    set(handles.behav_button, 'Enable', 'on');
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
            
        if exist('is_running','var') == 1
            obj = logical(value(is_running));
        else
            obj = 0;
        end
        
    % =========================================================================
    %       OTHER ACTIONS (CLOSE, RESET, etc.)
    % =========================================================================
    case 'reset_to_load_state'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        currentState.value = 'Load';
        behavState.value = 'Run';
        ephysState.value = 'Run';
        set(handles.control_button, 'Enable', 'on', 'String', 'Load', 'BackgroundColor', [0.2, 0.6, 0.8]);
        oe_controller.value = [];
        behav_obj.value = [];
        current_params.value = [];
    
    case 'close'        
        try
            feval(mfilename, obj, 'stop_blinking');
            if ishandle(value(myfig)), delete(value(myfig)); end
            delete_sphandle('owner', ['^@' mfilename '$']);
            dispatcher(value(behav_obj),'close');
            obj = [];
        catch 
            if ishandle(value(myfig)), delete(value(myfig)); end
            delete_sphandle('owner', ['^@' mfilename '$']);
            obj = [];
        end

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


    %% SAMPLE EPHYS RECORDINGS   
    case 'sample_recording_wrapper'
        % This wrapper determines if we are doing a pre- or post-session sample
        if strcmp(value(currentState), 'PostExperiment')
            feval(mfilename, obj, 'sample_recording', 'post_session');
        else
            feval(mfilename, obj, 'sample_recording', 'pre_session');
        end
        

    case 'sample_recording'
        prefix = varargin{1}; % 'pre_session' or 'post_session'
        %handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, ['--- ' upper(prefix) ' SAMPLE RECORDING INITIATED ---']);
        set([handles.sample_button, handles.control_button], 'Enable', 'off', 'String', 'Sampling...');
        drawnow;

        params = get_all_params(handles);
        
        % Ensure we have an OE connection
        if isempty(value(oe_controller))
            try
                log_message(handles, 'Connecting to Open Ephys GUI for sampling...');
                oe_controller.value = OpenEphysHTTPServer(params.gui_ip, 37497);
                if isempty(value(oe_controller)), error('Failed to connect.'); end
            catch ME
                log_message(handles, ['ERROR: Could not connect to OE: ' ME.message]);
                errordlg('Could not connect to Open Ephys for sampling.', 'Connection Error');
                feval(mfilename, obj, 'reset_to_load_state');
                return;
            end
        end

        % Create directories if they don't exist yet
        if isempty(value(session_base_path))
            [session_path, ~] = construct_paths(handles, params);
            if isempty(session_path) || ~create_directories(handles, params, session_path)
                feval(mfilename, obj, 'reset_to_load_state');
                return;
            end
            session_base_path.value = session_path;
        end
        
        sample_dir_name = [prefix '_sample_recording'];
        sample_save_path = fullfile(params.local_path, value(session_base_path), 'ephys', sample_dir_name);
        if ~exist(sample_save_path, 'dir'), mkdir(sample_save_path); end
        
        duration = str2double(get(handles.sample_duration, 'String'));
        settings = value(probe_settings);
        
        try
            log_message(handles, ['- Setting Reference to: ' settings.reference]);
            value(oe_controller).setParameters(params.proc_node_id, 0, 'Reference', settings.reference);
            
            if strcmp(settings.version, '1.0'), num_banks = 3; else, num_banks = 4; end
            
            for bank = 0:(num_banks - 1)
                log_message(handles, sprintf('Switching to Neuropixel Bank %d...', bank));
                value(oe_controller).setParameters(params.proc_node_id, 0, 'bank', bank);
                pause(1); % Allow time for the setting to apply          
                log_message(handles, sprintf('Recording Bank %d for %d seconds...', bank, duration));
                value(oe_controller).setRecordPath(params.rec_node_id, sample_save_path);
                pause(1); % Allow time for the setting to apply
                value(oe_controller).acquire(duration);
                pause(1); % Allow acquisition to stabilize
                value(oe_controller).record(duration);
                value(oe_controller).idle(); % Stop recording, but keep acquiring              
                log_message(handles, sprintf('Finished recording Bank %d.', bank));
                pause(1);
            end
            
            log_message(handles, 'Restoring probe settings for main experiment...');
            if ~isempty(settings.imro_path)
                config_string = ['LOADIMRO ' settings.imro_path];
                value(oe_controller).config(params.proc_node_id, config_string);
            else
                value(oe_controller).setParameters(params.proc_node_id, 0, 'bank', settings.bank);
            end
            
            log_message(handles, '--- SAMPLE RECORDING COMPLETE ---');
            
        catch ME
            log_message(handles, ['ERROR during sample recording: ' ME.message]);
            getReport(ME, 'extended', 'hyperlinks', 'on');
            errordlg('An error occurred during sample recording. Check command window.', 'Sampling Error');
            value(oe_controller).idle(); % Attempt to stop recording
        end
        
        % Reset button states
        if strcmp(value(currentState), 'PostExperiment')
            set(handles.control_button, 'Enable', 'on', 'String', 'Start New Experiment');
            set(handles.sample_button, 'Enable', 'on', 'String', 'Start Sample Recording');
            
            % Save/overwrite the log file after sampling is complete
            feval(mfilename, obj, 'save_log_file');
        else
            set(handles.control_button, 'Enable', 'on', 'String', 'Load');
            set(handles.sample_button, 'Enable', 'on', 'String', 'Start Sample Recording');
        end


        
    case 'open_probe_gui'
        % This action opens the separate GUI for probe settings.
        %handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        log_message(handles, 'Opening probe settings GUI...');
        
        probe_fig = figure('Name', 'Neuropixel Probe Settings', 'Position', [300 300 450 250], ...
            'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', 'Resize', 'off');
        
        p_handles = struct();
        
        % Probe Version
        p_handles.version_group = uibuttongroup(probe_fig, 'Title', 'Probe Version', 'Position', [0.05 0.7 0.9 0.25]);
        uicontrol(p_handles.version_group, 'Style', 'radiobutton', 'String', 'NP 1.0 (3 Banks)', 'Position', [10 5 150 25], 'Tag', '1.0');
        uicontrol(p_handles.version_group, 'Style', 'radiobutton', 'String', 'NP 2.0 (4 Banks)', 'Position', [200 5 150 25], 'Tag', '2.0');
        
        % Reference Selection
        p_handles.ref_group = uibuttongroup(probe_fig, 'Title', 'Reference', 'Position', [0.05 0.4 0.4 0.25]);
        uicontrol(p_handles.ref_group, 'Style', 'radiobutton', 'String', 'Tip', 'Position', [10 5 100 25], 'Tag', 'Tip');
        uicontrol(p_handles.ref_group, 'Style', 'radiobutton', 'String', 'External', 'Position', [100 5 100 25], 'Tag', 'External');
        
        % Bank Selection Panel (can be disabled)
        p_handles.bank_panel = uipanel(probe_fig, 'Title', 'Target Bank', 'Position', [0.5 0.4 0.45 0.25]);
        uicontrol(p_handles.bank_panel, 'Style', 'text', 'String', 'Bank:', 'Position', [10 5 40 20]);
        p_handles.bank_edit = uicontrol(p_handles.bank_panel, 'Style', 'edit', 'String', '0', 'Position', [60 5 50 25]);
        
        % IMRO File
        uicontrol(probe_fig, 'Style', 'text', 'String', 'IMRO File:', 'Position', [20 80 60 20]);
        p_handles.imro_text = uicontrol(probe_fig, 'Style', 'text', 'String', 'None selected', 'Position', [90 80 280 20], 'HorizontalAlignment', 'left');
        uicontrol(probe_fig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [20 45 100 30], ...
            'Callback', {@(h,e) feval(mfilename, obj, 'browse_imro', p_handles)});
        uicontrol(probe_fig, 'Style', 'pushbutton', 'String', 'Clear IMRO', 'Position', [130 45 100 30], ...
            'Callback', {@(h,e) feval(mfilename, obj, 'clear_imro', p_handles)});
            
        % Apply Button
        uicontrol(probe_fig, 'Style', 'pushbutton', 'String', 'Apply & Close', 'Position', [250 15 180 30], ...
            'FontWeight', 'bold', 'Callback', {@(h,e) feval(mfilename, obj, 'apply_probe_settings', p_handles)});
            
        probe_gui_handles.value = p_handles;
        
    case 'browse_imro'
        p_handles = varargin{1};
        [file, path] = uigetfile('*.imro', 'Select IMRO File');
        if isequal(file, 0) || isequal(path, 0)
            % User cancelled
            return;
        else
            full_path = fullfile(path, file);
            set(p_handles.imro_text, 'String', full_path);
        end
    
    case 'clear_imro'
        p_handles = varargin{1};
        set(p_handles.imro_text, 'String', 'None selected');
        % Re-enable bank selection
        set(findobj(p_handles.bank_panel, '-property', 'Enable'), 'Enable', 'on');
        

    case 'apply_probe_settings'
        p_handles = varargin{1};
        
        %handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        
        % Get values from the probe GUI
        settings.version = get(get(p_handles.version_group, 'SelectedObject'), 'Tag');
        settings.reference = get(get(p_handles.ref_group, 'SelectedObject'), 'Tag');
        settings.bank = str2double(get(p_handles.bank_edit, 'String'));
        settings.imro_path = get(p_handles.imro_text, 'String');
        if strcmp(settings.imro_path, 'None selected'), settings.imro_path = ''; end
        
        % Save settings to the main GUI's SPH
        probe_settings.value = settings;
        
        % Update the main GUI display
        if ~isempty(settings.imro_path)
            set(handles.target_display, 'String', 'Target: IMRO File');
        else
            set(handles.target_display, 'String', ['Target: Bank ' num2str(settings.bank)]);
        end
        
        log_message(handles, 'Probe settings saved.');
        
        % Close the probe GUI
        close(p_handles.ref_group.Parent);
        probe_gui_handles.value = [];

   case 'update_subject_id'
        % handles = feval(mfilename, obj, 'get_ui_handles');
        handles = value(ui_handles);
        params = get_all_params(handles);
        
        % Don't run if essential fields are empty
        if isempty(params.local_path) || isempty(params.central_path) || isempty(params.project_name) || isempty(params.rat_name)
            return;
        end

        max_local_id = find_max_subject_id(params.local_path, params.project_name, params.rat_name);
        max_central_id = find_max_subject_id(params.central_path, params.project_name, params.rat_name);

        final_id = max(max_local_id, max_central_id);

        if final_id > 0
            log_message(handles, ['Found existing Subject ID: ' num2str(final_id) '. Populating field.']);
            set(handles.sub_edit, 'String', sprintf('%03d', final_id)); % Format as 3 digits
        else
            log_message(handles, 'No existing Subject ID found for this rat. Please enter a new ID.');
        end

   case 'save_log_file'
        
       %handles = feval(mfilename, obj, 'get_ui_handles');
       handles = value(ui_handles);
        params = value(current_params);
        session_path = value(session_base_path);
        
        if isempty(session_path)
            log_message(handles, 'WARNING: Cannot save log file. Session path not set.');
            return;
        end
        
        log_path = fullfile(params.local_path, session_path, 'behav');
        if ~exist(log_path, 'dir')
            log_message(handles, ['WARNING: Behavior folder not found. Cannot save log. Path: ' log_path]);
            return;
        end
        
        log_file_path = fullfile(log_path, 'session_log.txt');
        
        try
            log_content = get(handles.log_box, 'String');
            fid = fopen(log_file_path, 'w');
            if fid == -1
                error('Could not open file for writing.');
            end
            for i = 1:length(log_content)
                fprintf(fid, '%s\n', log_content{i});
            end
            fclose(fid);
            log_message(handles, ['Log file saved successfully to: ' log_file_path]);
        catch ME
            log_message(handles, ['ERROR: Could not save log file. Details: ' ME.message]);
        end     

end % end of action

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
        if strcmp(fields{i}, 'experimenter'), continue; end % Make experimenter optional
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
    
    if isempty(params.experimenter)
        subject_name = sprintf('sub-%s_id-%s', params.subject_id, params.rat_name);
    else
        subject_name = sprintf('sub-%s_id-%s_expmtr-%s', params.subject_id, params.rat_name, params.experimenter);
    end
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

function max_id = find_max_subject_id(base_path, project, rat)
    max_id = 0;
    search_path = fullfile(base_path, project, 'rawdata');
    if ~exist(search_path, 'dir'), return; end
    
    dir_contents = dir(search_path);
    if isempty(dir_contents), return; end
    
    subject_ids = [];
    pattern = sprintf('^sub-(\\d+)_id-%s', rat); % Match based on rat name only
    
    for i = 1:length(dir_contents)
        if dir_contents(i).isdir
            token = regexp(dir_contents(i).name, pattern, 'tokens');
            if ~isempty(token)
                subject_ids(end+1) = str2double(token{1}{1});
            end
        end
    end
    
    if ~isempty(subject_ids)
        max_id = max(subject_ids);
    end


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
