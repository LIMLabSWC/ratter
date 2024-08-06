function varargout = GlobalControlSystem(varargin)
% GLOBALCONTROLSYSTEM M-file for GlobalControlSystem.fig
%      GLOBALCONTROLSYSTEM, by itself, creates a new GLOBALCONTROLSYSTEM or raises the existing
%      singleton*.
%
%      H = GLOBALCONTROLSYSTEM returns the handle to a new GLOBALCONTROLSYSTEM or the handle to
%      the existing singleton*.
%
%      GLOBALCONTROLSYSTEM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GLOBALCONTROLSYSTEM.M with the given input arguments.
%
%      GLOBALCONTROLSYSTEM('Property','Value',...) creates a new GLOBALCONTROLSYSTEM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GlobalControlSystem_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GlobalControlSystem_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GlobalControlSystem

% Last Modified by GUIDE v2.5 27-Sep-2012 22:07:48
%
% Created by Chuck 2011

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GlobalControlSystem_OpeningFcn, ...
                   'gui_OutputFcn',  @GlobalControlSystem_OutputFcn, ...
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


% --- Executes just before GlobalControlSystem is made visible.
function GlobalControlSystem_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>

set(double(gcf),'name','GlobalControlSystem V2.1');

handles.output = hObject;
handles.lastrefresh = 0;
handles.goodpassword = 0;

[names initials] = bdata('select experimenter, initials from ratinfo.contacts where is_alumni=0 order by experimenter');
set(handles.name_menu,'string',{'Select Name',names{:}});

handles.initials  = {'',initials{:}};
handles.compnames = get_compnames;
handles.ignore    = [5,6];                 
                 
handles = check_running(handles);                 
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = GlobalControlSystem_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>

varargout{1} = handles.output;


% --- Executes on button press in bcg_button.
function bcg_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'bcg');
guidata(hObject,handles);


% --- Executes on button press in runrats_button.
function runrats_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'runrats');
guidata(hObject,handles);


% --- Executes on button press in computers_button.
function computers_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'reboot');
guidata(hObject,handles);


% --- Executes on button press in pokesplot_button.
function pokesplot_button_Callback(hObject, eventdata, handles)



% --- Executes on button press in message_button.
function message_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'message');
guidata(hObject,handles);


% --- Executes on button press in update_button.
function update_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'update');
guidata(hObject,handles);


% --- Executes on button press in runscript_button.
function runscript_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = send_job(handles,'run');
guidata(hObject,handles);


% --- Executes on selection change in name_menu.
function name_menu_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
    
handles = activate_buttons(handles);
handles = check_running(handles);
guidata(hObject,handles);


function password_edit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = activate_buttons(handles);
guidata(hObject,handles);


% --- Executes on button press in read_button.
function read_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

answer = questdlg('Select Date of Message','','Today','Yesterday','Enter Date','Today');

if     strcmp(answer,'Today');     D = datestr(now,  'yyyy-mm-dd');
elseif strcmp(answer,'Yesterday'); D = datestr(now-1,'yyyy-mm-dd');
else D = inputdlg('Please enter the date as yyyy-mm-dd','',1,{''}); D = D{1};
end

names = get(handles.name_menu,'string');
name = names{get(handles.name_menu,'value')};
if strcmp(name,'Select Name'); msgbox('Please select you name before trying to read messages.'); return; end

IN = bdata(['select initials from ratinfo.contacts where experimenter="',name,'"']);

[M R T C F] = bdata(['select message, received, rectime, computer_name, failed from gcs where initials="',...
    IN{1},'" and dateval like "',D,'%" and job="message"']);

if isempty(M);
    msgbox(['You posted no message on ',D]);
    return;
end

for i = 1:length(M);
    temp = find(strcmp(handles.compnames(:,1),C{i}) == 1,1,'first');
    if isempty(temp); continue; end
    rig = handles.compnames{temp,2};
    if strcmp(rig,'31'); rig = 'Tech Computer'; end
    if strcmp(T{i},'0000-00-00 00:00:00'); T{i} = 'Message NOT Received'; end
    if F(i) == 1;                          T{i} = 'Message Never Posted'; end
    
    GCS_Message({rig,str2num(char(M{i}')),T{i}}); %#ok<ST2NM>
    pause(0.1);
end



% --- Executes on button press in viewrig_button.
function viewrig_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

for i = 1:length(handles.compnames)
    if get(eval(['handles.rig',handles.compnames{i,2}]),'value') == 1
        system(['start http://',handles.compnames{i,3},':5800/']);
        pause(0.1);
    end
end


% --- Executes on button press in fix_button.
function fix_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

if get(handles.fix_button,'value') == 1
    set(handles.fix_button,'string','Select Free');
else
    set(handles.fix_button,'string','Fix Choice');
    handles = check_running(handles);
end
guidata(hObject,handles);


% --- Executes on button press in all_button.
function all_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

if get(handles.all_button,'value') == 0
    set(handles.all_button,'string','Unselect All')
    
    showwarn = 0;
    for i = 1:length(handles.compnames)
        if sum(handles.ignore == i) > 0; continue; end
        set(eval(['handles.rig',handles.compnames{i,2}]),'value',1);
        str = get(eval(['handles.status',handles.compnames{i,2}]),'string');
        if length(str) > 7 && strcmp(str(1:7),'Running')
            showwarn = 1;
        end
    end
    if showwarn == 1
        warndlg('WARNING: You have selected a rig that appears to be running a rat!','','modal');
    end
    
else
    set(handles.all_button,'string','Select All')
    for i = 1:length(handles.compnames)
        set(eval(['handles.rig',handles.compnames{i,2}]),'value',0);
    end
end
    
guidata(hObject,handles);


% --- Executes on button press in refresh_button.
function refresh_button_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

handles = check_running(handles);
guidata(hObject,handles);


% --- Executes on button press in live_toggle.
function live_toggle_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

try %#ok<TRYNC>
    if get(handles.live_toggle,'value') == 1
        %Let's update the system in real time

        set(handles.live_toggle,'string','Pause','backgroundcolor',[1 0 0]);

        while get(handles.live_toggle,'value') == 1
            %We will continue to loop while the button is on
            tempstart = now;

            handles = check_running(handles);
            guidata(hObject,handles);

            %Puase such that we do 1 update every 10 seconds
            pause(10 - ((now - tempstart)*3600 * 24));
        end
        set(handles.live_toggle,'string','Go Live','backgroundcolor',[0 1 0]);

    else
        set(handles.live_toggle,'string','Go Live','backgroundcolor',[0 1 0]);
    end
    guidata(hObject,handles);  
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>

set(handles.live_toggle,'value',0);
delete(hObject);


% --- Executes during object creation, after setting all properties.
function name_menu_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rig1.
function rig1_Callback(hObject, eventdata, handles)
handles = warn_running(handles,1);
guidata(hObject,handles);


% --- Executes on button press in rig2.
function rig2_Callback(hObject, eventdata, handles)
handles = warn_running(handles,2);
guidata(hObject,handles);


% --- Executes on button press in rig3.
function rig3_Callback(hObject, eventdata, handles)
handles = warn_running(handles,3);
guidata(hObject,handles);


% --- Executes on button press in rig4.
function rig4_Callback(hObject, eventdata, handles)
handles = warn_running(handles,4);
guidata(hObject,handles);



% --- Executes on button press in rig5.
function rig5_Callback(hObject, eventdata, handles)


% --- Executes on button press in rig6.
function rig6_Callback(hObject, eventdata, handles)


% --- Executes on button press in rig7.
function rig7_Callback(hObject, eventdata, handles)
handles = warn_running(handles,7);
guidata(hObject,handles);


% --- Executes on button press in rig8.
function rig8_Callback(hObject, eventdata, handles)
handles = warn_running(handles,8);
guidata(hObject,handles);


% --- Executes on button press in rig9.
function rig9_Callback(hObject, eventdata, handles)
handles = warn_running(handles,9);
guidata(hObject,handles);


% --- Executes on button press in rig10.
function rig10_Callback(hObject, eventdata, handles)
handles = warn_running(handles,10);
guidata(hObject,handles);


% --- Executes on button press in rig11.
function rig11_Callback(hObject, eventdata, handles)
handles = warn_running(handles,11);
guidata(hObject,handles);


% --- Executes on button press in rig12.
function rig12_Callback(hObject, eventdata, handles)
handles = warn_running(handles,12);
guidata(hObject,handles);


% --- Executes on button press in rig13.
function rig13_Callback(hObject, eventdata, handles)
handles = warn_running(handles,13);
guidata(hObject,handles);


% --- Executes on button press in rig14.
function rig14_Callback(hObject, eventdata, handles)
handles = warn_running(handles,14);
guidata(hObject,handles);


% --- Executes on button press in rig15.
function rig15_Callback(hObject, eventdata, handles)
handles = warn_running(handles,15);
guidata(hObject,handles);


% --- Executes on button press in rig16.
function rig16_Callback(hObject, eventdata, handles)
handles = warn_running(handles,16);
guidata(hObject,handles);


% --- Executes on button press in rig17.
function rig17_Callback(hObject, eventdata, handles)
handles = warn_running(handles,17);
guidata(hObject,handles);


% --- Executes on button press in rig18.
function rig18_Callback(hObject, eventdata, handles)
handles = warn_running(handles,18);
guidata(hObject,handles);


% --- Executes on button press in rig19.
function rig19_Callback(hObject, eventdata, handles)
handles = warn_running(handles,19);
guidata(hObject,handles);


% --- Executes on button press in rig20.
function rig20_Callback(hObject, eventdata, handles)
handles = warn_running(handles,20);
guidata(hObject,handles);


% --- Executes on button press in rig21.
function rig21_Callback(hObject, eventdata, handles)
handles = warn_running(handles,21);
guidata(hObject,handles);


% --- Executes on button press in rig22.
function rig22_Callback(hObject, eventdata, handles)
handles = warn_running(handles,22);
guidata(hObject,handles);


% --- Executes on button press in rig23.
function rig23_Callback(hObject, eventdata, handles)
handles = warn_running(handles,23);
guidata(hObject,handles);


% --- Executes on button press in rig24.
function rig24_Callback(hObject, eventdata, handles)
handles = warn_running(handles,24);
guidata(hObject,handles);


% --- Executes on button press in rig25.
function rig25_Callback(hObject, eventdata, handles)
handles = warn_running(handles,25);
guidata(hObject,handles);


% --- Executes on button press in rig26.
function rig26_Callback(hObject, eventdata, handles)
handles = warn_running(handles,26);
guidata(hObject,handles);


% --- Executes on button press in rig27.
function rig27_Callback(hObject, eventdata, handles)
handles = warn_running(handles,27);
guidata(hObject,handles);


% --- Executes on button press in rig28.
function rig28_Callback(hObject, eventdata, handles)
handles = warn_running(handles,28);
guidata(hObject,handles);


% --- Executes on button press in rig29.
function rig29_Callback(hObject, eventdata, handles)
handles = warn_running(handles,29);
guidata(hObject,handles);


% --- Executes on button press in rig30.
function rig30_Callback(hObject, eventdata, handles)
handles = warn_running(handles,30);
guidata(hObject,handles);


% --- Executes on button press in rig31.
function rig31_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function password_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





