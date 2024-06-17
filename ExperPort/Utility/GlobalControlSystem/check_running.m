function handles = check_running(handles)

[ratname rigname ended starttime sessiondate crashed] = bdata(['select ratname, hostname, was_ended, starttime, sessiondate, crashed',...
    ' from sess_started where sessiondate="',datestr(now,'yyyy-mm-dd'),'" order by sessid desc']);
[RATS RIGS STS EDS]   = bdata(['select ratname, hostname, starttime, endtime from sessions where sessiondate="',datestr(now,'yyyy-mm-dd'),'"']);
[ratS slot]           = bdata(['select ratname, timeslot from ratinfo.schedule where date="',datestr(now,29),'"']);
[ratM tech]           = bdata(['select ratname, tech from ratinfo.mass where date="',datestr(now,29),'"']);
[name,initials,email] = bdata('select experimenter, initials, email from ratinfo.contacts where is_alumni=0');
[rigid,isbroken]      = bdata('select rigid, isbroken from ratinfo.rig_maintenance order by broke_date desc');
[rigtr,ndt,perf]      = bdata('select rigid, n_done_trials, performance from ratinfo.rigtrials');
[ratR, owner]         = bdata('select ratname, contact from ratinfo.rats where extant=1');

allnames = get(handles.name_menu,'string');

rigbroken = zeros(size(handles.compnames,1),1);
for i = 1:size(handles.compnames,1)
    temp = find(rigid == i & isbroken == 1,1,'first');
    if isempty(temp); continue; end
    rigbroken(i) = isbroken(temp);
end

for i = 1:length(email); email{i} = email{i}(1:find(email{i}=='@')-1); end
pp = strcmp(name,allnames{get(handles.name_menu,'value')});
if sum(pp) == 1
    person = email{pp};
else
    person = '';
end

%Let's figure out what the rigs are doing
current_slot = [];
current_tech = cell(0);
startedat    = [];
for i = 1:length(handles.compnames)
    temp = find(strcmp(rigname,['Rig',sprintf('%02i',str2num(handles.compnames{i,2}))]) == 1,1,'first'); %#ok<ST2NM>
    
    if rigbroken(i) == 1
        set(eval(['handles.status',handles.compnames{i,2}]),'string','BROKEN',...
            'foregroundcolor',[1 0 0]);
        if get(handles.fix_button,'value') == 0
            set(eval(['handles.rig',handles.compnames{i,2}]),'value',1);
        end
            
    elseif isempty(temp) || ended(temp) == 1
        %Either no rats have started in this rig or the last rat to run was
        %ended.  If that rat ran for more than 1 minute we will mark the
        %rig as free.  If he ran less than 1 minute it might have been an
        %accidental double click, so let's notify the user of that.
        
        temp2 = find(strcmp(RIGS,['Rig',sprintf('%02i',str2num(handles.compnames{i,2}))]) == 1,1,'last'); %#ok<ST2NM>
        if ~isempty(temp2)
            if (datenum(EDS(temp2),'HH:MM:SS') - datenum(STS(temp2),'HH:MM:SS')) * 24 * 60 < 1
                set(eval(['handles.status',handles.compnames{i,2}]),'string','DOUBLE CLICK','foregroundcolor',[1 0 0]);
                continue;
            end
        end
        
        if sum(handles.ignore == i) > 0; continue; end
        
        if get(handles.fix_button,'value') == 0
            set(eval(['handles.rig',handles.compnames{i,2}]),'value',1);
        end
        set(eval(['handles.status',handles.compnames{i,2}]),'string','');
    else
        if get(handles.fix_button,'value') == 0
            set(eval(['handles.rig',handles.compnames{i,2}]),'value',0);
        end
        
        tempr  = strcmp(ratR,ratname{temp});
        if sum(tempr) == 1
            if ~isempty(person) && ~isempty(strfind(owner{tempr},person))
                weight = 'bold';
            else
                weight = 'normal';
            end
        end
        
        if crashed(temp) == 0
            temp2 = rigtr == str2num(handles.compnames{i,2}); %#ok<ST2NM>
            if sum(temp2) == 1
                p = round(perf(temp2)*100); if p < 0; p = 0; end
                set(eval(['handles.status',handles.compnames{i,2}]),'string',[ratname{temp},' ',...
                    sprintf('%4i',ndt(temp2)),' @',sprintf('%3i',p),'%'], 'foregroundcolor',[0 0.6 0.2],'fontweight',weight);
            else
                set(eval(['handles.status',handles.compnames{i,2}]),'string',['Running ',ratname{temp}],...
                    'foregroundcolor',[0 0.6 0.2],'fontweight',weight);
            end
            
            startedat(end+1) = datenum([sessiondate{temp},' ',starttime{temp}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>

            if sum(handles.ignore == i) > 0; continue; end
            tempS = find(strcmp(ratS,ratname{temp}) == 1,1,'first');
            if ~isempty(tempS); current_slot(end+1) = slot(tempS); end %#ok<AGROW>

            tempM = find(strcmp(ratM,ratname{temp}) == 1,1,'first');
            if ~isempty(tempM); current_tech{end+1} = tech{tempM}; end %#ok<AGROW>
        else
            set(eval(['handles.status',handles.compnames{i,2}]),'string',['Crashed ',ratname{temp}],...
                'foregroundcolor',[1 0 0],'fontweight',weight);
        end
        
    end
end

uCT = unique(current_tech); if isempty(uCT); uCT{1} = ''; end
if length(uCT) > 1
    for i=1:length(uCT); n(i) = sum(strcmp(current_tech,uCT{i})); end %#ok<AGROW>
    activetech_initials = uCT{find(n == max(n),1,'first')};
else
    activetech_initials = uCT;
end

tempC = find(strcmp(initials,activetech_initials) == 1,1,'first');
if ~isempty(tempC); activetech = name{tempC}; else activetech = 'I don''t know who'; end

if isempty(current_slot)
    %No one is running who is on the schedule, let's find the last session
    %that was finished
    comprats = ratname(ended==1);
    compslot = [];
    for i=1:length(comprats);
        tempS = find(strcmp(ratS,comprats{i})==1,1,'first');
        if ~isempty(tempS); compslot(end+1) = slot(tempS); end %#ok<AGROW>
    end
    
    sched = slot(~strcmp(ratS,''));
    completed = zeros(1,6);
    
    for i = 1:9
        if sum(compslot == i) / sum(sched == i) > 0.5; completed(i) = 1; end
    end
    lastcomp = find(completed == 1,1,'last');
    
    if isempty(lastcomp)
        str = 'Training has not yet started today.';
    else
        sess = ratS(slot == lastcomp);
        sess(strcmp(sess,'')) = [];
        last_tech = cell(0);
        for i = 1:length(sess);
            tempM = find(strcmp(ratM,sess{i}) == 1,1,'first');
            if ~isempty(tempM); last_tech{end+1} = tech{tempM}; end %#ok<AGROW>
        end

        uCT = unique(last_tech); if isempty(uCT); uCT{1} = ''; end
        if length(uCT) > 1
            for i=1:length(uCT); n(i) = sum(strcmp(last_tech,uCT{i})); end %#ok<AGROW>
            lasttech_initials = uCT{find(n == max(n),1,'first')};
        else
            lasttech_initials = uCT;
        end

        tempC = find(strcmp(initials,lasttech_initials) == 1,1,'first');
        if ~isempty(tempC); lasttech = name{tempC}; else lasttech = 'I don''t know who'; end

        str = [lasttech,' completed Session ',num2str(lastcomp)];
    end
else
    str = [activetech,' is running Session ',num2str(mode(current_slot)),...
        ' for ',num2str(round((now - mean(startedat)) * 24 * 60)),' minutes'];
end

set(handles.tech_session_text,'string',str);


%Now let's try to figure out what the tech computer is doing
weighing = 0;
watering = 0;

id = bdata(['select max(weighing) from ratinfo.mass where date="',datestr(now,'yyyy-mm-dd'),'"']);
if ~isnan(id)
    tm = bdata(['select timeval from ratinfo.mass where weighing=',num2str(id)]);
else
    tm = {};
end

if ~isempty(tm) && ((datenum(datestr(now,'HH:MM:SS'),'HH:MM:SS') - datenum(tm{1},'HH:MM:SS')) * 24 * 60) < 2
    %The last weighing was within the last 5 minutes
    weighing = 1;
end

id = bdata(['select max(watering) from ratinfo.water where date="',datestr(now,'yyyy-mm-dd'),'"']);
if ~isnan(id)
    st = bdata(['select starttime from ratinfo.water where watering=',num2str(id)]);
else
    st = {};
end

if ~isempty(st) && ((datenum(datestr(now,'HH:MM:SS'),'HH:MM:SS') - datenum(st{1},'HH:MM:SS')) * 24 * 60) <= 60
    %Watering has started within the last 65 minutes
    watering = 1;
end

if     weighing == 1 && watering == 1; message = 'Weighing and Watering Rats';
elseif weighing == 1 && watering == 0; message = 'Weighing Rats';
elseif weighing == 0 && watering == 1; message = 'Watering Rats';
elseif weighing == 0 && watering == 0; message = '';
end

set(handles.status31,'string',message,'foregroundcolor',[0 0 0]);

handles.lastrefresh = now;




