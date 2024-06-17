function log_infusion(D)
% log_infusion(D)
%
% D is a array of 1 or more structs with the following fields
% D.ratname         
% D.sessiondate     (defaults to today if empty or missing)
% D.region          
% D.volume          
% D.drug
% D.dose
% D.start_time
% D.end_time
% D.performed_by
% D.notes           
% D.ignore          (defaults to 0 if empty or missing)
% D.ignore_reason   (defaults to NULL if empty or missing)
% 
% If a field isempty for any struct after the first, it uses the data from the first struct 


fn=fieldnames(D(1));

for rx=2:numel(D)
   for fx=1:numel(fn) 
    if isempty(D(rx).(fn{fx}))
        D(rx).(fn{fx})=D(1).(fn{fx});
    end
   end
end



for rx=1:numel(D)
    this_rat=D(rx).ratname;
    if ~isfield(D(rx),'sessiondate') || isempty(D(rx).sessiondate)
        D(rx).sessiondate=datestr(now,29);
    end
        
    D(rx).sessid=bdata('select max(sessid) from sess_started where ratname="{S}" and sessiondate="{S}" ',this_rat, D(rx).sessiondate);
    D(rx).cntrl_sessid=bdata('select sessid from sessions where ratname="{S}" and sessiondate=date_sub("{S}",interval 1 day)',this_rat, D(rx).sessiondate);  

end

insert_struct('ratinfo.infusions',D);

