function handles = update_xlim(handles)

tv = get(handles.time_menu,'value');
if tv == 1; d = 7;
elseif tv == 2; d = 14;
elseif tv == 3; d = 31;
elseif tv == 4; d = 92;
elseif tv == 5; d = 183;
elseif tv == 6; d = 365;
elseif tv == 7; d = 730;
elseif tv == 8; d = 1826;
end
set(double(gca),'xlim',[now-d,now]); 

%ylm = get(double(gca),'ylim');
%set(double(gca),'ylim',[ylm(1)-10,ylm(2)+10]);