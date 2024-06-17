function check_tomorrow_schedule_exists

try
    setpref('Internet','SMTP_Server','sonnabend.princeton.edu');
    setpref('Internet','E_mail','ScheduleMeister@Princeton.EDU');

    [r t] = bdata(['select rig, timeslot from ratinfo.schedule where date="',datestr(now+1,'yyyy-mm-dd'),'"']);

    message = cell(0);
    for rig=[1:3,7:30]
        for slot=1:9

            if sum(r==rig & t==slot) == 0
                message{end+1} = ['Missing Rig ',num2str(rig),' for Session ',num2str(slot)]; %#ok<AGROW>
            elseif sum(r==rig & t==slot) > 1
                message{end+1} = ['Duplicate Entry for Rig ',num2str(rig),' for Session ',num2str(slot)]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(message)
        sendmail({'ckopec@princeton.edu','jerlich@princeton.edu','brody@princeton.edu'},'Problem with Schedule',message);
    end
    
catch %#ok<CTCH>
    senderror_report;
end