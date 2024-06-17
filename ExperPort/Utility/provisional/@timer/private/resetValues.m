function resetValues(obj, pNames, pVals)
%resetValues resets the properties of a timer object
%
%    RESETVALUES(OBJ,PNAMES,PVALS) sets the properties of OBJ.  PNAMES and PVALS 
%    are values from the GETSETTABLEVALUES function.
%
%    See Also: TIMER/PRIVATE/GETSETTABLEVALUES
%

%    RDD 1-18-2002
%    Copyright 2001-2002 The MathWorks, Inc. 
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

olen = length(obj);
j=obj.jobject;

% foreach valid object...
for lcv=1:olen
    if isJavaTimer(j(lcv))
        for props=1:length(pNames)
            try
                set(j(lcv),pNames{props},pVals{lcv}{props});
            catch
            end
        end
    end
end