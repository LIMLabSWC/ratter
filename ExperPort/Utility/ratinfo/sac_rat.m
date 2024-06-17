function S=sac_rat(ratname)

if iscell(ratname)
    for rx=1:numel(ratname)
        S(rx)=sac_rat(ratname{rx});
    end
else
    
    
    [oldid, rig, slot, oldexp]=bdata('select schedentryid, rig, timeslot, experimenter from ratinfo.schedule where date>="{S}" and ratname="{S}" order by date desc limit 1',datestr(now,29),ratname);
    [ratID]=bdata('select internalID from ratinfo.rats where ratname="{S}"',ratname);
    
    
    
    if numel(ratID)==1
       
        try
            if ~isempty(oldid)
            mym(bdata,'update ratinfo.schedule set ratname="", experimenter="" where schedentryid="{S}"',oldid);
            fprintf('Rat %s removed from the schedule: Rig %d, Slot %d\n',ratname, rig, slot);
            end
            % Set date sac and extant=0
            mym(bdata,'update ratinfo.rats set extant=0,cagemate="", dateSac="{S}" where internalID="{S}"',datestr(now,29),ratID);
            
            % Remove rat from cagemate
            mym(bdata,'update ratinfo.rats set cagemate="" where cagemate="{S}"',ratname);
            
            fprintf('Rat %s removed from the registry\n',ratname);
            S.err=0;
        catch le
            showerror(le)
            S.err=1;
        end
        
    else
        fprintf('Failed to identify unique rat\n')
    end
end