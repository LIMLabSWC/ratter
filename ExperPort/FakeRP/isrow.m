% isrow(x)		returns 1 if x is a row vector, 0 otherwise
%
%

function [a] = isrow(x)
	if ( size(x,1) == 1 )
		a = 1;
	else
		a = 0;
	end;
