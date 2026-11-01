% sm = ClearScheduledInputs(sm)   (added 2026)   Drops inputs scheduled with ScheduleInput.
function [sm] = ClearScheduledInputs(sm)
   sm = get(sm.Fig, 'UserData');
   sm.PendingInputs = zeros(0,3);
   set(sm.Fig, 'UserData', sm);
   return;
