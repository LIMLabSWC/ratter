function S=put_rat_on_recovery(ratname)
% err=put_rat_on_recovery
%
% Input:
% Takes a ratname or a cell array of ratnames and moves the rat off
% of the training schedule and onto the recovery list
%
% Optional Output
% S    0 if everything worked
%      1 if there was an error


if iscell(ratname)
    for rx=1:numel(ratname)
        S(rx)=put_rat_on_recovery(ratname{rx});
    end
else
    
    
    [oldid, rig, slot, oldexp]=bdata('select schedentryid, rig, timeslot, experimenter from ratinfo.schedule where date>="{S}" and ratname="{S}" order by date desc',datestr(now,29),ratname);
    [ratID]=bdata('select internalID from ratinfo.rats where ratname="{S}"',ratname);
    
    
    
    if numel(ratID)==1
       
        try
            if ~isempty(oldid)
                for x=1:numel(oldid)
            mym(bdata,'update ratinfo.schedule set ratname="", experimenter="", comments="{S}" where schedentryid="{S}"',['reserved for ' ratname],oldid(x));
                end
            fprintf('Rat %s moved from the schedule, marked as reserved: Rig %d, Slot %d\n',ratname, rig, slot);
            end
            % Set date sac and extant=0
            mym(bdata,'update ratinfo.rats set recovering=1,training=0 where internalID="{S}"',ratID);
            
            fprintf('Rat %s set to recovering\n',ratname);
            S.err=0;
        catch le
            showerror(le)
            S.err=1;
        end
        
    else
        fprintf('Failed to identify unique rat\n')
    end
end