% RunRats(varargin)
% This is the GUI for technicians in the lab to use for day to day running
% of rats.  The logic of the code follows that of dispatcher.

% The original RunRats was written bu Jeff Erlich with modifications by
% Sebastien Awwad, 2007-2008 and Sundeep Tuteja, 2009
%
% This is a complete rewrite written by     Chuck Kopec 2011
% Maintenance features added by             Chuck Kopec 2012
% 9 shift expansion by                      Chuck Kopec 2013
% being changed for Akrami Lab              Sharbat 2019


function [obj, varargout]=runrats(varargin)

%Argument handling
obj = class(struct, mfilename, sqlsummary);
varargout = {};
if nargin==0 || nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty'),
    return;
end;

% This line is required for the use of SoloParams
GetSoloFunctionArgs;

if nargin>=2 && isa(varargin{1}, class(obj)), action = varargin{2}; varargin = varargin(3:end);
else                                          action = varargin{1}; varargin = varargin(2:end);
end;
if ~ischar(action)
    error('Runrats expects to be called with a string as the first argument specifying the action to perform. E.g.: runrats(''init'');');
end

%Make the action case insensitive
action = lower(action);

switch action

    case 'physinit'
        %% physinit
        SoloParamHandle(obj,'phys','value',1);
        runrats(obj,'init');

    case 'init'
        %% init
        display('test');
        %If we are starting from a forced reboot from runrats itself we
        %need to make sure the do_on_reboot.bat file is set back to nothing
        try %#ok<TRYNC>
            p = pwd;
            cd('\ratter\Rigscripts')

            !del do_on_reboot.bat
            !copy nothing.bat do_on_reboot.bat /Y
            cd(p);
        end

        %If a dispatcher is already open, let's close it so we don't ever have
        %more than 1
        if exist('myfig', 'var')
            if isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)), delete(value(myfig)); end;
        end

        %Let's see if the rig is broken
        isbroken = bdata(['select isbroken from rig_maintenance where rigid="',num2str(bSettings('get','RIGS','Rig_ID')),'" and isbroken=1']);
        if isempty(isbroken); isbroken = 0;
        else                  isbroken = 1;
        end
        SoloParamHandle(obj,'IsBroken','value',isbroken); %

        %Let's see how long it's been since the last calibration
        SoloParamHandle(obj,'CalibAge','value',Inf); %Age of the calibration in days
        SoloParamHandle(obj,'CalibExp','value',100);
        %         runrats(obj,'check_calibration'); %we use bpod now, ignore.

        %If the calibration is too old, let's open WaterCalibration for the
        %tech, if we are getting near needing a new calibration let's warn them
        %If the rig is broken ignore calibration

        techmessage = '';
        %         if dispatcher('is_running'); dispatcher('close'); end
        %         if bSettings('get','WATER','skip_calibration_now') ~= 1 && isbroken == 0
        %             if value(CalibAge) >= value(CalibExp) %#ok<NODEF>
        %                 dispatcher('init'); set(double(gcf),'visible','off');
        %                 dispatcher('set_protocol','WaterCalibration');
        %                 return;
        %             elseif value(CalibAge) >= value(CalibExp)-1
        %                 techmessage = 'WARNING Calibration will expire in 1 day!';
        %             elseif value(CalibAge) >= value(CalibExp)-2
        %                 techmessage = 'Calibration will expire in 2 days,';
        %             elseif value(CalibAge) >= value(CalibExp)-3
        %                 techmessage = 'Calibration will expire in 3 days,';
        %             end
        %         end
        %
        % Start and hide the dispatcher.

        dispobj=dispatcher('init');
        h=get_sphandle('owner','dispatcher','name','myfig');
        set(value(h{1}), 'Visible','Off');
        SoloParamHandle(obj, 'dispobj','value',dispobj);

        %SoloParamHandle storing the settings file
        SoloParamHandle(obj, 'settings_file_sph',       'value', '');
        SoloParamHandle(obj, 'settings_file_load_time', 'value', 0 );


        % The main RunRats window should appear in the center of the screen
        sr = get(0,'MonitorPositions');
        wh = [650 250];
        pos = [(sr(3)-wh(1))/2,(sr(4)-wh(2))/2,wh(1),wh(2)];

        fig = figure('Position',pos,'MenuBar','none','ToolBar','none', ...
            'NumberTitle','off','Name','RunRats V2.2 ','Resize','off',...
            'closerequestfcn', [mfilename '(''close'')']);
        SoloParamHandle(obj,'myfig', 'value',fig);
        
        try
            set(myfig, 'WindowStyle', 'modal');
            pause(0.1);
            
        catch %#ok<CTCH>
        
            disp('WARNING: Failed to keep runrats on top');
        end

     
        %Create the non-gui variables we will need
        SoloParamHandle(obj,'RigID',           'value',bSettings('get','RIGS','Rig_ID')); %The rig ID
        SoloParamHandle(obj,'RatSch',          'value',cell(10,1)); %The rats that run in this rig in session order
        SoloParamHandle(obj,'CurrSession',     'value',1); %The session that we should prep to load
        SoloParamHandle(obj,'CurrProtocol',    'value',1); %The protocol that the rat runs under
        SoloParamHandle(obj,'WasFlushed',      'value',0); %Was the rig flused today
        SoloParamHandle(obj,'InLiveLoop',      'value',0); %Let's us know if we should break out of the loop
        SoloParamHandle(obj,'CurrRat',         'value',''); %The name of the current rat
        SoloParamHandle(obj,'PanelBack',       'value',[]); %handles to all the uicontrols that share the background color
        SoloParamHandle(obj,'RigIsBroken',     'value',0); %1 if the rig is broken, 0 if it's not
        SoloParamHandle(obj,'DoingMaintenance','value',0); %1 if we are entering a maintenance note
        SoloParamHandle(obj,'do_full_restart', 'value',1); %1 if we want to restart matlab between each session
        SoloParamHandle(obj,'SafetyMode',      'value',''); %empty for no safety, B for before, A for after
        SoloParamHandle(obj,'OptoPlugColor',   'value',[]); %figure handle for opto plug color panel
        SoloParamHandle(obj,'Rerun_AfterCrash',   'value',1); % should load the previous protocol if runrats/dispatcher crashed

        if ~exist('phys','var'); SoloParamHandle(obj,'phys','value',0); end


        SoloParamHandle(obj, 'curProtocol', 'value', '');  %Current Protocol
        SoloParamHandle(obj,'schedDay','value',[]);

        % For Live Webcam Feed
        % SoloParamHandle(obj,'Camera_Fig_window','value',[]);
        % SoloParamHandle(obj,'Camera_Obj','value',[]);
        % SoloParamHandle(obj,'Camera_Image','value',[]);

        %Let's make the menus
        try
            all_experimenters = bdata('select distinct experimenter from rats where extant=1 order by experimenter');
        catch %#ok<CTCH>
            disp('ERROR: Unable to connect to MySQL Server');
            all_experimenters = '';
        end
        all_experimenters = [{''};all_experimenters];

        MenuParam(obj,'ExpMenu',all_experimenters,1,0,0,'position',[10 204 200 35],'labelfraction',0.01);
        MenuParam(obj,'RatMenu',{''},             1,0,0,'position',[10 162 200 35],'labelfraction',0.01);
        MenuParam(obj,'SchList',{'Not Active'},   1,0,0,'position',[10 120 200 35],'labelfraction',0.01);

        SubheaderParam(obj,'ExpLbl','Experimenter',0,0,'position',[215 204 170 35]);
        SubheaderParam(obj,'RatLbl','Rat',         0,0,'position',[215 162 170 35]);
        SubheaderParam(obj,'SchLbl','Schedule',    0,0,'position',[215 120 170 35]);

        set(get_ghandle(ExpMenu),'FontSize',20,'BackgroundColor',[1 1 1]); %#ok<NODEF>
        set(get_ghandle(RatMenu),'FontSize',20,'BackgroundColor',[1 1 1]); %#ok<NODEF>
        set(get_ghandle(SchList),'FontSize',16,'BackgroundColor',[1 1 1],'FontName','Courier','FontWeight','bold'); %#ok<NODEF>

        set(get_ghandle(ExpLbl),'FontSize',20,'BackgroundColor',[1,0.8,0.6],'HorizontalAlignment','left');
        set(get_ghandle(RatLbl),'FontSize',20,'BackgroundColor',[1,0.8,0.6],'HorizontalAlignment','left');
        set(get_ghandle(SchLbl),'FontSize',20,'BackgroundColor',[1,0.8,0.6],'HorizontalAlignment','left');

        set_callback(ExpMenu,{mfilename,'expmenu_callback'});
        set_callback(RatMenu,{mfilename,'ratmenu_callback'});
        set_callback(SchList,{mfilename,'schlist_callback'});


        %Let's make the buttons
        PushbuttonParam(obj,'FlushValves',0,0,'position',[ 10,50,140, 25],'BackgroundColor',[0.6 1   1  ],'label','Flush Valves');
        PushbuttonParam(obj,'TestImplant',0,0,'position',[155,50,140, 25],'BackgroundColor',[1   0.6 1  ],'label','Test Implant');
        PushbuttonParam(obj,'UpdateMode' ,0,0,'position',[300,50,170, 25],'BackgroundColor',[0.6 1   0.6],'label','Live Update On');
        PushbuttonParam(obj,'Maintenance',0,0,'position',[475,50,165, 25],'BackgroundColor',[1   0.3 0.1],'label','Maintenance');
        PushbuttonParam(obj,'Multi',      0,0,'position',[400,85,240,155],'BackgroundColor',[1   1   0.4],'label','Load Protocol');

        set(get_ghandle(FlushValves),'Fontsize',16);
        set(get_ghandle(TestImplant),'Fontsize',16);
        set(get_ghandle(UpdateMode), 'Fontsize',16);
        set(get_ghandle(Maintenance),'Fontsize',16);
        set(get_ghandle(Multi),      'Fontsize',24);

        set_callback(FlushValves,{mfilename,'flush_valves'});
        set_callback(TestImplant,{mfilename,'test_implant'});
        set_callback(UpdateMode, {mfilename,'updatemode_button'});
        set_callback(Maintenance,{mfilename,'rig_maintenance'});
        set_callback(Multi,      {mfilename,'multi_button'});

        %Hide the Test Implant button if this rig isn't set up to do this
        alldio=bSettings('get','DIOLINES','ALL');
        if isempty(alldio) || (sum(strcmp(alldio(:,1),'stim1'))  == 0 && sum(strcmp(alldio(:,1),'LASER')) == 0) &&...
                (sum(strcmp(alldio(:,1),'BLUE'))   == 0 && sum(strcmp(alldio(:,1),'GREEN')) == 0) &&...
                (sum(strcmp(alldio(:,1),'YELLOW')) == 0 && sum(strcmp(alldio(:,1),'RED'))   == 0)
            set(get_ghandle(TestImplant),'visible','off');
        end


        %Let's make the display areas
        DispParam(obj,'Instructions','',         0,0,'position',[10,80,380,40],'label','','labelfraction',0.005);
        DispParam(obj,'StatusBar',   techmessage,0,0,'position',[ 1, 1,650,50],'label','','labelfraction',0.003);

        %This is intended to be a copy of the instructions field which will
        %require the tech to click on if the experimenter wants it
        PushbuttonParam(obj,'Safety',            0,0,'position',[10,80,380,40],'label','');
        set_callback(Safety,{mfilename,'safety_button'});

        set(get_ghandle(Instructions),'Fontsize',14,'BackgroundColor',[1,0.8,0.6],'HorizontalAlignment','left','FontWeight','bold'); %#ok<NODEF>
        set(get_ghandle(StatusBar),   'Fontsize',14,'BackgroundColor',[0.9,0.9,1],'HorizontalAlignment','center'); %#ok<NODEF>
        set(get_ghandle(Safety),      'Fontsize',14,'BackgroundColor',[1,0.8,0.6],'HorizontalAlignment','left','FontWeight','bold','visible','off');


        c = get(double(gcf),'children');
        set(c(end),'backgroundcolor',[1,0.8,0.6]);
        PanelBack.value = [c(end),get_ghandle(ExpLbl),get_ghandle(RatLbl),get_ghandle(SchLbl),get_ghandle(Instructions)];


        %Time to make the rig maintenance screen
        confirmnote = {'If you repaired the rig, enter','your name and click FIXED.'};
        schedulenote = 'Run these rats in different rigs';
        try %#ok<TRYNC>
            labmembers = bdata('select experimenter from contacts where is_alumni=0');
            labmembers = unique(strtrim(labmembers));
            labmembers(2:end+1) = labmembers;
        end
        labmembers{1} = 'Select Name';

        DispParam(obj,'MaintenanceTitle','Rig is Broken',0,0,'position',[220,190,430, 60],'label','','labelfraction',0.01);
        DispParam(obj,'ScheduleNote',schedulenote,       0,0,'position',[  1,220,220, 30],'label','','labelfraction',0.01);
        DispParam(obj,'Schedule','',                     0,0,'position',[  1, 40,220,180],'label','','labelfraction',0.01);
        DispParam(obj,'RigTechNote','',                  0,0,'position',[220, 40,430,150],'label','','labelfraction',0.01);
        DispParam(obj,'ConfirmNote',confirmnote,         0,0,'position',[  1,  1,220, 40],'label','','labelfraction',0.01);
        MenuParam(obj,'LabMembersMenu',labmembers,     1,0,0,'position',[220,  1,283, 40],'labelfraction',0.01);
        PushbuttonParam(obj,'Fixed',                     0,0,'position',[500,  1,150, 40],'label','Fixed');

        set(get_ghandle(MaintenanceTitle),'Fontsize',32,'visible','off','BackgroundColor',[1,0,0],      'HorizontalAlignment','center');
        set(get_ghandle(ScheduleNote),    'Fontsize',12,'visible','off','BackgroundColor',[1,0.7,0.7],  'HorizontalAlignment','center');
        set(get_ghandle(Schedule),        'Fontsize',12,'visible','off','BackgroundColor',[1,0.7,0.7],  'HorizontalAlignment','left');
        set(get_ghandle(RigTechNote),     'Fontsize',12,'visible','off','BackgroundColor',[1,1,1],      'HorizontalAlignment','center');
        set(get_ghandle(ConfirmNote),     'Fontsize',12,'visible','off','BackgroundColor',[0.9,0.9,0.9],'HorizontalAlignment','center');
        set(get_ghandle(LabMembersMenu),  'Fontsize',24,'visible','off','BackgroundColor',[1,1,1]); %#ok<NODEF>
        set(get_ghandle(Fixed),           'Fontsize',24,'visible','off','BackgroundColor',[0,1,0],'enable','off');

        set_callback(LabMembersMenu,{mfilename,'select_labmember'});
        set_callback(Fixed,         {mfilename,'flag_rig_fixed'});

        %Let's make a fix comments screen
        EditParam(obj,      'RepairNote','',0,0,'position',[  1, 40,650,150],'label','','HorizontalAlignment','left','labelfraction',0.003);
        PushbuttonParam(obj,'Submit',       0,0,'position',[  1,  1,650, 40],'label','Submit');

        set(get_ghandle(RepairNote),'Fontsize',16,'visible','off','BackgroundColor',[1,1,1],'max',2);
        set(get_ghandle(Submit),    'Fontsize',24,'visible','off','BackgroundColor',[0,1,0],'enable','off');

        set_callback(RepairNote,{mfilename,'enter_repairnote'});
        set_callback(Submit,    {mfilename,'submit_rig_fixed'});


        %Let's clean up the unused labels
        temp = get_glhandle(Instructions);   set(temp(2),'visible','off');
        temp = get_glhandle(StatusBar);      set(temp(2),'visible','off');
        temp = get_glhandle(ConfirmNote);    set(temp(2),'visible','off');
        temp = get_glhandle(ScheduleNote);   set(temp(2),'visible','off');
        temp = get_glhandle(Schedule);       set(temp(2),'visible','off');
        temp = get_glhandle(LabMembersMenu); set(temp(2),'visible','off');

        %Last thing we need to make is a timer, boooooo, I don't like them
        scr = timer;
        set(scr,'Period', 0.2,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
            'BusyMode','drop','TimerFcn',[mfilename,'(''End_Continued'')']);
        SoloParamHandle(obj, 'stopping_complete_timer', 'value', scr);

        % Update the rig info table
        update_riginfo();
        runrats(obj,'updatelog','startup');

        %We are done building the GUI, let's update the session menu, figure
        %out what session we are in and load up that rat

        runrats(obj,'update_schedule');
        runrats(obj,'estimate_current_session');

        %Now that we know the schedule for this rig and what session we should
        %prepare to load, let's do it.
        runrats(obj,'update_exprat');
        runrats(obj,'check_rig_flushed');
        % runrats(obj,'live_loop');


    case 'send_empty_state_machine'
        %% send_empty_state_machine
        display('reached sesm');

        state_machine_server = bSettings('get','RIGS','state_machine_server');

        server_slot = bSettings('get','RIGS','server_slot');
        if isnan(server_slot); server_slot = 0; end

        card_slot = bSettings('get', 'RIGS', 'card_slot');
        if isnan(card_slot); card_slot = 0; end

        sm = BpodSM(state_machine_server, 3333,server_slot);
        sm = Initialize(sm);

        [inL,outL] = MachinesSection(dispatcher,'determine_io_maps');

        sma = StateMachineAssembler('full_trial_structure');
        sma = add_state(sma,'name','vapid_state_in_vapid_matrix');

        send(sma,sm,'run_trial_asap',0,'input_lines',inL,'dout_lines',outL,'sound_card_slot', int2str(card_slot));


    case 'check_calibration'
        %% check_calibration

        lastcalib = check_calibration;
        if ~isnan(lastcalib); calibage = now - datenum(lastcalib,'yyyy-mm-dd HH:MM:SS');
        else                  calibage = Inf;
        end

        CalibAge.value = calibage;
        days = floor(value(CalibExp) - calibage);
        hours = floor((value(CalibExp) - days - calibage) * 24);

        if exist('StatusBar','var') && calibage > value(CalibExp) && bSettings('get','WATER','skip_calibration_now') ~= 1
            %If calibration has expired close runrats and open calibration protocol
            dispatcher('set_protocol','WaterCalibration');
            runrats(obj,'close_gui_only');
            return;

        elseif exist('StatusBar','var') && (calibage > value(CalibExp)- 6) && bSettings('get','WATER','skip_calibration_now') ~= 1
            %Calibration is not expired but old, so let's warn the tech it
            %will expire soon

            techmessage = value(StatusBar); %#ok<NODEF>
            tempF = strfind(techmessage,'flush');

            %Only update message if it's not already telling the tech to
            %flush the valves
            if isempty(tempF)
                tempC = strfind(techmessage,'Calibration will expire in');

                if ~isempty(tempC); techmessage(min(tempC):end) = ''; end

                lastchar = find(techmessage ~= ' ',1,'last');
                if ~isempty(lastchar) && lastchar < numel(techmessage)
                    techmessage(lastchar + 1:end) = '';
                end

                techmessage = [techmessage,'    Calibration will expire in ',...
                    num2str(days),' days ',num2str(hours),' hours'];

                StatusBar.value = techmessage;
            end
        end



    case 'live_loop'
        %% live_loop
        %Here we loop, updated the schedule and menus accordingly.

        %We do this so the DIO lines work
        display('reached live loop');
        runrats(obj,'send_empty_state_machine');

        InLiveLoop.value = 1;
        strt = now;
        donefirst = 0;
        while value(InLiveLoop) == 1
            %We only want to update every 30 seconds so we don't clog the
            %network but we want the loop to go fast to be responsive.
            if ((now - strt) * 24 * 60) > 0.5 || donefirst == 0
                disp(['RunRats Live Update at ',datestr(now,'HH:MM:SS')]);
                runrats(obj,'update_schedule');
                runrats(obj,'estimate_current_session');
                runrats(obj,'update_exprat');
                runrats(obj,'check_rig_flushed');
                runrats(obj,'check_rig_broken');


                if strcmp(get(get_ghandle(MaintenanceTitle),'string'),'Please wait while RunRats updates...')
                    set(get_ghandle(MaintenanceTitle),'string','Rig is Broken','BackgroundColor',[1 0 0]);
                    %                 elseif value(IsBroken) == 0
                    %Only check for calibration if the rig is not broken
                    %                     runrats(obj,'check_calibration');
                end

                strt = now;
                donefirst = 1;
            end
            pause(rand(1));
        end
        if runrats('is_running')
            %disp(get(get_ghandle(Multi),'string'));
            if isempty(strfind(get(get_ghandle(Multi),'string'),'Run')) &&...
                    isempty(strfind(get(get_ghandle(Multi),'string'),'Unloading Test'))
                runrats(obj,'updatemode_button',0);
            end
        end


    case 'updatemode_button'
        %% updatemode_button
        %The user has clicked the updatemode button, this will either take
        %us in or out of the live loop, we also need to change colors

        if     nargin > 2;                                                     forceto = varargin{1};
        elseif strcmp(get(get_ghandle(UpdateMode),'string'),'Live Update On'); forceto = 0;
        else                                                                   forceto = 1;
        end

        if forceto == 0
            set(get_ghandle(UpdateMode),'String','Update Paused','BackgroundColor',[1 0 0],'ForegroundColor',[0 0 0]);
            h = value(PanelBack); %#ok<NODEF>
            for i = 1:length(h);
                set(h(i),'BackgroundColor',[1,0.2,0.2]);
            end
            set(get_ghandle(Safety),'BackgroundColor',[1,0.2,0.2]);
            InLiveLoop.value = 0;
        else
            h = value(PanelBack); %#ok<NODEF>
            for i = 1:length(h);
                set(h(i),'BackgroundColor',[1,0.8,0.6]);
            end
            set(get_ghandle(Safety),'BackgroundColor',[1,0.8,0.6]);
            set(get_ghandle(UpdateMode),'String','Live Update On','BackgroundColor',[0.6 1 0.6],'ForegroundColor',[0 0 0]);
            runrats(obj,'live_loop');
        end


    case 'expmenu_callback'
        %% expmenu_callback
        %The user has selected a different experimenter from the menu

        InLiveLoop.value = 0;
        runrats(obj,'update_ratmenu');


    case 'ratmenu_callback'
        %% ratmenu_callback
        %The user has selected a different rat from the menu

        InLiveLoop.value = 0;
        runrats(obj,'update_rat',1);


    case 'schlist_callback'
        %% schlist_callback
        %The user has selected a different session from the schedule

        InLiveLoop.value = 0;
        runrats(obj,'update_exprat');


    case 'check_rig_flushed'
        %% check_rig_flushed
        %Check if the rig has been flushed today
        %
        %         if ~isnan(value(RigID))
        %             wf = bdata(['select wasflushed from rigflush where rig=',...
        %                 num2str(value(RigID)),' and dateval="',datestr(now,'yyyy-mm-dd'),'"']);
        %             if isempty(wf) || wf == 0
        %                 %The rig has not been flushed
        %                 StatusBar.value = 'Please flush the rig before loading the first rat today.';
        %                 set(get_ghandle(Multi),'enable','off');
        %                 wf = 0;
        %             end
        %         else
        %             wf = nan;
        %         end
        %         WasFlushed.value = wf;

        %As of 2015-09-02 I am turning this feature off.  Possibly leading to
        %rats losing motivation in session 1 if they can drink it. -Chuck

        WasFlushed.value = 1;


    case 'check_rig_broken'
        %% check_rig_broken
        %Here we determine if the rig has been flagged as broken.  If it is
        %we bring up the maintenance screen, if not we keep it as normal,
        %however, if we are entering a maintenance note we should skip this

        if value(DoingMaintenance) == 0 && ~isnan(value(RigID)) %#ok<NODEF>
            [note,isbroken,tech,notedate] = bdata('select note, isbroken, broke_person, broke_date from rig_maintenance where rigid="{S}"',value(RigID));

            fullnote = '';
            if ~isempty(note)
                recent_break = find(isbroken == 1,1,'last');
                if ~isempty(recent_break)
                    note     = note{recent_break};
                    isbroken = isbroken(recent_break);
                    tech     = tech{recent_break};
                    notedate = notedate{recent_break};
                    try %#ok<TRYNC>
                        fullnote = {['Note entered by ',tech,' on ',notedate],char(note)'};
                    end
                else
                    isbroken = 0;
                end

                set(get_ghandle(Fixed),'enable','off');

                if isbroken == 1; s = {'on','off'};
                else              s = {'off','on'};
                end
            else                  s = {'off','on'};
            end

            set(get_ghandle(MaintenanceTitle),'visible',s{1});
            set(get_ghandle(RigTechNote),     'visible',s{1},'string',fullnote);
            set(get_ghandle(ConfirmNote),     'visible',s{1});
            set(get_ghandle(LabMembersMenu),  'visible',s{1}); %#ok<NODEF>
            set(get_ghandle(Fixed),           'visible',s{1});
            set(get_ghandle(ScheduleNote),    'visible',s{1});
            set(get_ghandle(Schedule),        'visible',s{1});

            set(get_ghandle(Instructions),    'visible',s{2}); %#ok<NODEF>
            set(get_ghandle(StatusBar),       'visible',s{2}); %#ok<NODEF>
            set(get_ghandle(FlushValves),     'visible',s{2});
            set(get_ghandle(TestImplant),     'visible',s{2});
            set(get_ghandle(UpdateMode),      'visible',s{2});
            set(get_ghandle(Maintenance),     'visible',s{2});
            set(get_ghandle(Multi),           'visible',s{2});
            set(get_ghandle(ExpMenu),         'visible',s{2}); %#ok<NODEF>
            set(get_ghandle(RatMenu),         'visible',s{2}); %#ok<NODEF>
            set(get_ghandle(SchList),         'visible',s{2}); %#ok<NODEF>
            set(get_ghandle(ExpLbl),          'visible',s{2});
            set(get_ghandle(RatLbl),          'visible',s{2});
            set(get_ghandle(SchLbl),          'visible',s{2});


            %Hide the Test Implant button if this rig isn't set up to do this
            alldio=bSettings('get','DIOLINES','ALL');
            if isempty(alldio) || (sum(strcmp(alldio(:,1),'stim1')) == 0 && sum(strcmp(alldio(:,1),'LASER')) == 0)
                set(get_ghandle(TestImplant),'visible','off');
            end

            IsBroken.value = isbroken;
        end

    case 'select_labmember'
        %% select_labmember
        %If the user has selected their name we enable the fixed button

        if strcmp(value(LabMembersMenu),'Select Name') == 0 %#ok<NODEF>
            set(get_ghandle(Fixed),'enable','on');
        else
            set(get_ghandle(Fixed),'enable','off');
        end

        if ~strcmp(value(RepairNote),'') && ~strcmp(value(LabMembersMenu),'Select Name')
            set(get_ghandle(Submit),'enable','on');
        end


    case 'enter_repairnote'
        %% enter_repairnote
        %If the user has entered a note we can enable the Submit button

        if strcmp(value(RepairNote),'') || strcmp(value(LabMembersMenu),'Select Name') %#ok<NODEF>
            set(get_ghandle(Submit),'enable','off');
        else
            set(get_ghandle(Submit),'enable','on');
        end



    case 'flag_rig_fixed'
        %% flag_rig_fixed
        %The user has confirmed that the rig is fixed. Now we make them
        %enter comments about how they fixed it before going back to
        %runrats normal mode

        set(get_ghandle(MaintenanceTitle),'string','Enter how you fixed the rig, then click SUBMIT',...
            'BackgroundColor',[0.7,1,0.7],'FontSize',20);
        set(get_ghandle(RepairNote),'visible','on','string','');
        set(get_ghandle(Submit),    'visible','on','enable','off');



    case 'submit_rig_fixed'
        %% submit_rig_fixed
        %The user has entered comments.  Update the MySQL table and return
        %runrats to normal operation

        [id isbroken] = bdata(['select maintenance_id, isbroken from rig_maintenance where rigid=',num2str(value(RigID))]);
        if ~isempty(id) && sum(isbroken) ~= 0
            %The rig was broken, let's add info to that MySQL entry
            temp = find(isbroken == 1,1,'last');
            id = id(temp);
            bdata('call mark_rigfixed("{S}","{S}","{S}","{S}")',id,value(LabMembersMenu),...
                datestr(now,'yyyy-mm-dd HH:MM'),value(RepairNote)); %#ok<NODEF>
            InLiveLoop.value = 1;
        else
            %We just did maintenance, make a new MySQL entry
            bdata(['insert into rig_maintenance set fix_person="',value(LabMembersMenu),...
                '", fix_note="',value(RepairNote),'", fix_date="',datestr(now,'yyyy-mm-dd HH:MM'),...
                '", rigid=',num2str(value(RigID))]); %#ok<NODEF>
        end

        set(get_ghandle(LabMembersMenu),'position',[220,  1,283, 40]);
        set(get_ghandle(Submit),        'position',[  1,  1,650, 40]);

        set(get_ghandle(RepairNote),    'visible','off','string','');
        set(get_ghandle(Submit),        'visible','off');
        set(get_ghandle(LabMembersMenu),'visible','off');

        set(get_ghandle(MaintenanceTitle),'string','Please wait while RunRats updates...',...
            'BackgroundColor',[0.7 0.7 0.7],'FontSize',20);

        DoingMaintenance.value = 0;
        LabMembersMenu.value   = 1;

        runrats(obj,'check_rig_broken');



    case 'update_rat'
        %% udpate_rat
        %Here we take the selected rat and checkout their settings if
        %necessary, update their settings, and update the tech instructions

        if isempty(value(RatMenu)) || isempty(value(ExpMenu));  %#ok<NODEF>
            return;
        end

        runrats(obj,'disable_all');
        set(get_ghandle(Multi),'string',['Updating ',value(RatMenu)],...
            'Backgroundcolor',[0.8 0.8 0.8],'fontsize',24);
        pause(0.1);

        dirCurrent  = cd;
        [dirData errtmp] = bSettings('get','GENERAL','Main_Data_Directory');
        if errtmp || ~ischar(dirData) || isempty(dirData);
            return;
        end

        if ~exist(dirData,'dir')
            %We need to check out SoloData
        end
        cd(dirData);

        dirSettings = [dirData    ,filesep,'Settings'];
        dirExp      = [dirSettings,filesep,value(ExpMenu)];
        dirRat      = [dirExp     ,filesep,value(RatMenu)];

        if ~exist(dirSettings,'dir')
            mkdir('Settings');
            system('svn add Settings');
        end
        cd(dirSettings);

        if ~exist(dirExp,'dir')
            mkdir(value(ExpMenu));
            system(['svn add ' value(ExpMenu)]);
        end
        cd(dirExp);

        if ~exist(dirRat,'dir');
            mkdir(value(RatMenu));
            system(['svn add ' value(RatMenu)]);
        end;
        cd(dirRat);

        % update_folder(pwd,'svn');

        cd(dirCurrent);
        runrats(obj,'enable_all');
        set(get_ghandle(Multi),'string','Load Protocol','BackgroundColor',[1,1,0.4],'FontSize',24);

        if strcmp(value(CurrRat),value(RatMenu)) %#ok<NODEF>
            if nargin < 3 || varargin{1} == 1
                InLiveLoop.value = 1;
            end
        else
            CurrRat.value = value(RatMenu);

            %Let's see if this is a new rat, if so, warn the tech
            ratM = bdata(['select mass from mass_log where animal_id="',value(RatMenu),'"']);
            if length(ratM) < 14
                StatusBar.value = 'WARNING: New Rat!';
                set(get_ghandle(StatusBar),'fontweight','bold');
            else
                StatusBar.value = ['Ready to load ',value(RatMenu)];
                set(get_ghandle(StatusBar),'fontweight','normal');
            end
        end

        runrats(obj,'update_tech_instructions');
        runrats(obj,'check_rig_flushed');


    case 'update_exprat'
        %% update_exprat
        %Here we update the Experimenter and Rat Menus to reflect the
        %selected entry in the Schedule List

        CurrSession.value = get(get_ghandle(SchList),'value'); %#ok<NODEF>
        currrat = value(RatMenu); %#ok<NODEF>

        ratsch = value(RatSch); %#ok<NODEF>
        if ~isnan(value(CurrSession))
            if value(CurrSession) <= 9
                SchList.value = value(CurrSession);
                StatusBar.value = ['Ready to load session ',num2str(value(CurrSession))];
            else
                SchList.value = 10;
                StatusBar.value = 'All training session are done for today.';
            end
            activerat = ratsch{value(CurrSession)};
        else
            activerat = '';
        end

        %Find the rat's experimenter, and set the experimenter and rat menus accordingly
        if ~isempty(activerat)
            exp = bdata(['select experimenter from rats where ratname="',activerat,'"']);
            ExpMenu.value = exp{1};
        else
            ExpMenu.value = '';
        end

        runrats(obj,'update_ratmenu',activerat);
        runrats(obj,'update_tech_instructions');

        %If the rat has changed, let's update it.
        if ~strcmp(value(RatMenu),currrat)
            runrats(obj,'update_rat',value(InLiveLoop)); %#ok<NODEF>
        else
            %Stay in the loop if we haven't changed anything
            InLiveLoop.value = 1;
        end

        %runrats(obj,'updatelog','update_exprat');

%% SPECIAL CASE ADDED BY ARPIT FOR CLICK AND SELECT 
% doesn't effect the running of the other cases/functions
    case 'update exp_rat_userclick'
        
        ExpMenu.value = varargin{1};
        runrats(obj,'update_ratmenu',varargin{2});
        %If the rat has changed, let's update it.
        if ~strcmp(value(RatMenu),varargin{2})
            runrats(obj,'update_rat',value(InLiveLoop)); %#ok<NODEF>
        else
            %Stay in the loop if we haven't changed anything
            InLiveLoop.value = 1;
        end
        
        runrats(obj,'begin_load_protocol');

        % Added to send the details about the experimenter and rat
    case 'exp_rat_names'
        varargout{1} = value(ExpMenu);
        varargout{2} = value(RatMenu);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'update_tech_instructions'
        %% update_tech_instructions
        %Posts the tech instructions for the active rat on the screen

        if ~isempty(value(OptoPlugColor)) %#ok<NODEF>
            try delete(value(OptoPlugColor)); end %#ok<TRYNC>
        end

        if ~strcmp(value(RatMenu),'') %#ok<NODEF>
            [ti,sess] = bdata(['select instructions, timeslot from scheduler where ratname="',value(RatMenu),...
                '" and date="',datestr(now,'yyyy-mm-dd'),'"']);
            if iscell(ti) && numel(ti) > 1 % More than one session is scheduled for this rat.  Grab the appropriate tech instruction
                runrats(obj,'estimate_current_session');
                if isempty(value(CurrSession))
                    ti = ti{1};
                elseif sum(sess==value(CurrSession)) == 1
                    ti = ti{sess==value(CurrSession)};
                else
                    ti = '';
                end
            elseif iscell(ti) && ~isempty(ti); ti = ti{1};
            else                           ti = '';
            end
            try
                if sum(ti=='#') >= 2 && rem(sum(ti=='#'),2)==0
                    %This may be a day specific message. Let's try to parse it

                    if     strcmp(datestr(now,'ddd'),'Mon'); dayltr = 'm';
                    elseif strcmp(datestr(now,'ddd'),'Tue'); dayltr = 't';
                    elseif strcmp(datestr(now,'ddd'),'Wed'); dayltr = 'w';
                    elseif strcmp(datestr(now,'ddd'),'Thu'); dayltr = 'r';
                    elseif strcmp(datestr(now,'ddd'),'Fri'); dayltr = 'f';
                    elseif strcmp(datestr(now,'ddd'),'Sat'); dayltr = 's';
                    else   strcmp(datestr(now,'ddd'),'Sun'); dayltr = 'u';
                    end

                    p = find(ti == '#');

                    TI = ti(1:p(1)-1);

                    for i = 1:2:numel(p)-1
                        d = ti(p(i)+1:p(i+1)-1);
                        if ~isempty(strfind(lower(d),dayltr))
                            %This portion of the instructions should be
                            %displayed today
                            msg = '';
                            if i+1==numel(p)
                                if numel(ti)>p(end); msg = ti(p(end)+1:end); end
                            else
                                msg = ti(p(i+1)+1:p(i+2)-1);
                            end

                            TI = [TI,' ',msg]; %#ok<AGROW>
                        end
                    end

                    fstltr = find(TI ~= ' ',1,'first');
                    if fstltr > 1; TI(1:fstltr-1) = ''; end
                    ti = TI;

                end
            catch %#ok<CTCH>
                disp('Error while parsing tech instructions. Displaying everything.')
            end

            %Now let's check the instructions for the safety code
            d = find(ti == '$');
            s = '';
            if numel(d) > 1
                for i = 1:2:numel(d) - 1
                    temp = ti(d(i)+1:d(i+1)-1);
                    s(end+1:end+numel(temp)) = temp;
                end
            end
            if     ~isempty(strfind(s,'A')) && ~isempty(strfind(s,'B')) >  0; SafetyMode.value = 'AB';
            elseif ~isempty(strfind(s,'A')) &&  isempty(strfind(s,'B')) == 0; SafetyMode.value = 'A';
            elseif  isempty(strfind(s,'A')) && ~isempty(strfind(s,'B')) >  0; SafetyMode.value = 'B';
            else                                                              SafetyMode.value = '';
            end

            bad = [];
            if numel(d) > 1
                for i = 1:2:numel(d) - 1
                    bad(end+1:end+numel(d(i):d(i+1))) = d(i):d(i+1);
                end
            end
            ti(bad) = [];

            Instructions.value = ti;
            try  %#ok<TRYNC>
                OptoPlugColor.value = parse_optonote(ti);
            end
        else
            Instructions.value = '';
            SafetyMode.value = '';
        end



    case 'disable_all'
        %% disable_all
        %Disable all the buttons.

        set(get_ghandle(ExpMenu),    'enable','off'); %#ok<NODEF>
        set(get_ghandle(RatMenu),    'enable','off'); %#ok<NODEF>
        set(get_ghandle(SchList),    'enable','off'); %#ok<NODEF>
        set(get_ghandle(FlushValves),'enable','off');
        set(get_ghandle(TestImplant),'enable','off');
        set(get_ghandle(UpdateMode), 'enable','off');
        set(get_ghandle(Maintenance),'enable','off');
        set(get_ghandle(Multi),      'enable','off');



    case 'enable_all'
        %% enable_all
        %Enable all the buttons.

        set(get_ghandle(ExpMenu),    'enable','on'); %#ok<NODEF>
        set(get_ghandle(RatMenu),    'enable','on'); %#ok<NODEF>
        set(get_ghandle(SchList),    'enable','on'); %#ok<NODEF>
        set(get_ghandle(FlushValves),'enable','on');
        set(get_ghandle(TestImplant),'enable','on');
        set(get_ghandle(UpdateMode), 'enable','on');
        set(get_ghandle(Maintenance),'enable','on');
        set(get_ghandle(Multi),      'enable','on');



    case 'flush_valves'
        %% flush_valves
        %This will open each water valve sequentially for 10 seconds

        runrats(obj,'disable_all');
        oldval=value(StatusBar); %#ok<NODEF>
        StatusBar.value='Flushing Each Valve for 10 seconds';

        %Let's find all the water valves
        alldio=bSettings('get','DIOLINES','ALL');
        diolist=[];
        skip_center = bSettings('get','WATER','skip_center_flush');
        if isnan(skip_center) || isempty(skip_center); skip_center = 0; end

        for di=1:size(alldio,1)
            if ~isempty(strfind(alldio{di,1},'water')) && ~isnan(alldio{di,2})
                if ~isempty(strfind(alldio{di,1},'center')) && skip_center == 1;
                    continue;
                end
                diolist=[diolist alldio{di,2}]; %#ok<AGROW>
            end
        end
        %Dispatcher needs the log of each DIO line
        diolist = log2(diolist);

        %Cycle through the list opening each for 10 seconds
        for i = 1:length(diolist)
            dispatcher('toggle_bypass',diolist(i));
            pause(10);
            dispatcher('toggle_bypass',diolist(i));
        end

        if strcmp(oldval,'Please flush the rig before loading the first rat today.')
            oldval = '';
        end
        StatusBar.value=oldval;
        runrats(obj,'enable_all');


        %Update MySQL to show this rig has been flushed today
        if ~isnan(value(RigID))
            id = bdata(['select id from rigflush where rig=',...
                num2str(value(RigID)),' and dateval="',datestr(now,'yyyy-mm-dd'),'"']);


            if isempty(id) || ~isnan(id)
                if isempty(id)
                    bdata(['insert into rigflush set rig=',num2str(value(RigID)),...
                        ', wasflushed=1, dateval="',datestr(now,'yyyy-mm-dd'),'"']);
                end
            end
        end
        WasFlushed.value = 1;



    case 'test_implant'
        %% test_implant
        %This will toggle all the stim and laser lines to test a rats
        %implant before running

        %Check to see if the multi button is already disabled
        if strcmp(get(get_ghandle(Multi),'enable'),'off')
            disablemulti = 1;
        else
            disablemulti = 0;
        end

        runrats(obj,'disable_all');
        oldval=value(StatusBar); %#ok<NODEF>
        StatusBar.value='Testing Implant. Please Observe Rat';

        %Let's find all the stim lines
        alldio=bSettings('get','DIOLINES','ALL');
        diolist=[];
        for di=1:size(alldio,1)
            if (~isempty(strfind(alldio{di,1},'LASER'))  ||...
                    ~isempty(strfind(alldio{di,1},'GREEN'))  ||...
                    ~isempty(strfind(alldio{di,1},'BLUE'))   ||...
                    ~isempty(strfind(alldio{di,1},'YELLOW')) ||...
                    ~isempty(strfind(alldio{di,1},'RED')))   &&...
                    ~isnan(alldio{di,2})
                diolist=[diolist alldio{di,2}]; %#ok<AGROW>
            end
        end
        %Dispatcher needs the log of each DIO line
        diolist = log2(diolist);

        %Call dispatcher to toggle the stim lines in succession
        pause(3);
        for i = 1:length(diolist)
            dispatcher('toggle_bypass',diolist(i));
            pause(0.2);
            dispatcher('toggle_bypass',diolist(i));
            pause(0.5);
        end

        StatusBar.value=oldval;
        runrats(obj,'enable_all');
        runrats(obj,'check_rig_flushed');

        if disablemulti == 1
            set(get_ghandle(Multi),'enable','off');
        end

        runrats(obj,'updatelog','testimplant');


    case 'rig_maintenance'
        %% rig_maintenance
        %The user wants to enter some comments about maintenance they
        %performed on the rig.

        set(get_ghandle(StatusBar),'visible','off'); %#ok<NODEF>

        set(get_ghandle(MaintenanceTitle),'visible','on','string','Enter a description of the maintenance performed:','BackgroundColor',[1 0.3 0.1],'Fontsize',20);
        set(get_ghandle(RepairNote),      'visible','on');
        set(get_ghandle(Submit),          'visible','on','position',[325,1,325,40]);
        set(get_ghandle(LabMembersMenu),  'visible','on','position',[  1,1,325,40]); %#ok<NODEF>
        DoingMaintenance.value = 1;



    case 'update_ratmenu'
        %% update_ratmenu
        %Here we get the list of extant rats for the selected experimenter
        %and populate the rat menu with it

        exp = value(ExpMenu); %#ok<NODEF>
        currats = get(get_ghandle(RatMenu),'string'); %#ok<NODEF>

        if strcmp(exp,'')
            ratnames = {''};
        else
            ratnames = bdata(['select ratname from rats where experimenter="',exp,'" and extant=1']);
            ratnames = sortrows(strtrim(ratnames));
        end

        %If we've changed things, update the menus accordingly
        if length(currats) ~= length(ratnames) || ~strcmp(currats{1},ratnames{1}) ||...
                (nargin > 2 && ~strcmp(varargin{1},value(RatMenu)))
            set(get_ghandle(RatMenu),'string',ratnames,'value',1);

            %If we passed in a rat name, set the manu to it
            if nargin > 2; RatMenu.value = varargin{1};
            else           RatMenu.value = ratnames{1};
            end

            runrats(obj,'update_rat');
        else
            %Stay in the loop if we haven't changed anything
            InLiveLoop.value = 1;
        end



    case 'update_schedule'
        %% update_schedule
        
        %Here we grab the current schedule for this rig

        % if ~isnan(value(RigID));
        %     [rats slots] = bdata(['select ratname, timeslot from scheduler where date="',...
        %         datestr(now,'yyyy-mm-dd'),'" and rig=',num2str(value(RigID))]);
        % end

        % Updated by Arpit - instead of taking the date, we will look for
        % if the rats which are in training in scheduler table.
        if ~isnan(value(RigID))
            [rats,slots] = bdata(['select ratname, timeslot from scheduler where in_training="1" and rig=',num2str(value(RigID))]);
        end

        %Let's populate the 5 training sessions (changed by sharbat, with
        %approx times guesse for Akrami lab
        ratsch = cell(6,1); for i=1:6; ratsch{i} = ''; end
        sch    = cell(6,1);


        sch{1}  = ' 8-10am: ';
        sch{2}  = '10-12am: ';
        sch{3}  = '12- 2pm: ';
        sch{4}  = ' 2- 4pm: ';
        sch{5}  = ' 4- 6pm: ';
        sch{6} = '';

        if ~isnan(value(RigID))
            for i = 1:5
                temp = slots==i;
                if sum(temp) == 1
                    ratsch{i} = rats{temp};
                    sch{i} = [sch{i},ratsch{i}];
                end
            end
        end
        set(get_ghandle(Schedule),'string',sch(1:5));
        set(get_ghandle(SchList),'string',sch); %#ok<NODEF>
        RatSch.value = ratsch;


    case 'estimate_current_session'
        %% estimate_current_session
        %Here we will try to estimate which session is currently training

        CS = value(CurrSession);

        [ratSCH, slots] = bdata(['select ratname, timeslot from scheduler where date="',...
            datestr(now,'yyyy-mm-dd'),'"']);
        ratSES = bdata(['select ratname from sessions where sessiondate="',datestr(now,'yyyy-mm-dd'),'"']);
        [ratSS, ST]  = bdata(['select ratname, starttime from sess_started where sessiondate="',...
            datestr(now,'yyyy-mm-dd'),'"']);

        %Let's cycle through each of the 6 training sessions and see if the
        %rats are started, done, or neither
        COMP = zeros(5,1);
        for i = 1:5
            currats = ratSCH(slots == i);
            currats(strcmp(currats,'')) = [];
            comp = zeros(size(currats));
            st   = zeros(size(currats)); st(:) = nan;
            for j = 1:length(currats)
                if     sum(strcmp(ratSES,currats{j})) > 0; comp(j) = 2; %rat finished
                elseif sum(strcmp(ratSS, currats{j})) > 0; comp(j) = 1; %rat running
                    st(j) = datenum(ST{find(strcmp(ratSS, currats{j})==1,1,'first')},'HH:MM:SS');
                end
            end

            if     sum(comp == 2) >= numel(comp)/2; COMP(i) = 2; %session is likely completed
            elseif sum(comp  > 0) >= numel(comp)/2; COMP(i) = 1; %session is likely running
            else                                    COMP(i) = 0; %session not yet started
            end

            %If the session is still running, let's see how long they've been in.
            if COMP(i) == 1
                st = (datenum(datestr(now,'HH:MM:SS')) - nanmean(st)) * 24 * 60;
                if st > 60; COMP(i) = 2; end
            end
        end

        lastcomp = find(COMP == 2,1,'last');
        if     isempty(lastcomp);       CurrSession.value = 1;
        elseif lastcomp == numel(COMP); CurrSession.value = [];
        else                            CurrSession.value = lastcomp + 1;
        end

        %In the event the system thinks we've finished 9 but there are
        %sessions earlier that aren't completed, let's find the first not
        %completed session and make that the current session.
        %careful with no of sessions
        if isempty(value(CurrSession))
            notcomp = find(COMP ~= 2,1,'first');
            if ~isempty(notcomp)
                CurrSession.value = notcomp;
            end
        end
        % WARNING : dummy value added by sharbat
        %         CurrSession.value = 4
        % WARNING : dummy value added by sharbat
        CurrSession.value = find(COMP ~= 2,1,'first');
        SchList.value = value(CurrSession);

        if isempty(value(CurrSession)) || value(CurrSession) ~= CS
            disp('Updating Current Session');

            if ~isempty(value(CurrSession))
                runrats(obj,'updatelog','update_session');
            end

            if (isempty(value(CurrSession)) && ~isempty(CS) && CS == 5) %|| (value(CurrSession) == 7 && CS == 6)
                %Training for today is nearing its end but this rig is
                %likely not running a rat in session 9 or it's already out.
                %Let's do the daily reboot for this rig here.
                runrats(obj,'reboot')
            end

        end


    case 'safety_button'
        %% safety_button
        %The user had clicked the safety button which will unlock the multi
        %button

        set(get_ghandle(Multi),'enable','on');


    case 'multi_button'
        %% multi_button
        %The user has clicked the Multi purpose button, depending on what
        %state runrats is in, this button will do different things. Let's
        %figure out what to do here.

        if     strcmp(get(get_ghandle(Multi),'string'),'Load Protocol')
            runrats(obj,'begin_load_protocol');

        elseif ~isempty(strfind(get(get_ghandle(Multi),'string'),'Run'))
            runrats(obj,'run');

        elseif ~isempty(strfind(get(get_ghandle(Multi),'string'),'End Session'))
            runrats(obj,'end');

        elseif ~isempty(strfind(get(get_ghandle(Multi),'string'),'Crashed'))
            runrats(obj,'crash_cleanup');

        end


    case 'begin_load_protocol'
        %% begin_load_protocol
        %Let's unload any protocols from dispatcher and either do the
        %manual test or skip right to loading the protocol depending on the
        %rig's settings

        %dammy add here

        InLiveLoop.value = 0;
        runrats(obj,'disable_all');

        set(get_ghandle(Multi),'string','Unloading...','fontsize',28);

        x = '';
        try x = dispatcher('get_protocol_object'); end %#ok<TRYNC>
        if ~isempty(x)
            %There was a protocol previously open. Let's not trust that
            %their close section is working properly.
            try  %#ok<TRYNC>
                %rigscripts does not exist currently, try Protocols (ask
                %Athena) -sharbat
                p = bSettings('get','GENERAL','Main_Code_Directory');
                p(strfind(p,'ExperPort'):end) = '';
                p = [p,'Rigscripts'];
                cd(p);
                if ispc == 1
                    system('restart_runrats.bat');
                end
            end
        end

        dispatcher('set_protocol','');
        if bSettings('get','RUNRATS','skip_manual_test') == 1
            runrats(obj,'load_protocol');
        else
            runrats(obj,'manual_test');
        end


    case 'manual_test'
        %% manual_test
        %Load and run the manual test protocol

        %Reset the values that GCS sees for trials and performance
        try send_n_done_trials(obj,'reset'); end %#ok<TRYNC>

        set(get_ghandle(Multi),'string','Loading Test','fontsize',28);

        r = rand(1);
        if r < 0.0015 && value(RigID) < 40
            runrats(obj,'updatelog','manualtest_leftfail');
            dispatcher('set_protocol','Rigtest_singletrial_leftfail');
        elseif r < 0.003 && value(RigID) < 40
            runrats(obj,'updatelog','manualtest_rightfail');
            dispatcher('set_protocol','Rigtest_singletrial_rightfail');
        else
            runrats(obj,'updatelog','manualtest');
            dispatcher('set_protocol','Rigtest_singletrial');
        end
        %Hide protocol window.
        h=get_sphandle('owner','Rigtest_singletrial','name', 'myfig');
        for i=1:numel(h); set(value(h{i}),'Visible','Off'); end

        set(get_ghandle(Multi),'String','Manual Test','Fontsize',28);
        StatusBar.value='Please test the rig by poking in the lit pokes.';

        %Begin execution of the manual test protocol.
        dispatcher(value(dispobj),'Run'); %#ok<NODEF>

        %RigTest_singletrial will call runrats('rigtest_singletrial_is_complete')
        %after it finishes one trial at which point we continue on


    case 'rigtest_singletrial_is_complete'
        %% rigtest_singletrial_is_complete
        %The manual test is complete, let's clear out the protocol and move
        %on to load the rat's protocol and settings

        set(get_ghandle(Multi),'String','Unloading Test','Fontsize',24);
        StatusBar.value='Completing Test. Please be patient!';

        dispatcher(value(dispobj),'Stop'); %#ok<NODEF>

        %Let's pause until we know dispatcher is done running
        set(value(stopping_complete_timer),'TimerFcn',[mfilename,'(''rigtest_singletrial_is_complete_continued'');']);
        start(value(stopping_complete_timer));


    case 'rigtest_singletrial_is_complete_continued',
        %% rigtest_singletrial_is_complete_continued
        if value(stopping_process_completed) %This is provided by dispatcher to runrats
            stop(value(stopping_complete_timer)); %Stop looping.
            dispatcher('set_protocol','');
            runrats(obj,'load_protocol');
        end



    case 'load_protocol'
        %% load_protocol
        %Okay, we are finally ready to load the protocol and the rats
        %settings, runrats will then wait for the tech to click Run

        %Let's make sure we have the most up-to-date settings
        runrats(obj,'update_rat',0);

        set(get_ghandle(Multi),'String','Loading...','BackgroundColor', [0.8 0.8 0.6],'Fontsize',30);
        StatusBar.value='Loading protocol and settings.  Please be patient!';
        pause(0.1);

        %%%%%%%%%%%% ARPIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % NOT REQUIRED AS INSTEAD OF SVN WE ARE USING GITHUB 

        %Let's also make sure we have the most up-to-date code
        
        % CurrDir = pwd;
        % pname = bSettings('get','GENERAL','Main_Code_Directory');
        % if ~isempty(pname) && ischar(pname)
        %     update_folder(pname,'svn');
        % end
        % 
        % %And finally we make sure the protocols are up-to-date
        % pname = bSettings('get','GENERAL','Protocols_Directory');
        % if ~isempty(pname) && ischar(pname)
        %     update_folder(pname,'svn');
        % end
        % cd(CurrDir);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %Let's get the protocol for the rat and load it
        CurrProtocol.value = getProtocol(value(ExpMenu),value(RatMenu)); %#ok<NODEF>
        if isempty(value(CurrProtocol))
            StatusBar.value = ['No Settings for ',value(RatMenu)];
            runrats(obj,'enable_all');
            set(get_ghandle(Multi),'string','Load Protocol','BackgroundColor',[1,1,0.4],'FontSize',24);
            InLiveLoop.value = 1;

            %Let's notify the experimenter that the load failed, pause to
            %let the tech see the note, then go back to live loop
            runrats(obj,'email_experimenter','no settings');

            runrats(obj,'updatelog','nosettings');

            pause(10);
            runrats(obj,'live_loop');
            return;
        end

        try
            dispatcher(value(dispobj),'set_protocol',value(CurrProtocol)); %#ok<NODEF>
        catch %#ok<CTCH>
            StatusBar.value = ['Failed to load ',value(CurrProtocol),' for ',value(RatMenu)];
            runrats(obj,'enable_all');
            set(get_ghandle(Multi),'string','Load Protocol','BackgroundColor',[1,1,0.4],'FontSize',24);
            InLiveLoop.value = 1;

            %Let's notify the experimenter that the load failed, pause to
            %let the tech see the note, then go back to live loop
            runrats(obj,'email_experimenter','protocol fail');

            runrats(obj,'updatelog','failload protocol');

            pause(10);
            runrats(obj,'live_loop');
            return;
        end

        rath=get_sphandle('name','ratname','owner',value(CurrProtocol));
        exph=get_sphandle('name','experimenter','owner',value(CurrProtocol));
        rath{1}.value=value(RatMenu); %#ok<NASGU>
        exph{1}.value=value(ExpMenu); %#ok<NASGU>

        try
            protobj=eval(value(CurrProtocol));

            [out, sfile]=load_solouiparamvalues(value(RatMenu),'experimenter',value(ExpMenu),...
                'owner',class(protobj),'interactive',0);
            settings_file_sph.value = sfile;
            settings_file_load_time.value = now;
            if ~dispatcher('is_running')
                pop_history(class(protobj), 'include_non_gui', 1);
                feval(value(CurrProtocol), protobj, 'prepare_next_trial');
            end
        catch %#ok<CTCH>
            StatusBar.value = 'Failed to load Settings file.';
            runrats(obj,'enable_all');
            set(get_ghandle(Multi),'string','Load Protocol','BackgroundColor',[1,1,0.4],'FontSize',24);
            InLiveLoop.value = 1;

            %Let's notify the experimenter that the load failed, pause to
            %let the tech see the note, then go back to live loop
            runrats(obj,'email_experimenter','settings fail');

            runrats(obj,'updatelog','failload settings');

            pause(10);
            runrats(obj,'live_loop');
            return;
        end

        set(get_ghandle(Multi),'String',['Run: ',value(RatMenu)],'BackgroundColor',[0.3,1,0.3],'Fontsize',32);
        [pname,fname,ext] = fileparts(sfile); %#ok<NASGU>

        StatusBar.value=['Using settings file: ',fname];
        if value(phys)==1
            create_phys_session(eval(value(CurrProtocol)))
        end

        runrats(obj,'enable_all');
        figure(value(myfig));
        InLiveLoop.value = 0;

        %Check to see if the experimenter wants to enable the safety before
        if ~isempty(strfind(value(SafetyMode),'B')) %#ok<NODEF>
            set(get_ghandle(Multi),'enable','off');
            set(get_ghandle(Safety),'visible','on','string',value(Instructions)); %#ok<NODEF>
        else
            set(get_ghandle(Multi),'enable','on');
            set(get_ghandle(Safety),'visible','off','string','');
        end


    case  'run'
        %% run
        %Here we start the protocol running
        runrats(obj,'updatelog','runstart');
        runrats(obj,'disable_all');
        set(get_ghandle(Multi),'String','End Session','BackgroundColor',[1,0.2,0.2],'Fontsize',28);
        StatusBar.value = ['Start Time: ',datestr(now,'HH:MM PM'),'. ',value(StatusBar)]; %#ok<NODEF>

        try
            sendstarttime(eval(value(CurrProtocol))); %#ok<NODEF>
        catch %#ok<CTCH>
            disp('ERROR: Failed to add the start time to the MySQL table.');
        end

        %Let's make everything unresponsive for 5 more seconds to prevent
        %double clicks from stopping the session
        pause(5);

        %Start raspberry pi_camera
        % try
        %     disp('trying camera')
        %     start_camera(value(RigID),value(RatMenu),value(CurrProtocol),'start')
        % catch
        %     disp('failed to start pi camera')
        % end

        % If using USB Webcam, then try using it instead using Bonsai
        % try
        %     disp('Connecting to USB HD Camera')
        %     webcam_connected = webcamlist;
        %     webcam_idx = find(contains(webcam_connected,'USB'));
        %     if ~isempty(webcam_idx) % USB Camera connected
        %         cam = webcam(webcam_connected{webcam_idx});
        %         fig = figure('NumberTitle','off','MenuBar','none');
        %         fig.Name = 'My Camera';
        %         ax = axes(fig);
        %         frame = snapshot(cam);
        %         im = image(ax,zeros(size(frame),'uint8'));
        %         axis(ax,'image');
        %         preview(cam,im)
        %         Camera_Fig_window.value = fig;
        %         Camera_Obj.value = cam;
        %         Camera_Image.value = im;
        %     else
        %         disp('No USB camera connected')
        %     end            
        % catch
        %     disp('failed to connect to USB camera')
        % end

        %Enable the Multi button so the user can stop the session
        enable(Multi);

        %Check to see if the experimenter wants to enable the safety before
        if ~isempty(strfind(value(SafetyMode),'A')) %#ok<NODEF>
            set(get_ghandle(Multi),'enable','off');
            set(get_ghandle(Safety),'visible','on','string',value(Instructions)); %#ok<NODEF>
        else
            set(get_ghandle(Multi),'enable','on');
            set(get_ghandle(Safety),'visible','off','string','');
        end
        
        % Let start recording the videos by sending the command to protocol
        % itself instead of the plugin bonsaicamera
        protobj=eval(value(CurrProtocol));
        feval(value(CurrProtocol), protobj, 'start_recording');

        % Now ready to run with dispatcher
        dispatcher(value(dispobj),'Run'); %#ok<NODEF>


    case 'flicker_multibutton'
        %% flicker_multibutton
        %Called by dispatcher while running to invert the color of the
        %multi button, let's the tech know if the rig is running
        clr = get(get_ghandle(Multi),'BackgroundColor');
        set(get_ghandle(Multi),'BackgroundColor',1 - clr);


    case  'end'
        %% end
        %Ends the current protocol being run through dispatcher
        runrats(obj,'updatelog','runend');
        runrats(obj,'disable_all');
        set(get_ghandle(Multi),'String','Saving...','Fontsize',32);
        
        %Stop raspberry pi_camera
        % try
        %     disp('stopping camera')
        %     start_camera(value(RigID),value(RatMenu),value(CurrProtocol),'stop')
        % catch
        %     disp('failed to stop pi camera')
        % end

        % Stop USB Camera
        % try
        %     closePreview(value(Camera_Obj))
        %     clear(value(Camera_Image))
        %     clear(value(Camera_Obj));
        %     close(value(Camera_Fig_window));
        %     disp('USB camera stopped')
        % catch
        %     disp('failed to stop USB camera')
        % end

        %Stop dispatcher and wait for it to respond
        dispatcher(value(dispobj),'Stop'); %#ok<NODEF>

        %Let's pause until we know dispatcher is done running
        set(value(stopping_complete_timer),'TimerFcn',[mfilename,'(''end_continued'');']);
        start(value(stopping_complete_timer));


    case 'end_continued'
        %% end_continued
        if value(stopping_process_completed) %This is provided by dispatcher to runrats
            stop(value(stopping_complete_timer)); %Stop looping.

            %Now that everything is stopped let's send an empty state
            %matrix to the Linux machine.  This will reset all the lines
            %and sounds to be off.
            runrats(obj,'send_empty_state_machine')

            protobj=eval(value(CurrProtocol)); %#ok<NODEF>
            feval(value(CurrProtocol), protobj, 'end_session');
            sfile=SavingSection(protobj,'savedata','interactive',0);

            %if the protocol has a pre_saving_settings section, call it
            try
                feval(value(CurrProtocol),protobj,'pre_saving_settings');
            catch %#ok<CTCH>
                disp('Protocol does not appeat to have a pre_saving_settings')
            end


            SavingSection(protobj,'savesets','interactive',0);

            [pname,fname] = fileparts(sfile);

            configFilePath = '..\PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat';
            load(configFilePath);
            svnusername = svn_user;
            svnpsswd = svn_password;
            logmsg = 'saved data and settings file';

            cd(pname);
            cmdstr = char(strcat('svn add', {' '}, fname, '.mat',{'@'})); %the @ calls for a peg revision, ref to
            % https://stackoverflow.com/questions/27312188/how-to-move-rename-a-file-in-subversion-with-characters-in-it
            system(cmdstr);
            cmdstr2 = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
            if ~(system(cmdstr2))
                display('SoloData data files added!')
            end

            [setpname, setfname] = fileparts(value(settings_file_sph));
            cd(setpname);
            cmdstr3 = char(strcat('svn add', {' '}, setfname, '.mat',{'@'})); %the @ calls for a peg revision, ref to
            % https://stackoverflow.com/questions/27312188/how-to-move-rename-a-file-in-subversion-with-characters-in-it
            try
                system(cmdstr3);
            catch
                display('SoloData settings files seem to be there!')
            end

            cmdstr4 = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
            if ~(system(cmdstr4))
                display('SoloData settings files added!')
            end
            StatusBar.value=['Saved data and settings file: ',fname];

            set(get_ghandle(Multi),'String','Reloading');
            dispatcher('set_protocol','');

            %Let's reset the Multi button and hop back in the live loop
            set(get_ghandle(Multi),'ForegroundColor',[0,0,0],'BackgroundColor',...
                [1,1,0.4],'string','Load Protocol','FontSize',24);
            InLiveLoop.value = 0; % Changed by Arpit as the timer function is preventing 'flush' to run
            runrats(obj,'enable_all');

            %We need to turn RunRats back to live mode
            h = value(PanelBack); %#ok<NODEF>
            for i = 1:length(h);
                set(h(i),'BackgroundColor',[1,0.8,0.6]);
            end
            set(get_ghandle(UpdateMode),'String','Live Update On','BackgroundColor',[0.6 1 0.6],'ForegroundColor',[0 0 0]);

            %%%%%%%%%%%%%%Removing the part of full restart %%%%%%%%%%%%%%
                    %%%%%%%%%%%%% ARPIT %%%%%%%%%%%%%%%%%%%%%

            do_full_restart.value = 0;
            p = bSettings('get','GENERAL','Main_Code_Directory');
            cd(p);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
            %Another option is to now kill MatLab completely and restart
            %runrats.  This ensures windows don't pile up, and code can get
            %updated before each session

            if value(do_full_restart) == 1

                %Close the MySQL connection
                try bdata('close'); end %#ok<TRYNC>

                if value(CurrSession) == 9 %|| value(CurrSession) == 6 %#ok<NODEF>
                    %We just finished session 9 so let's do a full reboot
                    runrats(obj,'reboot')
                else
                    %This is an earlier session during the day, let's simply
                    %restart Matlab
                    %
                    pause(1);
                    drawnow;

                    p = bSettings('get','GENERAL','Main_Code_Directory');
                    p(strfind(p,'ExperPort'):end) = '';
                    p = [p,'Rigscripts'];
                    cd(p);

                    try %#ok<TRYNC>
                        if ispc == 1
                            system('restart_runrats.bat')
                        else
                            system('./start_runrats.sh')
                        end
                    end
                end
            end

            %And now we hop back in the loop
            % runrats(obj,'live_loop');
        end


    case 'reboot'
        %% reboot
        %This is designed to execute once each day, either when the session
        %9 rat is done training or if this rig is not running a rat in
        %session 9, when it sees that session 9 is nearning completion.
        runrats(obj,'updatelog','reboot');
        try
            try
                %Once a week try to email me the datalogs so I can see if
                %things are working. I'll deactivate this once I know all
                %is working properly.
                if strcmp(datestr(now,'ddd'),'Mon')
                    file = which('runrats_datalog.txt');
                    path = bSettings('get','GENERAL','Main_Data_Directory');
                    newfile = [path,filesep,'Data',filesep,'RunRats',filesep,'Rig',sprintf('%03.0f',value(RigID)),filesep,...
                        datestr(now,'yymmdd'),'_','Rig',sprintf('%03.0f',value(RigID)),'_runrats_datalog.txt'];
                    system(['echo f | xcopy "',file,'" "',newfile,'"']);
                    add_and_commit(newfile);
                end
            end
            cd('\ratter\Rigscripts')

            !del do_on_reboot.bat
            !copy start_runrats.bat do_on_reboot.bat /Y
            pause(1)
            system('shutdown -r -f -t 1');
            pause(20);
            %!copy nothing.bat do_on_reboot.bat /Y
        end


    case 'crashed'
        %% crashed
        %Dispatcher crashed while running the protocol. Let's notify the
        %tech that we've crashed and send an email with the last error
        %message to the rat's owner. We will also update a MySQL table that
        %the GCS reads to post that a crash happened
        runrats(obj,'updatelog','crashed');
        set(get_ghandle(Multi),'String','Crashed','BackgroundColor',[0,0,0],...
            'ForegroundColor',[1,1,1],'Fontsize',40);
        enable(Multi);

        if ~isempty(varargin) && iscell(varargin) && strcmp(class(varargin{1}),'MException')
            lsterr = varargin{1};
        else
            lsterr = lasterror; %#ok<LERR>
        end

        %Let's stop dispatcher and clean it up
        RunningSection(value(dispobj),'RunStop'); %#ok<NODEF>
        dispatcher('set_protocol','');

        %Now we can email the rat's owner a detailed crash report
        try %#ok<TRYNC>
            error_message = lsterr.message;
            error_message = strrep(error_message, '\', '\\');
            error_message = strrep(error_message, '"', '\"');
            message = cell(0);
            message{end+1} = ['Rig ',num2str(value(RigID)),' crashed while running ',value(RatMenu),' at ',datestr(now,13)]; %#ok<NODEF>
            message{end+1} = '';
            message{end+1} = lsterr.identifier;            
            message{end+1} = error_message;
            file_path = lsterr.stack(1).file;
            message{end+1} = strrep(file_path, '\', '\\');
            message{end+1} = lsterr.stack(1).name;
            message{end+1} = num2str(lsterr.stack(1).line);
            message{end+1} = '';
            
            for i = 1:length(lsterr.stack)
                message{end+1} = ['Line ' num2str(lsterr.stack(i).line) ', File ' lsterr.stack(i).file ', Function ' lsterr.stack(i).name]; %#ok<AGROW>
            end

            IP = get_network_info;
            message{end+1} = ' ';
            if ischar(IP); message{end+1} = ['Email generated by ',IP];
            else           message{end+1} = 'Email generated by an unknown computer!!!';
            end
            message{end+1} = 'ratter\ExperPort\Modules\@runrats\runrats.m';

            %setpref('Internet','SMTP_Server','brodyfs2.princeton.edu');
            %setpref('Internet','E_mail',['RunRats',datestr(now,'yymm'),'@Princeton.EDU']);
            % set_email_sender

            owner = bdata(['select contact from rats where ratname="',value(RatMenu),'"']);
            if ~isempty(owner)
                owner = owner{1};
                owner = [',',owner,','];
                owner(owner == ' ') = '';
                cms = find(owner == ',');

                for i = 1:length(cms)-1
                    exp = owner(cms(i)+1:cms(i+1)-1);
                    % sendmail([exp,'@ucl.ac.uk'],[value(RatMenu),' Crashed'],message);
                    gmail_SMTP([exp,'@ucl.ac.uk'],[value(RatMenu),' Crashed'],message);
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Modified/Added by Arpit

        %Let's update the MySQL table to indicate a crash has happened
        %Since this sql table is missing, the same information can be 
        % obtained from sess_started table where was_ended will stay 0. 
        
        % id = bdata(['select sessid from sess_started where ratname="',value(RatMenu),...
        %     '" and was_ended=0 and sessiondate="',datestr(now,'yyyy-mm-dd'),'"']);
        % if ~isempty(id)
        %     id = id(end);
        %     bdata('call mark_crashed("{S}")',id);       
        % end

        %% Lets try and rerun the protocol and only do it if the animal is training
        try
            is_rat_training = bdata(['select in_training from rats where experimenter="',value(ExpMenu),'" and ratname="', value(RatMenu),'"']);
        catch
            is_rat_training = 1; % if couldn't find then try rerun of the protocol
        end

        if value(Rerun_AfterCrash) == 1 && is_rat_training == 1
                runrats(obj,'rerun');
        end


    case 'rerun' % called in 'crash' and made by combining 'begin_load_protocol' , 'load_protocol' and 'run' 

        InLiveLoop.value = 0;
        runrats(obj,'disable_all');

        set(get_ghandle(Multi),'string','Unloading...','fontsize',28);

        x = '';
        try x = dispatcher('get_protocol_object'); end %#ok<TRYNC>
        if ~isempty(x)
            %There was a protocol previously open. Let's not trust that
            %their close section is working properly.
            try  %#ok<TRYNC>
                %rigscripts does not exist currently, try Protocols (ask
                %Athena) -sharbat
                p = bSettings('get','GENERAL','Main_Code_Directory');
                p(strfind(p,'ExperPort'):end) = '';
                p = [p,'Rigscripts'];
                cd(p);
                if ispc == 1
                    system('restart_runrats.bat');
                end
            end
        end

        dispatcher('set_protocol','');

        % Loading the protocol and setting file
        runrats(obj,'load_protocol')

        % Running the protocol
        runrats(obj,'run')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'crash_cleanup'
        %% crash_cleanup
        %The tech has acknowledged the crash. Let's jump back in the loop

        runrats(obj,'enable_all');
        set(get_ghandle(Multi),'ForegroundColor',[0,0,0],'BackgroundColor',...
            [1,1,0.4],'string','Load Protocol','FontSize',24);

        InLiveLoop.value = 1;
        % runrats(obj,'live_loop');

    case 'updatelog'

        try
            Exp = value(ExpMenu);
            Rat = value(RatMenu);
            Sch = value(SchList);

            time = datestr(now,'yymmdd HH:MM:SS');

            str = [time,' ',varargin{1},' ',Exp,' ',Rat,' ',Sch,char(10)];
            file = which('runrats_datalog.txt');
            f = fopen(file,'a+t');
            fseek(f,0,'eof');
            fprintf(f,str,'char');
            fclose(f);

            %runrats_datalog{end+1} = str;
            %save(file,'runrats_datalog');
        end


    case 'email_experimenter'
        %% email_experimenter
        %Something has gone wrong during the load phase and we should email
        %the experimenter if we can

        try %#ok<TRYNC>
            %setpref('Internet','SMTP_Server','brodyfs2.princeton.edu');
            %setpref('Internet','E_mail',['RunRats',datestr(now,'yymm'),'@Princeton.EDU']);
            % set_email_sender

            message{1} = ['Load failed for ',value(RatMenu)]; %#ok<NODEF>
            if strcmp(varargin{1},'no settings')
                subject    = ['No settings for ',value(RatMenu)];
                message{2} = ['Please check that there are settings for ',value(RatMenu)];
            elseif strcmp(varargin{1},'protocol fail')
                subject    = ['Failed to load ',value(CurrProtocol)]; %#ok<NODEF>
                message{2} = ['Protocol ',value(CurrProtocol),' could not be laoded for ',value(RatMenu)];
            else
                subject    = ['Failed to load settings for ',value(RatMenu)];
                message{2} = ['The settings file for ',value(RatMenu),' failed to load'];
            end

            IP = get_network_info;
            message{end+1} = ' ';
            if ischar(IP); message{end+1} = ['Email generated by ',IP];
            else           message{end+1} = 'Email generated by an unknown computer!!!';
            end
            message{end+1} = 'ratter\ExperPort\Modules\@runrats\runrats.m';

            contact = bdata(['select contact from rats where ratname="',value(RatMenu),'"']);
            if ~isempty(contact)
                contact = [',',contact{1},','];
                contact(contact == ' ') = '';
                cms = find(contact == ',');
                for i = 1:length(cms)-1
                    email = contact(cms(i)+1:cms(i+1)-1);
                    % sendmail([email,'@princeton.edu'],subject,message);
                    gmail_SMTP([email,'@ucl.ac.uk'],subject,message);
                end
            end
        end




    case 'is_running'
        %% is_running
        %If the Multi button exists, runrats has been loaded
        if exist('Multi','var'), obj = 1; else obj = 0; end


    case 'get_settings_file_load_time'
        %% get_settings_file_load_time
        %This is called by SavingSection, let's not modify it

        if exist('settings_file_load_time', 'var') && isa(settings_file_load_time, 'SoloParamHandle') %#ok<NODEF>
            varargout{1} = value(settings_file_load_time);
        else
            varargout{1} = 0;
        end


    case 'get_settings_file_path'
        %% get_setting_file_path
        %This is called by SavingSection, let's not modify it

        if exist('settings_file_sph', 'var') && isa(settings_file_sph, 'SoloParamHandle') %#ok<NODEF>
            varargout{1} = value(settings_file_sph);
        else
            varargout{1} = '';
        end
     

    case  'close'
        %% close
        %Closes runrats

        runrats(obj,'close_gui_only');

        try
            dispatcher(value(dispobj),'close'); %#ok<NODEF>
        catch %#ok<CTCH>
            disp('WARNING: Dispatcher close attempt in runrats failed.');
        end


    case 'close_gui_only'
        %% close_gui_only

        try
            StatusBar.value='Cleaning up......';
            runrats(obj,'disable_all');
        catch %#ok<CTCH>
            disp('WARNING: Close attempt in runrats failed.');
        end
        delete(value(myfig));

        delete_sphandle('owner', ['^@', mfilename '$']);
        obj = [];


    otherwise
        warning('Unknown action " %s" !', action);%#ok<WNTAG>
end

return;


function p=getProtocol(exprmtr,rat)

olddir=cd;
p='';
try %#ok<TRYNC>
    dd=bSettings('get','GENERAL','Main_Data_Directory');

    if isnan(dd); dd='../SoloData'; end
    if dd(end)~=filesep; dd(end+1)=filesep; end
    %changed filesep, sharbat
    dd=[dd,'Settings',filesep];
    cd([dd,exprmtr,filesep,rat]);
    fn=dir('settings_*_*_*_*.mat');
    for xi=1:numel(fn)
        s=fn(xi).name;
        tc=textscan(s,'%s','Delimiter','_');
        prt{xi}=tc{1}{2};         %#ok<AGROW>
        r=tc{1}{end};
        % Must have had 5 fields (settings, prot, exprtr, rat, date), the
        % date must be 11 chars long (7 of date plus '.mat'), the first six
        % of those must be numbers, not letters:
        if length(tc{1}) == 5 && length(r) == 11 && all(~isletter(r(1:6))),
            setdate{xi}=r(1:7); %#ok<AGROW>
        else % not a file we want, give it a really early date, 2000:
            setdate{xi}='000101a'; %#ok<AGROW>
        end
    end

    [srtdsets, sdi]=sort(setdate);

    % Look only at settings that are not later than today
    ymd = str2double(yearmonthday); keeps = ones(size(sdi));
    for i=1:length(sdi), if str2double(srtdsets{i}(1:6)) > ymd, keeps(i) = 0; end; end;
    srtdsets = srtdsets(find(keeps)); sdi = sdi(find(keeps)); %#ok<FNDSB,NASGU>

    p=prt{sdi(end)};
    if p(1)=='@'
        p=p(2:end);
    end

end
cd(olddir)


function update_folder(pname,vn)

try
    currdir = pwd;
    cd(pname);
    if strcmp(vn,'cvs')
        failed1 = 0;
        [failed2 message2] = system('cvs up -d -P -A');
    elseif strcmp(vn,'svn')
        [failed1 message1] = system('svn cleanup');
        [failed2 message2] = system('svn update');
    end
    cd(currdir);

    rig = bSettings('get','RIGS','Rig_ID');
    if ~ischar(rig); rig = num2str(rig); end

    if failed1 == 1 || failed2 == 1
        %setpref('Internet','SMTP_Server','brodyfs2.princeton.edu');
        %setpref('Internet','E_mail',['RunRats',datestr(now,'yymm'),'@Princeton.EDU']);
        % set_email_sender

        if pname(1)   ~= filesep; pname = [filesep,pname]; end
        if pname(end) ~= filesep; pname = [pname,filesep]; end
        fs = find(pname == filesep);

        contact = '';
        for i = 1:length(fs)-1
            temp = pname(fs(i)+1:fs(i+1)-1);
            if length(temp) == 4 && ~isempty(str2num(temp(2:4))) %#ok<ST2NM>
                %This is a rat, let's email the owner
                contact = bdata(['select contact from rats where ratname="',temp,'"']);
            elseif strcmpi(temp,'experport') || strcmpi(temp,'protocols')
                contact = {'ckopec'};
            end
        end

        if failed1 == 1
            message    = cell(0);
            message{1} = ['SVN cleanup failed in ',pname];
            message{2} = ' ';
            message{3} = message1;

            IP = get_network_info;
            message{end+1} = ' ';
            if ischar(IP); message{end+1} = ['Email generated by ',IP];
            else           message{end+1} = 'Email generated by an unknown computer!!!';
            end
            message{end+1} = 'ratter\ExperPort\Modules\@runrats\runrats.m';

            ctemp = [',',contact{1},','];
            ctemp(ctemp == ' ') = '';
            cms = find(ctemp == ',');
            for i = 1:length(cms)-1
                email = ctemp(cms(i)+1:cms(i+1)-1);
                % sendmail([email,'@princeton.edu'],['SVN Cleanup FAILED on Rig ',rig],message);
                gmail_SMTP([email,'@ucl.ac.uk'],['SVN Cleanup FAILED on Rig ',rig],message);
            end
        end

        if failed2 == 1
            message    = cell(0);
            message{1} = [vn,' update failed in ',pname];
            message{2} = ' ';
            message{3} = message2;
            if     strcmp(vn,'cvs'); subject = ['SVN Update FAILED on Rig ',rig];
            elseif strcmp(vn,'svn'); subject = ['SVN Update FAILED on Rig ',rig];
            else                     subject = '';
            end

            IP = get_network_info;
            message{end+1} = ' ';
            if ischar(IP); message{end+1} = ['Email generated by ',IP];
            else           message{end+1} = 'Email generated by an unknown computer!!!';
            end
            message{end+1} = 'ratter\ExperPort\Modules\@runrats\runrats.m';

            ctemp = [',',contact{1},','];
            ctemp(ctemp == ' ') = '';
            cms = find(ctemp == ',');
            for i = 1:length(cms)-1
                email = ctemp(cms(i)+1:cms(i+1)-1);
                % sendmail([email,'@ucl.ac.uk'],subject,message); %
                gmail_SMTP([email,'@ucl.ac.uk'],subject,message); % Using gmail instead of brody smtp
            end
        end
    end
catch %#ok<CTCH>
    senderror_report;
end



function gmail_SMTP(recipient_email,subject_line,email_body)

smtp_server = 'smtp.gmail.com';
smtp_port = '587'; % Use TLS
email_address = 'behav.akramilab@gmail.com';
email_password = 'fakc mdbw woef lqmq'; % IMPORTANT: this is set in setting of gmail

% recipient_email = 'arpit.agarwal@ucl.ac.uk';
% subject_line = 'Test Email from MATLAB via Gmail';
% email_body = 'This email was sent using Gmail SMTP from MATLAB.';

% --- Set MATLAB Email Preferences ---
setpref('Internet','SMTP_Server',smtp_server);
setpref('Internet','E_mail',email_address);
setpref('Internet','SMTP_Username',email_address);
setpref('Internet','SMTP_Password',email_password);

% Set server properties
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.starttls.enable','true');
props.setProperty('mail.smtp.port',smtp_port);

% --- Send the Email ---
try
    sendmail(recipient_email, subject_line, email_body);
    disp('Email sent successfully via Gmail SMTP.');
catch ME
    disp(['Error sending email: ' ME.message]);
end

