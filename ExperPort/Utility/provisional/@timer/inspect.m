function inspect(obj)
%INSPECT Open the inspector and inspect timer object properties.

%    RDD 11-20-2001
%    Copyright 2001-2003 The MathWorks, Inc.
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

% Error checking.
if length(obj) ~= 1
    error('MATLAB:timer:singletonrequired',timererror('MATLAB:timer:singletonrequired'));
end

if ~isvalid(obj)
   error('MATLAB:timer:invalid',timererror('MATLAB:timer:invalid'));
end

inspect(obj.jobject);
% Open the inspector.
