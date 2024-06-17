function handles = update_ratname(handles)

str = get(handles.ratname_list,'string');
rtn = get(handles.ratname_list,'value');

if isempty(str) || rtn == 0; return; end
temp = str{rtn};

ratname = temp(1:4);
mass = str2num(temp(end-4:end)); %#ok<ST2NM>
if strcmp(temp(end-4:end),'New!!'); newrat = 1; else newrat=0; end

ratpos = find(handles.rattag == ratname(1),1,'first');
if ~isempty(ratpos); ratclr = handles.colors(ratpos,:);
else                 ratclr = [1 1 1];
end

set(handles.colorbar1,'backgroundcolor',ratclr);
set(handles.colorbar2,'backgroundcolor',ratclr);


set(handles.ratname_text,'string',ratname);
if ~isempty(mass)
    set(handles.status_text,'string','Place the rat on the scale to reweigh',...
        'backgroundcolor',[1 0.6 0.8]);
else
    if newrat == 1
        set(handles.status_text,'string','CAREFUL, New rat! Place on the scale.',...
            'backgroundcolor',[1 1 0]);
    else
        set(handles.status_text,'string','Place the rat on the scale.',...
            'backgroundcolor',[1 1 1]);
    end
end
