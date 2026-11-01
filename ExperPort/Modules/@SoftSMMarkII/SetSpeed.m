% sm = SetSpeed(sm, speed)   (added 2026)
%
%                The emulator clock runs `speed` times faster than real
%                time from now on (1 = real time, the default). All state
%                timers, scheduled waves and recorded event times follow
%                the emulator clock, so a 2 s hold still takes 2 s of
%                emulator time but only 2/speed s of real time.
%
%                Only useful with inputs scheduled ahead in emulator time
%                (ScheduleInput.m, VirtualRat): clicks on the buttons
%                happen in real time. Mute the emulator's sounds at
%                speed > 1 (global softsound_play_sounds = 0).
%
function [sm] = SetSpeed(sm, speed)

   if ~isnumeric(speed) || ~isscalar(speed) || ~(speed > 0) || ~isfinite(speed),
     error('SoftSMMarkII:BadSpeed', 'speed must be a positive number');
   end;
   sm = get(sm.Fig, 'UserData');
   if speed == sm.Speed, return; end;

   t = emu_time(sm);          % continue the emulator clock from here
   sm.SpeedEmuT0  = t;
   sm.SpeedRealT0 = clock;
   sm.Speed       = speed;
   set(sm.Fig, 'UserData', sm);
   return;
