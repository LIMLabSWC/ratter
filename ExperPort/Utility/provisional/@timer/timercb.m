function timercb(obj,type,val,event)
%TIMERCB Wrapper for timer object M-file callback.
%
%   TIMERCB(OBJ,TYPE,VAL,EVENT) calls the function VAL with parameters
%   OBJ and EVENT.  This function is not intended to be called by the 
%   user.
%
%   See also TIMER
%

%    RDD 12-2-01
%    Copyright 2001-2005 The MathWorks, Inc.
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

if ~isvalid(obj)
    return;
end
% try   % <~>
    if isa(val,'char') % strings are evaled in base workspace.
        evalin('base',val);
    else % non-strings are fevaled with calling object and event struct as parameters
    % Construct the event structure.  The callback is expected to be of cb(obj,event,...) format
        eventStruct = struct(event);
        eventStruct.Data = struct(eventStruct.Data);
    
	% make sure val is a cell / only not a cell if user specified a function handle as callback.
        if isa(val, 'function_handle')
            val = {val};
        end	
     % Execute callback function.
		feval(val{1}, obj, eventStruct, val{2:end});
    end        
% catch % <~> below
%     lerrInfo = lasterror;
%     if ~ strcmp(type,'ErrorFcn') && isJavaTimer(obj.jobject)
%         try
%            obj.jobject.callErrorFcn(lerrInfo.message,lerrInfo.identifier);
%         catch
%         end
%     end
%     %Error message is coming from Callback specified by the user.  We
%     %will provide the stack information in this case. (To be retrieved
%     %by call to lasterror).
%     lerrInfo.message = timererror('MATLAB:timer:badcallback',type, ...
%         get(obj,'Name'));
%     lerrInfo.identifier = 'MATLAB:timer:badcallback';
%     nStack = length(lerrInfo.stack)-length(dbstack);
%     lerrInfo.stack = lerrInfo.stack(1:nStack);
%     lasterror(lerrInfo);
%     disp(lasterr);
% end % <~> above
