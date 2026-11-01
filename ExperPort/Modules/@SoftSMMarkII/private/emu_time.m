function [t] = emu_time(sm)
% t = emu_time(sm)   Current emulator time in seconds (added 2026).
%
% With the default speed factor of 1 this is exactly the original
% etime(clock, sm.T0). After SetSpeed(sm, s) the emulator clock runs
% s times faster than the real clock, continuing from where it was.

   if sm.Speed == 1 && sm.SpeedEmuT0 == 0,
     t = etime(clock, sm.T0);
   else
     t = sm.SpeedEmuT0 + sm.Speed * etime(clock, sm.SpeedRealT0);
   end;
   return;
