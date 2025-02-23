function check_rat_exceptions

try
    setpref('Internet','SMTP_Server','sonnabend.princeton.edu');
    setpref('Internet','E_mail','RatRegistry@Princeton.EDU');

    [ratR,recov,forcedep,bringup,deliv,contact] = bdata(['select ratname, recovering, forceDepWater,',...
        ' bringUpAt, deliverydate, contact from ratinfo.rats where extant=1 order by ratname']);

    [Exp,email] = bdata('select experimenter, email from ratinfo.contacts where is_alumni=0');
    for i = 1:length(email); econ{i} = email{i}(1:find(email{i} == '@',1,'first')-1); end %#ok<AGROW>

    X = struct('old',[],'bringup',[],'forcedep',[],'recov',[]);

    for i = 1:length(ratR)

        %Let's check for old rats
        age = now - datenum(deliv{i},'yyyy-mm-dd');
        if  age > 610
            if strcmp(deliv{i},'0000-00-00');
                months = nan; %#ok<NASGU>
            else
                months = round((age/30.5) * 10) / 10; %#ok<NASGU>
            end
            eval(['X.old.',ratR{i},'=months;']);
        end

        %Let's check for recovering rats
        if recov(i) == 1; 
            eval(['X.recov.',ratR{i},'=1;']); 
        end

        %Let's check for bring up rats
        if bringup(i) ~= 0
            eval(['X.bringup.',ratR{i},'=bringup(i);']);
        end

        %Let's check for forcedep rats
        if forcedep(i) ~= 0
            eval(['X.forcedep.',ratR{i},'=forcedep(i);']);
        end
    end

    oldrats = fields(X.old);
    recrats = fields(X.recov);
    buprats = fields(X.bringup);
    deprats = fields(X.forcedep);

    for i = 1:length(Exp)
        message = cell(0);

        donefirst = 0;
        for j = 1:length(oldrats)
            con = contact{strcmp(ratR,oldrats{j})};
            if ~isempty(strfind(con,econ{i})) 
                if donefirst == 0;
                    message{end+1} = 'The following rats are more than 20 months old:'; %#ok<AGROW>
                    message{end+1} = ' '; %#ok<AGROW>
                    donefirst = 1;
                end
                message{end+1} = [oldrats{j},' is now ',num2str(eval(['X.old.',oldrats{j}])),' months old']; %#ok<AGROW>
            end
        end
        if donefirst == 1; message{end+1} = ' '; message{end+1} = ' '; end %#ok<AGROW>

        donefirst = 0;
        for j = 1:length(recrats)
            con = contact{strcmp(ratR,recrats{j})};
            if ~isempty(strfind(con,econ{i})) 
                if donefirst == 0;
                    message{end+1} = 'The following rats are flagged as recovering:'; %#ok<AGROW>
                    message{end+1} = ' '; %#ok<AGROW>
                    donefirst = 1;
                end
                message{end+1} = recrats{j}; %#ok<AGROW>
            end
        end
        if donefirst == 1; message{end+1} = ' '; message{end+1} = ' '; end %#ok<AGROW>

        donefirst = 0;
        for j = 1:length(buprats)
            con = contact{strcmp(ratR,buprats{j})};
            if ~isempty(strfind(con,econ{i})) 
                if donefirst == 0;
                    message{end+1} = 'The following rats have specified bring up times:'; %#ok<AGROW>
                    message{end+1} = ' '; %#ok<AGROW>
                    donefirst = 1;
                end
                message{end+1} = [buprats{j},' is scheduled for bring up in session ',num2str(eval(['X.bringup.',buprats{j}]))]; %#ok<AGROW>
            end
        end
        if donefirst == 1; message{end+1} = ' '; message{end+1} = ' '; end %#ok<AGROW>

        donefirst = 0;
        for j = 1:length(deprats)
            con = contact{strcmp(ratR,deprats{j})};
            if ~isempty(strfind(con,econ{i})) 
                if donefirst == 0;
                    message{end+1} = 'The following rats have specified watering times:'; %#ok<AGROW>
                    message{end+1} = ' '; %#ok<AGROW>
                    donefirst = 1;
                end
                message{end+1} = [deprats{j},' is scheduled for watering in session ',num2str(eval(['X.forcedep.',deprats{j}]))]; %#ok<AGROW>
            end
        end

        if ~isempty(message)
            IP = get_network_info;
            message{end+1} = ' '; %#ok<AGROW>
            if ischar(IP); message{end+1} = ['Email generated by ',IP]; %#ok<AGROW>
            else           message{end+1} = 'Email generated by an unknown computer!!!'; %#ok<AGROW>
            end
            
            sendmail(email{i},'Weekly Rat Exception Reminder',message);
        end

    end

catch %#ok<CTCH>
    senderror_report;
end
    
    
    
    
            