function output = checkruninslot(Ts,Te,slot)

output = 0;

if     slot == 1; SS = '00:00:00'; SE = '02:00:00';
elseif slot == 2; SS = '02:00:00'; SE = '04:00:00';
elseif slot == 3; SS = '04:00:00'; SE = '06:00:00';
elseif slot == 4; SS = '08:00:00'; SE = '10:00:00';
elseif slot == 5; SS = '10:00:00'; SE = '12:00:00';
elseif slot == 6; SS = '12:00:00'; SE = '14:00:00';
elseif slot == 7; SS = '16:00:00'; SE = '18:00:00';
elseif slot == 8; SS = '18:00:00'; SE = '20:00:00';
elseif slot == 9; SS = '20:00:00'; SE = '22:00:00';
end

test1 = timediff(SS,Te,2);
test2 = timediff(Ts,SE,2);

if test1 < 0; output = -1; end
if test2 < 0; output =  1; end