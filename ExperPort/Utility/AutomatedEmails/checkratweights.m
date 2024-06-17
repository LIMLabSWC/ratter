function output = checkratweights(find_missing,varargin)

try 
    
    if nargin == 0; find_missing = 0; end
    
    istodaysunday = strcmp(datestr(now,'ddd'),'Sun');
    
    setpref('Internet','SMTP_Server','sonnabend.princeton.edu');
    setpref('Internet','E_mail','MassMeister@Princeton.EDU');

    [ratnames1, forcefrees, forcedeps, recoverings, cagemates, contacts] =...
        bdata('select ratname, forcefreewater, forcedepwater, recovering, cagemate, contact from ratinfo.rats where extant=1');
    [training, slots] = bdata('select ratname, timeslot from ratinfo.schedule where date="{S}"',datestr(now,29));
        
    norats = strcmp(training,'');
    training(norats) = [];
    slots(norats) = [];
    recov = ratnames1(recoverings==1);
    
    weighedrats = training;
    for r=1:length(training)
        temp = strcmp(ratnames1,training{r});
        if sum(temp) == 0; weighedrats{end+1} = ''; %#ok<AGROW>
        else               weighedrats{end+1} = cagemates{temp}; %#ok<AGROW>
        end
    end
    weighedrats(strcmp(weighedrats,'')) = [];
    weighedrats = unique(weighedrats);
    
    fd = ratnames1(forcedeps ~= 0);
    
    ratnames = [weighedrats; recov; fd]; ratnames(strcmp(ratnames,'')) = []; ratnames = unique(ratnames);
    
    
    [m d r] = bdata('select mass, date, ratname from ratinfo.mass order by date'); 
    for i = 1:length(ratnames)
        temp = strcmp(r,ratnames{i}); %#ok<NASGU>
        eval(['MASS.' ,ratnames{i},' = m(temp);']);
        eval(['DATES.',ratnames{i},' = d(temp);']);
    end
    
    pmain = bSettings('get','GENERAL','Main_Code_Directory');
    pname = [pmain,'\Utility\AutomatedEmails\'];
    
    LTR = 'abcdefghijklmnopqrstuvwxyz';
    foundfile = 0;
    dt = changedate(yearmonthday,1);
    cnt = 0;
    while foundfile == 0
        cnt = cnt+1;
        dt = changedate(dt,-1);
        for ltr = 26:-1:1
            file = ['C:\Automated Emails\Mass\',dt,LTR(ltr),'_DecliningRats.mat'];
            if exist(file,'file')==2; foundfile = 1; load(file); PreviousBad = AllBadRats; end     %#ok<NODEF>
        end
        if cnt >= 10; PreviousBad = cell(0); foundfile = 1; end
    end

    notrealrats = {'sen1';'sen2'};

    missingeveningmass = cell(0);
    missingmorningmass = cell(0);

    output = [];

    [Exp, expnames, subscribe_alls, morningTs, afternoonTs, LMs, alum] =...
        bdata('select email, experimenter, subscribe_all, tech_morning, tech_afternoon, lab_manager, is_alumni from ratinfo.contacts');
    
    AllBadRats    = cell(0);
    AllRecovRats  = cell(0);
    RecovPosRats  = cell(0);
    FewEntRats    = cell(0);

    for e = 1:length(Exp)
        if alum(e) == 1; continue; end
        
        expname = expnames{e};
        tempemail = Exp{e}(1:find(Exp{e} == '@',1,'first')-1);
        rattemp = [];
        for r = 1:length(ratnames)
            temp = strcmp(ratnames1,ratnames{r});
            if sum(temp) == 0; continue; end
            contact = contacts{temp};
            expswap = parse_emails(contact);
            
            temp = Exp(subscribe_alls == 1);
            for i = 1:length(temp)
                temp{i}(find(temp{i}=='@',1,'first'):end) = [];
            end
            expswap(end+1:end+length(temp)) = temp;
            
            if sum(strcmp(expswap,tempemail)) > 0
                rattemp(end+1) = r; %#ok<AGROW>
            end
        end

        message = cell(0);
        badrats = [];
        tempdata = cell(0);
        for r = 1:length(rattemp)

            ratname = ratnames{rattemp(r)};
            if sum(strcmp(notrealrats,ratname)) > 0; continue; end
            min_entries = 10;
            max_days    = 30;

            days  = 0:-1:-max_days+1;
            mass = []; 
            eval(['M = MASS.',ratname,';']);
            eval(['D = DATES.',ratname,';']);
            for d = days
                temp = strcmp(D,datestr(now+d,29));
                if sum(temp) ~= 0; mass(end+1) = M(find(temp==1,1,'first')); %#ok<AGROW>
                else               mass(end+1) = nan; %#ok<AGROW>
                end
            end
            mass(mass == 0) = nan; %#ok<AGROW>

            for m = 2:length(mass)-1
                if sum(isnan(mass(m-1:m+1))) == 0
                    temp = mean([mass(m-1) mass(m+1)]);
                    if abs(mass(m-1) - mass(m+1)) / temp < 0.02
                        if abs(mass(m) - temp) / temp > 0.04
                            mass(m) = nan; %#ok<AGROW>
                        end
                    end
                end
            end

            gooddata = ~isnan(mass);
            goodmass = mass(gooddata);
            gooddays = days(gooddata);
            n_done_trials=[];
            
%             for d=gooddays
%                 sqlstr=sprintf('select n_done_trials from bdata.sessions where ratname="%s" and datediff(sessiondate,curdate())=%d',ratname,d);
%                 [trials]=bdata(sqlstr);
%                 if isempty(trials); trials=nan; end;
%                 n_done_trials(end+1)=trials(1);
%             end
            
            temp1 = strcmp(training,ratname);
            if sum(temp1) == 0
                %He doesn't train
                temp2 = strcmp(ratnames1,ratname);
                if sum(temp2) == 0; continue; end
                cm = cagemates{find(temp2 == 1,1,'first')};
                if strcmp(cm,'') == 1 || sum(strcmp(training,cm)) == 0
                    %He had no cagemate or his cagemate doesn't train
                    slot = forcedeps(strcmp(ratnames1,ratname));
                    if slot == 0
                        %He is not forced to get water at any particular time
                        if sum(strcmp(recov,ratname)) > 0
                            %He's a recovering rat, weight in morning
                            slot = 0;
                        else
                            slot = 7;
                        end
                    end
                else
                    %His cagemate does train
                    slot = slots(strcmp(training,cm));
                end
            else
               slot = slots(temp1);     
            end        
                
            if isnan(mass(1)) && ~istodaysunday
                if     slot < 4; missingmorningmass{end+1} = ratname; %#ok<AGROW>
                else             missingeveningmass{end+1} = ratname; %#ok<AGROW>
                end
            end
            if find_missing == 1; continue; end

            isrecoveringrat = recoverings(strcmp(ratnames1,ratname));
            if isrecoveringrat == 1; AllRecovRats{end+1} = ratname; end %#ok<AGROW>
            
            fewentries = 0;
            if sum(gooddata) < min_entries; 
                fewentries = 1;
            else
                weight_declining = 0;

                onedaychange   = (goodmass(1) - goodmass(2)) / mean(goodmass(1:10));
                multidaychange = (mean(goodmass(1:3)) - mean(goodmass(8:10))) / mean(goodmass(1:10));
                [rr pp]        = corrcoef(gooddays(1:10),goodmass(1:10));
                slope          = polyfit(gooddays(1:10),goodmass(1:10),1);

                if onedaychange < -0.05 || multidaychange < -0.08 || (rr(2) < 0 && pp(2) < 0.05 && slope(1) < -1);  
                    weight_declining = 1; 
                end
            end

            if weight_declining == 1 || sum(strcmp(PreviousBad,ratname)) > 0 || isrecoveringrat == 1 || fewentries == 1
                if fewentries == 1
                    message{end+1,1}  = [ratname,'  Too Few Weight Entries'];                     %#ok<AGROW>
                    FewEntRats{end+1} = ratname;                                                  %#ok<AGROW>
                elseif weight_declining == 1
                    message{end+1,1} = ratname;                                                   %#ok<AGROW>
                    badrats = [badrats,' ',ratname];                                              %#ok<AGROW>
                    AllBadRats{end+1} = ratname;                                                  %#ok<AGROW>
                elseif sum(strcmp(PreviousBad,ratname)) > 0
                    message{end+1,1} = [ratname,'  First Good Day Follow Up'];                    %#ok<AGROW>
                elseif isrecoveringrat == 1
                    message{end+1,1} = [ratname,'  Recovering'];                                  %#ok<AGROW>
                    RecovPosRats{end+1} = ratname;                                                %#ok<AGROW>
                end
                
                message{end+1,1} =  ' ';                                                          %#ok<AGROW>
                message{end+1,1} = ['One Day Change: ',num2str(round(onedaychange*1e3)/1e3)];     %#ok<AGROW>
                message{end+1,1} = ['Multi Day Change: ',num2str(round(multidaychange*1e3)/1e3)]; %#ok<AGROW>
                message{end+1,1} = ['Multi Day r: ',num2str(round(rr(2)*1e3)/1e3)];               %#ok<AGROW>
                message{end+1,1} = ['Multi Day p: ',num2str(round(pp(2)*1e3)/1e3)];               %#ok<AGROW>
                message{end+1,1} = ['Multi Day slope: ',num2str(round(slope(1)*1e3)/1e3)];        %#ok<AGROW>
                message{end+1,1} =  ' ';                                                          %#ok<AGROW>
                if length(goodmass) < 10
                    message{end+1,1} = ['Rat Mass Data: ',num2str(goodmass(end:-1:1))];           %#ok<AGROW>
                    %message{end+1,1}=  ['Rat Trials:    ',num2str(n_done_trials(end:-1:1))];
                else
                    message{end+1,1} = ['Rat Mass Data: ',num2str(goodmass(10:-1:1))];            %#ok<AGROW>
                    %message{end+1,1}=  ['Rat Trials:    ',num2str(n_done_trials(10:-1:1))];
                end
                message{end+1,1} =  ' ';                                                          %#ok<AGROW>
                message{end+1,1} =  ' ';                                                          %#ok<AGROW>
                message{end+1,1} =  ' ';                                                          %#ok<AGROW>
                
                tempdata{end+1}.ratname = ratname;                                                %#ok<AGROW>
                tempdata{end}.mass = mass;
            end
        end
        if find_missing == 1; continue; end
        
        if ~isempty(message)   
            message{end+1,1} = 'Explaination of parameters:';                                                                 %#ok<AGROW>
            message{end+1,1} = 'One Day Change is the percent change in body mass over the past 2 mass entires';              %#ok<AGROW>
            message{end+1,1} = 'Multi Day Change is the percent change in body mass over the past 10 mass entries';           %#ok<AGROW>
            message{end+1,1} = '        the average mass from entries 1:3 is compared to the average mass from entires 8:10'; %#ok<AGROW>
            message{end+1,1} = 'Multi Day r is the correlation coefficient from the linear fit to the last 10 entries';       %#ok<AGROW>
            message{end+1,1} = 'Multi Day p is the p value of the correlation coefficient';                                   %#ok<AGROW>
            message{end+1,1} = 'Rat Mass Data are the last 10 mass entries';                                                  %#ok<AGROW>
            message{end+1,1} = ' ';                                                                                           %#ok<AGROW>
            message{end+1,1} = 'Current Thresholds: ';                                                                        %#ok<AGROW>
            message{end+1,1} = 'One Day Change < -0.05 ';                                                                     %#ok<AGROW>
            message{end+1,1} = 'Multi Day Change < -0.08 ';                                                                   %#ok<AGROW>
            message{end+1,1} = 'Multi Day p < 0.05 ';                                                                         %#ok<AGROW>
            message{end+1,1} = 'Multi Day slope < -1 ';                                                                       %#ok<AGROW>
            message{end+1,1} = ' ';                                                                                           %#ok<AGROW>
            message{end+1,1} = 'You will receive an e-mail every day a rats weight is declining and also the first day after';%#ok<AGROW>
            message{end+1,1} = 'when his weight is no longer declining as a follow up.  Rats on follow up are indicated in';  %#ok<AGROW>
            message{end+1,1} = 'the graph with an * next to their name. Rats marked as recovering will generate a graph     ';%#ok<AGROW>
            message{end+1,1} = 'every day, and are indicated in the graph with a _R next to their name. If their weight is  ';%#ok<AGROW>
            message{end+1,1} = 'increasing that will be amended to _R+. Rats with too few entries will always generate an   ';%#ok<AGROW>
            message{end+1,1} = 'email and will have a _F next to their name in the figure legend.';                           %#ok<AGROW>
            message{end+1,1} = ' ';                                                                                           %#ok<AGROW>
            message{end+1,1} = 'Thanks';                                                                                      %#ok<AGROW>
            message{end+1,1} = 'The Mass Meister';                                                                            %#ok<AGROW>
            message{end+1,1} = '  ';                                                                                          %#ok<AGROW>
            message{end+1,1} = '  ';                                                                                          %#ok<AGROW>
            message{end+1,1} = 'This email was generated by the Brody Lab Automated Email System.';                           %#ok<AGROW>
            
            IP = get_network_info;
            message{end+1} = ' '; %#ok<AGROW>
            if ischar(IP); message{end+1} = ['Email generated by ',IP]; %#ok<AGROW>
            else           message{end+1} = ['Email generated by unknown computer!!!']; %#ok<AGROW>
            end
            
            if ~isempty(tempdata);
                f = figure('color','w'); set(gca,'fontsize',18); hold on;
                c = jet(length(tempdata));
                name = cell(0);
                for r = 1:length(tempdata);
                    plot(0:-1:-max_days+1,tempdata{r}.mass,'-o','markerfacecolor',c(r,:),...
                        'markeredgecolor',c(r,:),'markersize',8,'color',c(r,:),'linewidth',2);
                    if sum(strcmp(AllRecovRats,tempdata{r}.ratname)) > 0
                        name{r} = [tempdata{r}.ratname,'_R'];
                        if sum(strcmp(RecovPosRats,tempdata{r}.ratname)) > 0
                            name{r} = [tempdata{r}.ratname,'_R+'];
                        end
                    elseif sum(strcmp(FewEntRats,tempdata{r}.ratname)) > 0
                        name{r} = [tempdata{r}.ratname,'_F'];
                    elseif sum(strcmp(AllBadRats,tempdata{r}.ratname)) == 0
                        name{r} = [tempdata{r}.ratname,'*'];
                    else
                        name{r} = tempdata{r}.ratname; 
                    end
                end
                legend(gca,name,'Location','EastOutside');
                xlabel(['Days Prior to ',datestr(now,29)]);
                ylabel('Rat Mass, grams'); pause(0.1);

                saveas(f,[pname,'ratmassfig.pdf']); pause(0.1);
                close(f);
            end

            if isempty(badrats)
                subject = 'Rat Mass Follow-Up';
            else
                subject = [badrats,' Weight Declining'];
            end
            message = remove_duplicate_lines(message);
            sendmail(Exp{e},subject,message,[pname,'ratmassfig.pdf']);
            eval(['output.',expname,' = message;']); 

        end
    end 

    clear output
    if find_missing == 1
        output.morning = missingmorningmass;
        output.evening = missingeveningmass;
    else 
        output = [];
    end
    
    for i = 1:2;
        if i == 1; R = missingmorningmass; T = 'morning'; 
                   E = Exp(subscribe_alls == 1 | morningTs == 1 | LMs == 1);
        else       R = missingeveningmass; T = 'evening'; 
                   E = Exp(subscribe_alls == 1 | afternoonTs == 1 | LMs == 1);
        end
        if ~isempty(R)
            message = cell(0);
            message{end+1} = ['The following rats are to be weighed in the ',T];                   %#ok<AGROW>
            message{end+1} = 'but were not weighed today.';                                        %#ok<AGROW>
            message{end+1} = '   ';                                                                %#ok<AGROW>
            for r = 1:length(R); message{end+1} = R{r}; end                                        %#ok<AGROW>
            message{end+1} = '   ';                                                                %#ok<AGROW>
            message{end+1} = 'Please remember to weigh all rats that run, every day.';             %#ok<AGROW>
            message{end+1} = '   ';                                                                %#ok<AGROW>
            message{end+1} = 'Thanks,';                                                            %#ok<AGROW>
            message{end+1} = 'The Mass Meister';                                                   %#ok<AGROW>
            
            IP = get_network_info;
            message{end+1} = ' '; %#ok<AGROW>
            if ischar(IP); message{end+1} = ['Email generated by ',IP]; %#ok<AGROW>
            else           message{end+1} = 'Email generated by an unknown computer!!!'; %#ok<AGROW>
            end

            for e = 1:length(E)
                if alum(strcmp(Exp,E{e})) == 1; continue; end
                techname = expnames{strcmp(Exp,E{e})};
                message = remove_duplicate_lines(message);
                if find_missing == 0
                    sendmail(E{e},'Missing Rat Weights Detected',message);
                end
                eval(['output.',techname,' = message;']);
            end
        end
    end

    if find_missing == 0
        try
            for ltr = 1:26
                file = ['C:\Automated Emails\Mass\',yearmonthday,LTR(ltr),'_MassProblem_Email.mat'];
                if ~exist(file,'file'); save(file,'output'); break; end    
            end
        end

        try
            for ltr = 1:26
                file = ['C:\Automated Emails\Mass\',yearmonthday,LTR(ltr),'_DecliningRats.mat'];
                if ~exist(file,'file'); save(file,'AllBadRats'); break; end    
            end
        end
    end
    
catch %#ok<CTCH>
    senderror_report;
end