function varargout = ShiftChecker(varargin)
% SHIFTCHECKER M-file for ShiftChecker.fig
%      SHIFTCHECKER, by itself, creates a new SHIFTCHECKER or raises the existing
%      singleton*.
%
%      H = SHIFTCHECKER returns the handle to a new SHIFTCHECKER or the handle to
%      the existing singleton*.
%
%      SHIFTCHECKER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHIFTCHECKER.M with the given input arguments.
%
%      SHIFTCHECKER('Property','Value',...) creates a new SHIFTCHECKER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ShiftChecker_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ShiftChecker_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ShiftChecker

% Last Modified by GUIDE v2.5 25-Mar-2012 20:16:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ShiftChecker_OpeningFcn, ...
                   'gui_OutputFcn',  @ShiftChecker_OutputFcn, ...
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


% --- Executes just before ShiftChecker is made visible.
function ShiftChecker_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

set(handles.text1,'string',['Check shifts for: ',datestr(now,'mmm dd, yyyy')]);

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = ShiftChecker_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;



function edit_window_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit_window_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in morning_button.
function morning_button_Callback(hObject, eventdata, handles)
set(handles.edit_window,'string','Analyzing Shift. Please Wait...');
pause(0.1);

x = checkshift('morning',0);

if isempty(x.problems); tstr = 'No problems discovered for the morning shift.';
else                    tstr = [num2str(length(x.problems)-x.spacecount),' problems discovered for the morning shift.'];
end
set(handles.title_text,'string',tstr);

str = cell(0);
for i = 1:length(x.problems); str{end+1} = x.problems{i}; end
str{end+1} = ' ';
for i = 1:length(x.stats);    str{end+1} = x.stats{i};    end
str{end+1} = ' ';

set(handles.edit_window,'string',str);

% --- Executes on button press in evening_button.
function evening_button_Callback(hObject, eventdata, handles)
set(handles.edit_window,'string','Analyzing Shift. Please Wait...');
pause(0.1);

x = checkshift('evening',0);

if isempty(x.problems); tstr = 'No problems discovered for the evening shift.';
else                    tstr = [num2str(length(x.problems)-x.spacecount),' problems discovered for the evening shift.'];
end
set(handles.title_text,'string',tstr);

str = cell(0);
for i = 1:length(x.problems); str{end+1} = x.problems{i}; end
str{end+1} = ' ';
for i = 1:length(x.stats);    str{end+1} = x.stats{i};    end
str{end+1} = ' ';

set(handles.edit_window,'string',str);

