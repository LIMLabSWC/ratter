function [sm] = apply_input(sm, line, val, ts)
% sm = apply_input(sm, line, val, ts)   (added 2026)
%
% Sets input line `line` to val (1 = poke in, 0 = poke out) at emulator
% time ts, exactly as if its button had been clicked at that time.

   if line < 1 || line > numel(sm.InputState), return; end;
   val = double(val ~= 0);
   if sm.InputState(1, line) == val, return; end;   % no edge, nothing to do

   sm.InputState(1, line) = val;
   RedrawInputButton(sm, line);

   if sm.UseHappenings,
     sm = happ_edge(sm, line, val, ts);
   elseif val,
     [i, evtColPos] = find(sm.InputEvents == line);  %#ok<ASGLU>
     for i = 1:size(evtColPos, 2), sm = EventColTriggered(sm, evtColPos(1,i), ts); end;
   else
     [i, evtColPos] = find(sm.InputEvents == -line); %#ok<ASGLU>
     for i = 1:size(evtColPos, 2), sm = EventColTriggered(sm, evtColPos(1,i), ts); end;
   end;
   return;
