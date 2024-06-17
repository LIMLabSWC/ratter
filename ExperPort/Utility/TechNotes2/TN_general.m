function handles = TN_general(handles)

handles = TN_clear(handles);

set(handles.rat_button,'value',0);
set(handles.rig_button,'value',0);
set(handles.tower_button,'value',0);
set(handles.session_button,'value',0);
set(handles.experimenter_button,'value',0);

set(handles.active_text,'string','General Issue');
