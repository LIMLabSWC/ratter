function port_watercal = port_watercal()
for vID = 1:3
IP = get_network_info;
format_fname = 'W:\\rat_cals\\Rig%s_valve%d_cal.csv';
cal_fname = sprintf(format_fname,IP(end-1:end),vID);
if exist(cal_fname,'file')
bonsai_cal =  csvread(cal_fname,0,0);
lcal_fname = 'C:\\Users\\Akrami Lab\\bpod\\Bpod Local\\Calibration Files\\LiquidCalibration.mat';
load(lcal_fname,'LiquidCal');
valveTimes = bonsai_cal(:,2)*1000; % convert S to ms
pulseMass = bonsai_cal(:,4)*1000; % convert g to micrograms

LiquidCal(vID).Table = [valveTimes,pulseMass];
LiquidCal(vID).Coeffs = polyfit(LiquidCal(vID).Table(:,2),LiquidCal(vID).Table(:,1),2);

save(lcal_fname,'LiquidCal');
end
end
