function handles = TN_submit(handles)

dstr = get(handles.date_text,'string');
tstr = datestr(now,13);

initials = lower(handles.initials{get(handles.name_menu,'value')});
note = get(handles.note_edit,'string');
if isempty(note); return; end
if get(handles.rat_button,'value') == 1
    
    for i = 1:length(handles.active);
        ratname = handles.active{i};
        bdata('INSERT INTO ratinfo.technotes (datestr, timestr, ratname, techinitials, note) values ("{S}","{S}","{S}","{S}","{S}")',...
            dstr,tstr,ratname,initials,note);
    end
    
elseif get(handles.rig_button,'value') == 1 || get(handles.tower_button,'value') == 1
    
    isbroken = questdlg({'Is this rig broken?','Clicking YES will disable runrats',...
        'preventing anyone from running rats on that rig.'},'','Yes','No','No');
    if strcmp(isbroken,'Yes')
        names = get(handles.name_menu,'string');
        name  = names{get(handles.name_menu,'value')};
        if strcmp(name,''); name = 'unknown'; end
    end
    
    for i = 1:length(handles.active);
        R = handles.active{i};
        if ischar(R); R(R == ',') = ' '; R = str2num(R); end %#ok<ST2NM>
        
        for r = 1:length(R);
            bdata('INSERT INTO ratinfo.technotes (datestr, timestr, rigid, techinitials, note) values ("{S}","{S}","{S}","{S}","{S}")',...
                dstr,tstr,R(r),initials,note);
            
            if strcmp(isbroken,'Yes')
                bdata(['insert into ratinfo.rig_maintenance set rigid=',num2str(R(r)),', note="',note,'", isbroken=1, broke_person="',...
                    name,'", broke_date="',datestr(now,'yyyy-mm-dd HH:MM'),'"']);
            end
        end
    end
    
elseif get(handles.session_button,'value') == 1
    
    for i = 1:length(handles.active);
        S = handles.active{i};
        bdata('INSERT INTO ratinfo.technotes (datestr, timestr, timeslot, techinitials, note) values ("{S}","{S}","{S}","{S}","{S}")',...
            dstr,tstr,S,initials,note);
    end
    
elseif get(handles.experimenter_button,'value') == 1
    
    for i = 1:length(handles.active);
        EXP = handles.active{i};
        bdata('INSERT INTO ratinfo.technotes (datestr, timestr, experimenter, techinitials, note) values ("{S}","{S}","{S}","{S}","{S}")',...
            dstr,tstr,EXP,initials,note);
    end
    
else
    bdata('INSERT INTO ratinfo.technotes (datestr, timestr, techinitials, note) values ("{S}","{S}","{S}","{S}")',...
        dstr,tstr,initials,note);
end

set(handles.submit_button,'enable','off');