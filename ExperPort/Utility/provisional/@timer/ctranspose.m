function obj = ctranspose(obj)
% ' Complex conjugate transpose.   
% 
%    B = CTRANSPOSE(OBJ) is called for the syntax OBJ' (complex conjugate
%    transpose) when OBJ is a timer object array.
%

%    RDD 1-15-2002
%    Copyright 2001-2002 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

% Transpose the jobject vector.
obj.jobject = obj.jobject';