function [sm] = advance_to(sm, T)
% sm = advance_to(sm, T)   (added 2026)
%
% Runs the emulator up to emulator time T, applying scheduled inputs
% (sm.PendingInputs, sorted by time) in time order together with state
% timers and scheduled waves. Used by FlushQueue only when inputs are
% scheduled ahead (VirtualRat), so pokes land at their exact emulator time
% whatever the speed factor and however rarely dispatcher polls.

   for guard = 1:200000,
     if isempty(sm.PendingInputs), tp = Inf; else tp = sm.PendingInputs(1,1); end;
     sm = drain(sm, min(T, tp));
     % the rat may have scheduled something earlier while we drained
     if ~isempty(sm.PendingInputs) && sm.PendingInputs(1,1) < tp, continue; end;
     if tp > T, break; end;

     row = sm.PendingInputs(1,:);
     sm.PendingInputs = sm.PendingInputs(2:end,:);
     sm = apply_input(sm, row(2), row(3), row(1));
     sm = drain(sm, row(1));
     % tell the rat once its own pokes are all done (line 0 rows are
     % wake-up calls, not pokes; see ScheduleInput.m)
     if ~isempty(sm.RatCallback) && (row(2) == 0 || ~any(sm.PendingInputs(:,2) > 0)),
       sm = notify_rat(sm, row(1), 'input');
     end;
   end;
   return;


% -----------------------------------------------------------------------
% Process queued events and timers up to time lim, but never past the
% next scheduled input.
function [sm] = drain(sm, lim)
   for guard = 1:200000,
     if size(sm.EventQueue, 1),
       sm = ProcessNextQueuedEvent(sm);
       continue;
     end;
     L = lim;
     if ~isempty(sm.PendingInputs), L = min(L, sm.PendingInputs(1,1)); end;
     before = timer_signature(sm);
     sm = ProcessTimers(sm, L);
     if size(sm.EventQueue, 1) == 0 && isequal(before, timer_signature(sm)),
       break;
     end;
   end;
   return;


function [s] = timer_signature(sm)
   s = [sm.ForceTUP sm.CurrentState sm.CurrentStateTS];
   for i = 1:size(sm.SchedWaves, 1),
     sw = sm.SchedWaves{i,1};
     s = [s sw.running sw.didUP sw.didDOWN sw.untrigdInSustain]; %#ok<AGROW>
   end;
   return;
