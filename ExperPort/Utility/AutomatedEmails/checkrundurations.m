function output = checkrundurations(startdate,enddate,excludesundays,dsp,varargin)

if nargin < 1; startdate = yearmonthday; end
if nargin < 2; enddate   = yearmonthday; end
if nargin < 3; excludesundays = 0;       end
if nargin < 4; dsp            = 1;       end

dt = changedate(startdate,-1);

cnt = 0;
while strcmp(dt,enddate) == 0
    dt = changedate(dt,1);
    DT = datestr(datenum(dt,'yymmdd'),29);
    if dsp == 1; disp(['Analyzing: ',DT]); end
    
    [rigs rats1 slots]    = bdata(['select rig, ratname, timeslot from ratinfo.schedule where date="',DT,'"']);
    [STs ETs rats2]       = bdata(['select starttime, endtime, ratname from sessions where sessiondate="',DT,'"']);
    [Wst Wet rats3 WTech] = bdata(['select starttime, stoptime, rat, tech from ratinfo.water where date="',DT,'"']);
    
    if excludesundays == 1 && strcmp(datestr(datenum(dt,'yymmdd'),'ddd'),'Sun'); 
        if dsp == 1; disp(['Skipping Sunday ',dt]); end 
        continue; 
    end

    cnt = cnt+1;

    StartTime  = zeros(max(rigs),6); StartTime(:)  = nan;
    EndTime    = zeros(max(rigs),6); EndTime(:)    = nan;
    TotalTime  = zeros(max(rigs),6); TotalTime(:)  = nan;
    
    WaterStart = zeros(max(rigs),6); WaterStart(:) = nan;
    WaterEnd   = zeros(max(rigs),6); WaterEnd(:)   = nan;
    WaterTotal = zeros(max(rigs),6); WaterTotal(:) = nan;
    WaterBreak = zeros(max(rigs),6); WaterBreak(:) = nan;
    
    TECH = cell(2,1);

    for slot = 1:6
        for rig = rigs'  
            temp = slots == slot & rigs == rig;
            if sum(temp) == 0; continue; end
            ratname = rats1{temp};
            if isempty(ratname); continue; end
            
            temp = strcmp(rats2,ratname) == 1;
            if sum(temp) == 0; continue; end
            Ts = STs{temp};
            Te = ETs{temp};
            
            d = timediff(Ts,Te,2);
            st = (str2num(Ts(1:2)) * 3600) + (str2num(Ts(4:5)) * 60) + str2num(Ts(7:8)); %#ok<ST2NM>
            et = (str2num(Te(1:2)) * 3600) + (str2num(Te(4:5)) * 60) + str2num(Te(7:8)); %#ok<ST2NM>
            
            StartTime(rig,slot) = st;
            EndTime(rig,slot)   = et;
            TotalTime(rig,slot) = d;
            
            if slot == 1 && isempty(TECH{1})
                tech = bdata(['select tech from ratinfo.mass where ratname="',ratname,'" and date="',DT,'"']);
                if ~isempty(tech) && ~isempty(tech{1}); TECH{1} = lower(tech{1}); end
            elseif slot == 5 && isempty(TECH{2})
                tech = bdata(['select tech from ratinfo.mass where ratname="',ratname,'" and date="',DT,'"']);
                if ~isempty(tech) && ~isempty(tech{1}); TECH{2} = lower(tech{1}); end
            end
            
            temp = strcmp(rats3,ratname);
            if sum(temp) == 0; continue; end
            Ws = Wst(temp); if length(Ws) > 1; Ws = findtime(Ws,'min'); else Ws = Ws{1}; end
            We = Wet(temp); if length(We) > 1; We = findtime(We,'max'); else We = We{1}; end
            
            if ~isempty(Ws) && ~isempty(We); 
                d = timediff(Ws,We,2); if d < 0; d = d + (3600 * 24); end; 
                wst = (str2num(Ws(1:2)) * 3600) + (str2num(Ws(4:5)) * 60) + str2num(Ws(7:8)); %#ok<ST2NM>
                wet = (str2num(We(1:2)) * 3600) + (str2num(We(4:5)) * 60) + str2num(We(7:8)); %#ok<ST2NM>
            else
                d = nan; wst = nan; wet = nan;
            end
            WaterStart(rig,slot) = wst;
            WaterEnd(  rig,slot) = wet;
            WaterTotal(rig,slot) = d;
            WaterBreak(rig,slot) = wst - et;
        end
    end
    
    st1 = nanmin(StartTime(:,1)) / 3600; st1m = num2str(floor((st1-floor(st1))*60));
    ed3 = nanmax(EndTime(  :,3)) / 3600; ed3m = num2str(ceil(( ed3-floor(ed3))*60));
    ew2 = nanmax(WaterEnd( :,2)) / 3600; 
    
    st4 = nanmin(StartTime(:,4)) / 3600; st4m = num2str(floor((st4-floor(st4))*60));
    ed6 = nanmax(EndTime(  :,6)) / 3600; ed6m = num2str(ceil(( ed6-floor(ed6))*60));
    ew6 = nanmax(WaterEnd( :,6)) / 3600; 
    
    output.morning.day{cnt} = DT;
    output.evening.day{cnt} = DT;
    
    output.morning.tech{cnt} = TECH{1};
    output.evening.tech{cnt} = TECH{2};
    
    if ew2 - ed3 > 2; endmorning = ed3; else endmorning =  max([ed3 ew2]); end
    output.morning.length(cnt) = endmorning     - st1; %in hours
    output.evening.length(cnt) = max([ed6 ew6]) - st4; %in hours
    
    if dsp == 1; disp(['Morning Session ',num2str(floor(st1)),':',st1m,' to ',num2str(floor(ed3)),':',ed3m]); end
    if dsp == 1; disp(['Evening Session ',num2str(floor(st4)),':',st4m,' to ',num2str(floor(ed6)),':',ed6m]); end
    
    average_length = nanmedian(TotalTime) / 60; %in minutes
    output.morning.average(cnt) = nanmean(average_length(1:3)); 
    output.evening.average(cnt) = nanmean(average_length(4:6));
    
    clawback = zeros(size(StartTime,1),3); clawback(:) = nan;
    clawback(:,1) = StartTime(:,2) - (StartTime(:,1) + 7200);
    clawback(:,2) = StartTime(:,3) - (StartTime(:,2) + 7200);
    clawback(:,3) = EndTime(:,3)   - (EndTime(:,2) + 7200);
    
    output.morning.clawback(cnt) = nanmedian(clawback(:)) / 60; %in minutes
    
    clawback = zeros(size(StartTime,1),3); clawback(:) = nan;
    clawback(:,1) = StartTime(:,5) - (StartTime(:,4) + 7200);
    clawback(:,2) = StartTime(:,6) - (StartTime(:,5) + 7200);
    clawback(:,3) = EndTime(:,6)   - (EndTime(:,5) + 7200);
    
    output.evening.clawback(cnt) = nanmedian(clawback(:)) / 60; %in minutes
    
    output.morning.water(cnt,:) = mode(WaterTotal(:,1:2)) / 3600;
    output.evening.water(cnt,:) = mode(WaterTotal(:,3:6)) / 3600;
    
    temp = WaterBreak(:,1) > 0;
    if sum(temp) > 0; output.morning.minbreak(cnt,1) = min(WaterBreak(temp,1)) / 60;
    else              output.morning.minbreak(cnt,1) = nan;
    end
    
    temp = WaterBreak(:,2) > 0;
    if sum(temp) > 0; output.morning.minbreak(cnt,2) = min(WaterBreak(temp,2)) / 60;
    else              output.morning.minbreak(cnt,2) = nan;
    end
        
    temp = WaterBreak(:,4) > 0;
    if sum(temp) > 0; output.evening.minbreak(cnt,1) = min(WaterBreak(temp,4)) / 60;
    else              output.evening.minbreak(cnt,1) = nan;
    end
    
    temp = WaterBreak(:,5) > 0;
    if sum(temp) > 0; output.evening.minbreak(cnt,2) = min(WaterBreak(temp,5)) / 60;
    else              output.evening.minbreak(cnt,2) = nan;
    end
        
    temp = WaterBreak(:,1:2);
    temp = temp(:) / 60;
    output.morning.goodbreak(cnt) = sum(temp > 30) / sum(~isnan(temp));
    output.morning.badbreak(cnt)  = nanmedian(temp(temp < 30));
    
    temp = WaterBreak(:,4:5);
    temp = temp(:) / 60;
    output.evening.goodbreak(cnt) = sum(temp > 30) / sum(~isnan(temp));
    output.evening.badbreak(cnt)  = nanmedian(temp(temp < 30));
    
    %output.morning.freewater{cnt} = '';
    freewatertemp = cell(0);
    for r = 1:length(rats3)
        if sum(strcmp(rats1,rats3{r})) == 0 && strcmp(Wst{r},Wet{r}) == 1 && ~strcmp(rats3{r},' ')
            %This is a free water rat that was confirmed via WaterMeister
            freewatertemp{end+1} = lower(WTech{r}); %#ok<AGROW>
            %output.morning.freewater{cnt} = WTech{r};
        end
    end
    UFW = unique(freewatertemp);
    if length(UFW) == 1;                        output.morning.freewater{cnt} = UFW{1}; 
    elseif sum(strcmp(UFW,lower(TECH{1}))) > 0; output.morning.freewater{cnt} = lower(TECH{1}); %#ok<STCI>
    else                                        output.morning.freewater{cnt} = UFW;
    end
    output.evening.freewater{cnt} = '';
            
    for i = 1:2
        if ~isfield(output,TECH{i})
            temp.day       = cell(0);
            temp.length    = [];
            temp.average   = [];
            temp.clawback  = [];
            temp.water     = [];
            temp.minbreak  = [];
            temp.goodbreak = [];
            temp.badbreak  = [];
            temp.freewater = cell(0);
            temp.totalmornings = 0;
            temp.freeconfirms  = 0;
            if ~isempty(TECH{i}); eval(['output.',TECH{i},' = temp;']); end
        end
    end
    
    if ~isempty(TECH{1});
        ltr = '_M'; %#ok<NASGU>
        eval(['output.',TECH{1},'.day{end+1}        = [output.morning.day{cnt},ltr];']);
        eval(['output.',TECH{1},'.length(end+1)     = output.morning.length(cnt);']);
        eval(['output.',TECH{1},'.average(end+1)    = output.morning.average(cnt);']);
        eval(['output.',TECH{1},'.clawback(end+1)   = output.morning.clawback(cnt);']);
        eval(['output.',TECH{1},'.water(end+1,1:2)  = output.morning.water(cnt,:);']);
        eval(['output.',TECH{1},'.minbreak(end+1,:) = output.morning.minbreak(cnt,:);']);
        eval(['output.',TECH{1},'.goodbreak(end+1)  = output.morning.goodbreak(cnt);']);
        eval(['output.',TECH{1},'.badbreak(end+1)   = output.morning.badbreak(cnt);']);
        eval(['output.',TECH{1},'.freewater{end+1}  = output.morning.freewater{cnt};']);
    end
    
    if ~isempty(TECH{2})
        ltr = '_E';  %#ok<NASGU>
        eval(['output.',TECH{2},'.day{end+1}        = [output.evening.day{cnt},ltr];']);
        eval(['output.',TECH{2},'.length(end+1)     = output.evening.length(cnt);']);
        eval(['output.',TECH{2},'.average(end+1)    = output.evening.average(cnt);']);
        eval(['output.',TECH{2},'.clawback(end+1)   = output.evening.clawback(cnt);']);
        eval(['output.',TECH{2},'.water(end+1,1:4)  = output.evening.water(cnt,:);']);
        eval(['output.',TECH{2},'.minbreak(end+1,:) = output.evening.minbreak(cnt,:);']);
        eval(['output.',TECH{2},'.goodbreak(end+1)  = output.evening.goodbreak(cnt);']);
        eval(['output.',TECH{2},'.badbreak(end+1)   = output.evening.badbreak(cnt);']);
        eval(['output.',TECH{2},'.freewater{end+1}  = output.evening.freewater{cnt};']);
    end
end

for i = 1:length(output.morning.tech)
    if isempty(output.morning.tech{i}); continue; end
    eval(['output.',output.morning.tech{i},'.totalmornings = output.',output.morning.tech{i},'.totalmornings + 1;']);
    if sum(strcmp(output.morning.tech{i},output.morning.freewater{i}))>0
        eval(['output.',output.morning.tech{i},'.freeconfirms = output.',output.morning.tech{i},'.freeconfirms + 1;']);
    end
end





function T = findtime(times,fun)

for i = 1:length(times)
    t(i) = datenum(times{i},'hh:mm:ss'); %#ok<NASGU,AGROW>
end

str = 'first'; %#ok<NASGU>
T = eval(['times{find(t == ',fun,'(t),1,str)}']);

