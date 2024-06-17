% iscolumn(x)		returns 1 if x is a column vector, 0 otherwise
%
%

function [a] = iscolumn(x)
	if ( size(x,2) == 1 )
		a = 1;
	else
		a = 0;
	end;
