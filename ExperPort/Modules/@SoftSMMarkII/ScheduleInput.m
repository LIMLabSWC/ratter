% sm = ScheduleInput(sm, line, value, t)   (added 2026)
%
%                Sets input line `line` (1 = C, 2 = L, 3 = R with the
%                standard INPUTLINES) to value (1 = poke in, 0 = poke out)
%                at emulator time t (see GetTime). Several rows can be
%                given at once: line, value and t of equal length. Inputs
%                are applied in time order with the state timers the next
%                time dispatcher flushes the emulator. A time already in
%                the past is applied at the current time. Line 0 is a
%                wake-up call: no input changes, but an attached rat
%                callback (SetRatCallback.m) is called at that time.
%
function [sm] = ScheduleInput(sm, line, value, t)

   line = line(:); value = value(:); t = t(:);
   if ~isequal(numel(line), numel(value), numel(t)),
     error('SoftSMMarkII:BadSyntax', 'line, value and t must have the same length');
   end;
   sm = get(sm.Fig, 'UserData');
   now = emu_time(sm);
   sm.PendingInputs = sortrows([sm.PendingInputs ; [max(t, now) line value]], 1);
   set(sm.Fig, 'UserData', sm);
   return;
