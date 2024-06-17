function isemp = isempty(Obj)
%ISEMPTY True for empty timer arrays
%
%    ISEMPTY(X) returns 1 if X is an empty timer array and 0 otherwise. An
%    empty timer array has no elements, that is prod(size(X))==0.
%

%    RDD 1/29/2002
%    Copyright 2001-2003 The MathWorks, Inc.
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

isemp = (numel(Obj) == 0);

