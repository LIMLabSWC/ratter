function start_camera = start_camera(rig_id,rat_id,protocol,flag)
% Initialiase table for camera IP addresses. Camera for Rig 1 = ips(1)
ips ={ 
    '172.24.155.101',
    '172.24.155.102',
    '172.24.155.103',
    '172.24.155.104',
    '172.24.155.105',
    '172.24.155.106',
    '172.24.155.107',
    '172.24.155.108',
    '172.24.155.109',
    '172.24.155.110',
    '172.24.155.111',
    '172.24.155.112',
    '172.24.155.113',
    '172.24.155.114',
    '172.24.155.115',
    '172.24.155.116',
    '172.24.155.117',
    '172.24.155.118',
    '172.24.155.119',
    '172.24.155.120'
    };
rig_camIP = ips{rig_id};
if strcmp(flag,'start')    
    filename = [rat_id,'_',datestr(date,'yymmdd')];
    disp('created filename')
    command_string = ['plink.exe -ssh pi@',rig_camIP,' -pw raspberry cd Pi_camera; python3 streamnrecord.py ', ' ',filename,' ',rat_id,' ',protocol,' "COMMAND >/dev/null &"']; 
    system(command_string);
    disp('sent starting command')

elseif strcmp(flag,'stop')
    command_string = ['plink.exe -ssh pi@',rig_camIP,' -pw raspberry pkill -9 python3'];
    system(command_string);
    disp('sent stopping command')
end
end