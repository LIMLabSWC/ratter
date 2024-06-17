function AES_Master

HR = str2num(datestr(now,'HH')); %#ok<ST2NM>
if     HR == 0 %functions to run between 12AM  and 1AM
    try  %#ok<TRYNC>
        rat_bringup_list(2); 
    end 
     
elseif HR == 1  %functions to run between 1AM  and 2AM
    try  %#ok<TRYNC>
        rat_bringup_list(3); 
    end 
    
elseif HR == 2  %functions to run between 2AM  and 3AM  
    
elseif HR == 3  %functions to run between 3AM  and 4AM 
    try  %#ok<TRYNC>
        checktrainproblems2('full',now-1); 
    end
    
elseif HR == 4  %functions to run between 4AM  and 5AM     
    
elseif HR == 5  %functions to run between 5AM  and 6AM     

elseif HR == 6  %functions to run between 6AM  and 7AM
    try  %#ok<TRYNC>
        checkschedulechange2(2,'yesterday'); 
    end 
    try  %#ok<TRYNC>
        check_sched_reg_problems;       
    end 
    try  %#ok<TRYNC>
        rat_bringup_list(4);         
    end 
    
elseif HR == 7  %functions to run between 7AM  and 8AM 

elseif HR == 8  %functions to run between 8AM  and 9AM
    try  %#ok<TRYNC>
        rat_bringup_list(5); 
    end
    try  %#ok<TRYNC>
        checknoratsrun(1:3);      
    end
    
elseif HR == 9  %functions to run between 9AM  and 10AM
    try  %#ok<TRYNC>
        rat_bringup_list(6); 
    end 
    try %#ok<TRYNC>
        check_tomorrow_schedule_exists;
    end
    
elseif HR == 10 %functions to run between 10AM and 11AM

elseif HR == 11 %functions to run between 11AM and 12PM
    try  %#ok<TRYNC>
        rat_bringup_list(7); 
    end
    
elseif HR == 12 %functions to run between 12PM and 1PM 

elseif HR == 13 %functions to run between 1PM  and 2PM    

elseif HR == 14 %functions to run between 2PM  and 3PM  
    try  %#ok<TRYNC>
        rat_bringup_list(8); 
    end 
    try   %#ok<TRYNC>
        checkschedulechange2(3,'yesterday'); 
    end 
    try %#ok<TRYNC>
        checktrainproblems2('notes');
    end
    try  %#ok<TRYNC>
        checknoratsrun(4:6);      
    end

elseif HR == 15 %functions to run between 3PM  and 4PM 

    
elseif HR == 16 %functions to run between 4PM  and 5PM
    try  %#ok<TRYNC>
        rat_bringup_list(9); 
    end 

elseif HR == 17 %functions to run between 5PM  and 6PM

elseif HR == 18 %functions to run between 6PM  and 7PM

elseif HR == 19 %functions to run between 7PM  and 8PM    

elseif HR == 20 %functions to run between 8PM  and 9PM
    try  %#ok<TRYNC>
        checknoratsrun(7:9); 
    end 

elseif HR == 21 %functions to run between 9PM   and 10PM
    try  %#ok<TRYNC>
        rat_bringup_list(1,'print',now+1); 
    end 
    
elseif HR == 22 %functions to run between 10PM  and 11PM    
    try  %#ok<TRYNC>
        checkschedulechange2(1,'tomorrow'); 
    end
    
elseif HR == 23 %functions to run between 11PM and MIDNIGHT
    try  %#ok<TRYNC>
        checkratweights;    
    end 
    try  %#ok<TRYNC>
        if strcmp(datestr(now,'ddd'),'Sun')
            check_rat_exceptions;
        end
    end
	try %#ok<ALIGN,TRYNC>
		check_rat_performace;
    end

    try %#ok<ALIGN,TRYNC>
		announce_rigbroken;
    end
    
end

pause(10);
exit;