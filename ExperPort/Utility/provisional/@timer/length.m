function out = length(obj)
%LENGTH Length of timer object array.
%
%    LENGTH(OBJ) returns the length of timer object array,
%    OBJ. It is equivalent to MAX(SIZE(OBJ)).  
%    
%    See also TIMER/SIZE.
%

%    RDD 1-8-2002
%    Copyright 2001-2002 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $


% The jobject property of the object indicates the number of 
% objects that are concatenated together.
try
   out = builtin('length', obj.jobject);
catch
   out = 1;
end




