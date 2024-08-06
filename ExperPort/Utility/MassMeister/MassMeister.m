function varargout = MassMeister(varargin)
% MASSMEISTER M-file for MassMeister.fig
%      MASSMEISTER, by itself, creates a new MASSMEISTER or raises the existing
%      singleton*.
%
%      H = MASSMEISTER returns the handle to a new MASSMEISTER or the handle to
%      the existing singleton*.
%
%      MASSMEISTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASSMEISTER.M with the given input arguments.
%
%      MASSMEISTER('Property','Value',...) creates a new MASSMEISTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MassMeister_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MassMeister_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MassMeister

% Last Modified by GUIDE v2.5 07-Oct-2011 09:57:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MassMeister_OpeningFcn, ...
                   'gui_OutputFcn',  @MassMeister_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MassMeister is made visible.
function MassMeister_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
handles.output = hObject;

set(double(gcf),'name','MassMesiter V2.3');
set(handles.date_text,'string',datestr(now,'yyyy-mm-dd'));
handles.groups = get(handles.session_list,'string');
handles = get_newrats( handles);
handles = get_colors(  handles);
handles = update_names(handles);

handles = update_lists(handles);
handles = update_ratname(handles);

%Let's try to establish a connection to the balance
try
    handles.balance = serial('COM1');
    set(handles.balance,'Terminator','CR');
    fopen(handles.balance);
    set(handles.status_text,'string','Please select your name.',...
        'backgroundcolor',[1 1 1]);
catch %#ok<CTCH>
    handles.balance = [];
    set(handles.status_text,'string','ERROR: Can''t connect to balance',...
        'backgroundcolor',[1 0 0]);
end

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = MassMeister_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
varargout{1} = handles.output;


% --- Executes on selection change in session_list.
function session_list_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>

handles = update_lists(handles);
handles = update_ratname(handles);
guidata(hObject, handles);


% --- Executes on selection change in ratname_list.
function ratname_list_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>

handles = update_ratname(handles);
guidata(hObject,handles);



% --- Executes on button press in start_toggle.
function start_toggle_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>

if get(handles.start_toggle,'value') == 0
    set(handles.start_toggle,'backgroundcolor',[0 1 0],'string','Start');    
    set(handles.mass_text,'string','0');
else
    set(handles.start_toggle,'backgroundcolor',[1 0 0],'string','Stop');
    uicontrol(handles.ratname_list);
    
    %Let's load the settings file
    handles = load_settings(handles);
    
    %Let's jump to the first empty rat in the list.
    handles = jump_to_empty(handles);
    
    timeout       = 2;
    foundstable   = 0;
    doing_reweigh = 0;
    M = [];
    while get(handles.start_toggle,'value') == 1
        cyclestart = now;

        %Let's get the mass off the balance
        fprintf(handles.balance,'P'); 
        m = fscanf(handles.balance);
        if (now-cyclestart)*24*3600 > timeout
            set(handles.start_toggle,'backgroundcolor',[0 1 0],'string','Start','value',0); 
            set(handles.status_text,'string','ERROR: Can''t connect to balance',...
                'backgroundcolor',[0 1 0]);
            set(handles.mass_text,'string','0');
            return
        end
        
        m = str2num(m(2:12)); %#ok<ST2NM>
        
        set(handles.mass_text,'string',num2str(m));
        
        if m > handles.minmass
            %There is a rat on the scale
            if foundstable == 0
                %we do not yet have a stable reading
                if length(M) < handles.numreads
                    M(end+1) = m; %#ok<AGROW>
                else
                    %We have a full list of readings
                    M(1:end-1)=M(2:end);
                    M(end) = m; %#ok<AGROW>
                    p = polyfit(1:handles.numreads,M,1);
                    score = abs(p(1) * handles.rate)/mean(M);

                    if score < handles.threshold / 100
                        %We have a stable reading
                        foundstable = 1;
                        
                        ratname = get(handles.ratname_text,'string');
                        weight = round(mean(M));
                        
                        %If we have an entry for this rat today, delete it
                        try
                            id = bdata(['select weighing from ratinfo.mass where date="',...
                                datestr(now,29),'" and ratname="',ratname,'"']);
                            if ~isempty(id); bdata('call bdata.delete_weighing("{Si}")',id); end
                        catch %#ok<CTCH>
                            set(handles.status_text,'string','ERROR: Unable to connect to network.',...
                                'backgroundcolor',[1 0 0]);
                            set(handles.start_toggle,'value',0);
                            return
                        end
                        
                        %Insert the new weight into the MySQL table
                        try
                            bdata(['insert into ratinfo.mass set mass=',num2str(weight),...
                                ', date="',datestr(now,29),'", ratname="',ratname,...
                                '", tech="',handles.active_user,'", timeval="',datestr(now,'HH:MM:SS'),'"']); 
                        catch %#ok<CTCH>
                            set(handles.status_text,'string','ERROR: Unable to connect to network.',...
                                'backgroundcolor',[1 0 0]);
                            set(handles.start_toggle,'value',0);
                            return
                        end
                        
                        %Let's update the lists, but we don't want change
                        %the active rat just yet
                        handles = update_lists(handles,get(handles.ratname_list,'value'));
                        
                        %Tell the user to remove the rat
                        set(handles.status_text,'string','Weighing Complete. Remove the rat.',...
                            'backgroundcolor',[0 1 0]);
                    end
                end
            end
        else         
            if foundstable == 1
                %The rat is off the scale, jump to the next
                
                %if the weight is similar to the last weight entry, let's
                %move on to the next unweighed rat, if not we should prompt
                %the user to reweight this rat
                oldmass = bdata(['select mass from ratinfo.mass where ratname="',...
                    ratname,'" and date<"',datestr(now,29),'"order by weighing desc']);
                
                if isempty(oldmass) ||...
                   abs((weight - oldmass(1)) / oldmass(1)) < handles.error / 100 ||...
                   doing_reweigh == 1
                    %Weight is within range, there was no previous entry, 
                    %or this is our second attempt at weighing this rat, 
                    %either way, let's move on 
                    handles = jump_to_empty(handles);
                    doing_reweigh = 0;
                else
                    %Weight is out of range, let's reweigh this rat once
                    %more, that requires us to delete the weight entry from
                    %MySQL and update the lists
                    handles = update_ratname(handles);
                    id = bdata(['select weighing from ratinfo.mass where date="',...
                        datestr(now,29),'" and ratname="',ratname,'"']);
                    if ~isempty(id); bdata('call bdata.delete_weighing("{Si}")',id); end
                    handles = update_lists(handles,get(handles.ratname_list,'value'));
                    doing_reweigh = 1;
                end
                foundstable = 0;
            end         
            M = []; 
        end
        
        %Let's pause for a bit so we take a reading at the desired rate
        pausetime = (1/handles.rate) - ((now-cyclestart)*24*3600);
        if pausetime > 0; pause(pausetime); end
    end
    
    set(handles.start_toggle,'backgroundcolor',[0 1 0],'string','Start');  
    set(handles.mass_text,'string','0');
end
guidata(hObject,handles);



% --- Executes on button press in edit_button.
function edit_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

set(handles.start_toggle,'value',0);
set(handles.mass_text,'style','edit');
set(handles.status_text,'string','Please enter the rat''s mass then click Enter',...
    'backgroundcolor',[1 1 1]);

%Pass the focus to the mass_text object so the user doesn't need to mouse
%click on it
uicontrol(handles.mass_text);

%Now we wait for the user to enter the weight.
while get(handles.mass_text,'value') == 0
    pause(0.2);
end
weight_entered = get(handles.mass_text,'value');
ratname = get(handles.ratname_text,'string');

try
    %If this rat has an entry for this day we need to delete it
    id = bdata(['select weighing from ratinfo.mass where date="',datestr(now,29),'" and ratname="',ratname,'"']);
    if ~isempty(id); bdata('call bdata.delete_weighing("{Si}")',id); end
    
    %Now we insert the new weight into the table
    bdata(['insert into ratinfo.mass set mass=',num2str(weight_entered),...
        ', date="',datestr(now,29),'", ratname="',ratname,'", tech="',...
        handles.active_user,'", timeval="',datestr(now,'HH:MM:SS'),'"']); 
catch %#ok<CTCH>
    set(handles.status_text,'string','ERROR: Unable to connect to network.',...
        'backgroundcolor',[1 0 0]);
end
    
%Revert the mass_text object back to a text style
set(handles.mass_text,'style','text','value',0,'string','0');
handles = update_lists(handles);
handles = jump_to_empty(handles);

guidata(hObject,handles);


% --- Executes on button press in mass_text
function mass_text_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

%Executes when the user is done entering the weight for the rat manually.
%It is used by the edit button callback to know when to break out of the
%loop
set(handles.mass_text,'value',str2num(get(handles.mass_text,'string'))); %#ok<ST2NM>
guidata(hObject,handles);


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

ratname = get(handles.ratname_text,'string');
try
    id = bdata(['select weighing from ratinfo.mass where date="',datestr(now,29),'" and ratname="',ratname,'"']);
    %Make a call to MySQL to remove the line
    bdata('call bdata.delete_weighing("{Si}")',id);
    
catch %#ok<CTCH>
    set(handles.status_text,'string','ERROR: Unable to connect to network.',...
        'backgroundcolor',[1 0 0]);
end
handles = update_lists(handles,get(handles.ratname_list,'value'));
handles = update_ratname(handles);
guidata(hObject,handles);


% --- Executes on button press in zero_button.
function zero_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

if ~isempty(handles.balance)
    try
        fprintf(handles.balance,'T');
        set(handles.mass_text,'string','0');
    catch %#ok<CTCH>
        set(handles.status_text,'string','ERROR: Can''t connect to balance',...
            'backgroundcolor',[1 0 0]);
    end
else
    set(handles.status_text,'string','ERROR: Can''t connect to balance',...
        'backgroundcolor',[1 0 0]);
end
guidata(hObject,handles);
    


% --- Executes on selection change in user_menu.
function user_menu_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles.active_user = handles.initials{get(handles.user_menu,'value')};
if ~isempty(handles.balance); set(handles.start_toggle,'enable','on'); end
guidata(hObject,handles);


% --- Executes on button press in plotmass_button.
function plotmass_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

set(handles.start_toggle,'value',0);

str = get(handles.ratname_list,'string');
rtn = get(handles.ratname_list,'value');
ratname = str{rtn}(1:4);

try
    plot_rat_mass(ratname);
catch %#ok<CTCH>
    set(handles.status_text,'string','ERROR: Unable to connect to network.',...
        'backgroundcolor',[1 0 0]);
    return;
end



% --- Executes on button press in settings_button.
function settings_button_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>

MassMeister_Properties;



% --- Executes during object creation, after setting all properties.
function session_list_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function ratname_list_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function user_menu_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles) %#ok<DEFNU,INUSL>

try %#ok<TRYNC>
    fclose(handles.balance);
end
delete(hObject);




