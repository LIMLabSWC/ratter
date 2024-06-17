% isvector(x)	returns length if x is either a row or column vector, 0 else
%
%

function [a] = isvector(x)
	if iscolumn(x)
		a = size(x,1);
	elseif isrow(x)
		a = size(x,2);
	else
		a = 0;
	end;
	
