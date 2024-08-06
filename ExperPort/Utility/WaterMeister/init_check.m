function handles = init_check(handles)

global comp

oldname = get(double(gcf),'name');
set(double(gcf),'name','Updating');
pause(0.1);

handles.starttime = zeros(1,10); handles.starttime(:) = nan;
handles.start     = zeros(1,10);
comp              = zeros(1,10);

RatList = WM_rat_water_list(1,handles,'all',datestr(now,'yyyy-mm-dd'),1);
date_temp = datestr(now,'yyyy-mm-dd');    

[all_rats, all_strt, all_stop]=bdata(['select rat, starttime, stoptime from ratinfo.water where date = "',date_temp,'"']); 
[yes_rats, yes_strt, yes_stop]=bdata(['select rat, starttime, stoptime from ratinfo.water where date = "',datestr(now-1,'yyyy-mm-dd'),'"']);

for s = 1:10
    if s < 10
        disp(['Importing Data for Session ',num2str(s),'...']);
    else
        disp('Importing Data for Free Water Rats...');
    end
    ratnames = unique(RatList{s}(:));
    ratnames(strcmp(ratnames,'')) = [];
    
    STRT = cell(0); STP = cell(0);
    for r = 1:length(ratnames)
        if sum(strcmp(all_rats,ratnames{r})) > 0
            STRT{r} = all_strt{find(strcmp(all_rats,ratnames{r})==1,1,'first')};
            STP{r}  = all_stop{find(strcmp(all_rats,ratnames{r})==1,1,'first')};
        else
            STRT{r} = '';
            STP{r}  = '';
        end
    end
    
    strt = unique(STRT);
    stp  = unique(STP);
    
    if length(strt) == 1 && ~isempty(strt{1})
        handles.starttime(s) = datenum([date_temp,' ',strt{1}]);
    elseif length(strt) > 1
        S = [];
        for i=1:length(strt)
            S(i)=sum(strcmp(STRT,strt{i})); %#ok<AGROW>
        end
        con_strt = strt{find(S == max(S),1,'first')};
        if ~isempty(con_strt)
            handles.starttime(s) = datenum([date_temp,' ',con_strt]);
        end
    end
    
    if length(stp) == 1 && ~isempty(stp{1}) &&...
            ((s~=10 && ~strcmp(strt{1},stp{1})) || (s==10 && strcmp(strt{1},stp{1})))
        comp(s) = 1;
    elseif length(stp) > 1
        S = [];
        for i=1:length(stp)
            S(i)=sum(strcmp(STP,stp{i})); %#ok<AGROW>
        end
        con_stp = stp{find(S == max(S),1,'first')};
        if ~isempty(con_stp)
            comp(s) = 1;
        end
    end 
    
    %If the session is not completed but it got water with the past 12
    %hours it should continue to be marked as completed
    if comp(s) == 0 && ~isempty(ratnames)
        STP = cell(0);
        for r = 1:length(ratnames)
            if sum(strcmp(yes_rats,ratnames{r})) > 0
                STP{r} = yes_stop{find(strcmp(yes_rats,ratnames{r})==1,1,'first')};
            else
                STP{r}  = '';
            end
        end
        stp  = unique(STP);    
        if isempty(stp); continue; end
        
        for i = 1:length(stp)
            try    lastwater(i) = (now - datenum([datestr(now-1,'yyyy-mm-dd'),' ',stp{i}],'yyyy-mm-dd HH:MM:SS')) * 24; %#ok<AGROW>
            catch; lastwater(i) = 24; %#ok<CTCH,AGROW>
            end
        end
        lastwater = max(lastwater);
        
        disp(['Last watered ',num2str(lastwater),' hours ago.']);
        if ~isempty(stp) && lastwater < 12
            comp(s) = 1;
        end
    else
        comp(s) = 1;
    end
    
    str1 = 'BackgroundColor'; %#ok<NASGU>
    if comp(s) == 1
        eval(['set(handles.session',num2str(s),'_toggle,str1,[0 1 1]);']);
    elseif ~isnan(handles.starttime(s))
        eval(['set(handles.session',num2str(s),'_toggle,str1,[1 1 0]);']);
        handles.start(s) = 1;
    else
        eval(['set(handles.session',num2str(s),'_toggle,str1,[1 1 1]);']);
    end
end

set(handles.date_text,'string',datestr(now,29));
handles.lastupdate = now;

set(double(gcf),'name',oldname);

