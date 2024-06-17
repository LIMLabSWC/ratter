function output = checkshift(shift,dsp,varargin)

if nargin < 2; dsp = 1; end

WR = bdata(['select rat from ratinfo.water where date="',datestr(now,'yyyy-mm-dd'),'"']);
[SR TS RG] = bdata(['select ratname, timeslot, rig from ratinfo.schedule where date="',datestr(now,'yyyy-mm-dd'),'"']);
[SST SED SRT SRG] = bdata(['select starttime, endtime, ratname, hostname from sessions where sessiondate="',datestr(now,'yyyy-mm-dd'),'"']);
[TNN TNR TNG TNS] = bdata(['select note, ratname, rigid, timeslot from ratinfo.technotes where datestr="',datestr(now,'yyyy-mm-dd'),'"']);

[rigid,isbroken] = bdata('select rigid, isbroken from ratinfo.rig_maintenance order by broke_date desc');

rigbroken = zeros(30,1);
for i = 1:30
    temp = find(rigid == i,1,'first');
    if isempty(temp); continue; end
    rigbroken(i) = isbroken(temp);
end

srg = [];
for i = 1:length(SRG);
    if length(SRG{i}) > 3; srg(i) = str2num(SRG{i}(4:end)); end
end
SRG = srg;

for i = 1:30
    temp = check_calibration(i);
    if isnan(temp); lc(i) = Inf; continue; end %#ok<AGROW>
    lc(i) = now - datenum(temp,'yyyy-mm-dd'); %#ok<AGROW>
end

missingmass = checkratweights(1);
if strcmp(shift,'morning'); MM = missingmass.morning;
else                        MM = missingmass.evening;
end

WL = WM_rat_water_list([],[],'all',datestr(now,'yyyy-mm-dd'),1);
if strcmp(shift,'morning'); ws = 1:2; s = 1:3;
else                        ws = 3:6; s = 4:6;
end

SW = ones(1,6);
MW = cell(0);
for i = ws
    R = unique(WL{i}(:));
    R(strcmp(R,'')) = [];
    mwc = 0;
    
    for j = 1:length(R)
        if sum(strcmp(WR,R{j})) == 0
            mwc = mwc + 1;
            MW{end+1} = R{j};
        end
    end
    if mwc > length(R)/2; SW(i) = 0; end
end

R = unique(WL{7}(:));
R(strcmp(R,'')) = [];
mfwc = 0;
for j = 1:length(R)
    if sum(strcmp(WR,R{j})) == 0
        mfwc = mfwc + 1;
    end
end
if mfwc > length(R)/2; FreeWaterChecked = 0; 
else                   FreeWaterChecked = 1;
end

MT = cell(0);
WR = cell(0);
RS = cell(0);
ST = ones(1,6);
RF = ones(1,6);

for i = s
    R = SR(TS == i);
    G = RG(TS == i);
    bad = strcmp(R,'');
    R(bad) = [];
    G(bad) = [];
    mrtc = 0;
    rsc  = 0;
    
    for j = 1:length(R)
        temp = strcmp(SRT,R{j});
        if sum(temp) == 0
            mrtc = mrtc + 1;
            MT{end+1} = R{j};
        else
            realrig = SRG(temp);
            if all(realrig ~= G(j))
                WR{end+1} = R{j};
            end
            
            st = SST(temp);
            ed = SED(temp);
            dur = 0;
            for k = 1:length(st)
                dur = dur + (datenum(ed{k}) - datenum(st{k}));
            end
            if dur * 24 < 1
                rsc = rsc + 1;
                RS{end+1} = R{j}; 
            end
                
        end
    end
    
    if rsc  > length(R)/2; RF(i) = 0; end
    if mrtc > length(R)/2; ST(i) = 0; end
end

MM = unique(MM);
MW = unique(MW);
MT = unique(MT);
WR = unique(WR);
RS = unique(RS);

RatWRigTN = cell(0);
for i = 1:length(TNG)
    temp = SR(RG == TNG(i));
    temp(strcmp(temp,'')) = [];
    RatWRigTN(end+1:end+length(temp)) =  temp;
end
for i = 1:30
    if rigbroken(i) == 1
        temp = SR(RG == i);
        temp(strcmp(temp,'')) = [];
        RatWRigTN(end+1:end+length(temp)) =  temp;
    end
end

RatWSesTN = cell(0);
for i = 1:length(TNS)
    temp = SR(TS == TNS(i));
    temp(strcmp(temp,'')) = [];
    RatWSesTN(end+1:end+length(temp)) =  temp;
end
    
P = cell(0); 
spacecount = 0;

addspace = 0;
if strcmp(shift,'morning')
    if FreeWaterChecked == 0; addspace = 1; P{end+1} = 'Free Water rats not checked.'; end
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = s
    if any(TNS == i); X = ''; else X = 'NO TECH NOTE'; end
    if SW(i) == 0; addspace = 1; P{end+1} = ['Session ',num2str(i),' was not watered. ',X]; end
    if ST(i) == 0; addspace = 1; P{end+1} = ['Session ',num2str(i),' was not trained. ',X]; end
    if RF(i) == 0; addspace = 1; P{end+1} = ['Session ',num2str(i),' ran less than 1 hour. ',X]; end
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = 1:30
    if lc(i) > 15; addspace = 1; P{end+1} = ['Rig ',num2str(i),' needs calibration.']; end
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end  

addspace = 0;
for i = 1:length(MM)
    if sum(strcmp(TNR,MM{i})) > 0 || sum(strcmp(RatWSesTN,MM{i})) > 0; X = ''; else X = 'NO TECH NOTE'; end
    P{end+1} = [MM{i},' was not weighed. ',X];
    addspace = 1;
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = 1:length(MW)
    if sum(strcmp(TNR,MW{i})) > 0 || sum(strcmp(RatWSesTN,MW{i})) > 0; X = ''; else X = 'NO TECH NOTE'; end
    P{end+1} = [MW{i},' was not watered. ',X];
    addspace = 1;
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = 1:length(MT)
    if sum(strcmp(TNR,MT{i})) > 0 || sum(strcmp(RatWSesTN,MT{i})) > 0; X = ''; else X = 'NO TECH NOTE'; end
    P{end+1} = [MT{i},' was not trained. ',X];
    addspace = 1;
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = 1:length(WR)
    if sum(strcmp(TNR,WR{i})) > 0 || sum(strcmp(RatWRigTN,WR{i})) > 0; X = ''; else X = 'NO TECH NOTE'; end
    P{end+1} = [WR{i},' trained in the wrong rig. ',X];
    addspace = 1;
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

addspace = 0;
for i = 1:length(RS)
    if sum(strcmp(TNR,RS{i})) > 0  || sum(strcmp(RatWSesTN,RS{i})) > 0; X = ''; else X = 'NO TECH NOTE'; end
    P{end+1} = [RS{i},' trained for less than 1 hour. ',X];
    addspace = 1;
end
if addspace == 1; P{end+1} = ' '; spacecount = spacecount + 1; end

if dsp == 1
    if isempty(P)
        disp(['No problems discovered for the ',shift,' shift.']);
    else
        disp([num2str(length(P)-spacecount),' problems discovered for the ',shift,' shift.']);
        disp(' ');
        for i = 1:length(P)
            disp(P{i}); 
        end
    end
    disp(' ');
end


x = checkrundurations(yearmonthday,yearmonthday,0,0); %#ok<NASGU>
z = eval(['x.',shift]);

S{1} = ['Shift duration:    ',num2str(floor(z.length)), ' hours   ',num2str(round((z.length-floor(z.length))*60)),' minutes'];
S{2} = ['Average Training: ',num2str(floor(z.average)), ' minutes ',num2str(round((z.average-floor(z.average))*60)),' seconds'];
S{3} = ['Average Clawback: ',num2str(floor(z.clawback)),' minutes ',num2str(round((z.clawback-floor(z.clawback))*60)),' seconds'];

if dsp == 1;
    for i = 1:length(S);
        disp(S{i});
    end
end

output.problems = P;
output.stats    = S;
output.spacecount = spacecount;
    
    