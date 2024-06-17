function waitfor(obj)
%WAITFOR Wait until the timer stops running.
%
%    WAITFOR(OBJ) blocks the MATLAB command line and waits until the
%    timer, represented by the timer object OBJ, stops running. 
%    When a timer stops running, the value of the timer object's
%    Running property changes from 'On' to 'Off'.
%
%    If OBJ is an array of timer objects, WAITFOR blocks the MATLAB
%    command line until all the timers have stopped running.
%
%    If the timer is not running, WAITFOR returns immediately.
%
%    See also TIMER/START, TIMER/STOP, TIMER/WAIT.
%

%    RDD 3-11-2003
%    Copyright 2001-2003 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

try
    wait(obj);
catch
    rethrow(lasterror)
end
    