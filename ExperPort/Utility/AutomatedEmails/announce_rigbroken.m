function announce_rigbroken

try
    %extract broken rigs
    rigs = bdata(['SELECT DISTINCT rigid FROM ratinfo.rig_maintenance WHERE isbroken=1']);
    %extract date of broken rigs
    datebroken=bdata(['SELECT DISTINCT broke_date FROM ratinfo.rig_maintenance WHERE isbroken=1']);
    %in the following for loop we will run over all broken rigs and find
    %for how many days they were broken
    brokenriginfo=[];
    counter=0;
    if ~isempty(rigs)
    for rig=rigs
    counter=counter+1;
    numbroken(counter)=datenum(datestr(now,29),'yyyy-mm-dd')-datenum(datestr(datebroken,29),'yyyy-mm-dd');
    end % running over all broken rigs and find #broken days
    
    setpref('Internet','SMTP_Server','sonnabend.princeton.edu');
    setpref('Internet','E_mail','The-A-team@Princeton.EDU');
    
    message=cell(0);
    message{end+1} = ['Test for BrokenRigs Report Generated: ',datestr(now,29)];
    message{end+1} = '';
%     message{end+1} = ['Only today you receive this email at this time '];
%     message{end+1} = '';
%     message{end+1} = ['In future it will be sent around midnight '];
    
    for rig=rigs 
        message{end+1} = ['Rig number ',num2str(rig),' is broken for ',num2str(numbroken),' days!'];
        %message{end+1}='';
    end
    else
        message=cell(0);
        message{end+1} = ['Test for BrokenRigs Report Generated: ',datestr(now,29)];
        message{end+1} = '';
        message{end+1} = 'There is no broken rig!';
    end 
        
    sendmail({'myartsev@princeton.edu','aakrami@princeton.edu','brody@princeton.edu'},'BrokenRig info ',message);
    %sendmail({'aakrami@princeton.edu'},'BrokenRig info ',message);   %',R],message);
   
catch %#ok<CTCH>
      senderror_report;  
end
