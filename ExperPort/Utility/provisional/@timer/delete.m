function delete(obj)
%DELETE Remove timer object from memory.
%
%    DELETE(OBJ) removes timer object, OBJ, from memory. If OBJ 
%    is an array of timer objects, DELETE removes all the objects
%    from memory.  
%
%    When a timer object is deleted, it becomes invalid and cannot 
%    be reused. Use the CLEAR command to remove invalid timer  
%    objects from the workspace.
%
%    If multiple references to a timer object exist in the workspace,
%    deleting the timer object invalidates the remaining 
%    references. Use the CLEAR command to remove the remaining
%    references to the object from the workspace.
%
%    See also CLEAR, TIMER, TIMER/ISVALID.
%

%    RDD 11-20-2001
%    Copyright 2001-2004 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

len = length(obj);

stopWarn = false;

for lcv=1:len
    try
        if obj.jobject(lcv).isRunning == 1
            stopWarn = true;
            obj.jobject(lcv).stop;
		end
		%Call the Java method, to trigger an asynchronous delete call.
        obj.jobject(lcv).Asyncdelete;
	catch
    end
end

if stopWarn == true
    state = warning('backtrace','off');
    warning('MATLAB:timer:deleterunning',timererror('matlab:timer:deleterunning'));
    warning(state);
end