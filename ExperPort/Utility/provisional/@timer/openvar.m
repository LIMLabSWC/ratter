function openvar(name, obj)
%OPENVAR Open a timer object for graphical editing.
%
%    OPENVAR(NAME, OBJ) open a timer object, OBJ, for graphical 
%    editing. NAME is the MATLAB variable name of OBJ.
%
%    See also TIMER/SET, TIMER/GET.
%

%    RDD 03-13-2002
%    Copyright 2002-2003 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

if ~isa(obj, 'timer')
    errordlg('OBJ must be an timer object.', 'Invalid object', 'modal');
    return;
end

if ~isvalid(obj)
    errordlg('The timer object is invalid.', 'Invalid object', 'modal');
    return;
end

try
    inspect(obj);
catch
    fixlasterr;
    errordlg(lasterr, 'Inspection error', 'modal');
end