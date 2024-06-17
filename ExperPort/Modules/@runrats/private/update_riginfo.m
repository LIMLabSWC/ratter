function update_riginfo()
try
rigid=getRigID;

if isnan(rigid)
    fprintf(2,'This is not a rig, skipping update.\n');
    return;
end

[ip,ma,hn]=get_network_info;
[steMS errID errmsg] = ...
    bSettings('get','RIGS','state_machine_server'); 

 [vidS errID errmsg] = ...
    bSettings('get','RIGS','video_server_ip'); 
if isnan(vidS)
    vidS='';
end
bdata('call update_riginfo("{S}","{S}","{S}","{S}","{S}","{S}","{S}")',rigid,ip,steMS,ma,hn,isunix,vidS)
fprintf('Rig Info updated successfully.\nRig %d: IP=%s, MAC=%s, Hostname=%s\n',rigid,ip,ma,hn);
catch
    showerror
    fprintf(2,'Rig Info failed to update');
end

