function [sm] = happ_edge(sm, line, newVal, ts)
% sm = happ_edge(sm, line, newVal, ts)   (added 2026)
%
% An input line changed while a happenings matrix is running. As on Bpod,
% the poke is always recorded (as e.g. 'Cin' / 'Cout'), it moves the state
% machine if the current state lists it, and afterwards any 'hi'/'lo'
% happenings of the (unchanged) state are checked.

   if isempty(sm.HappSpec), return; end;
   if newVal, det = 'line_in'; else det = 'line_out'; end;

   ids = find(reshape(strcmp({sm.HappSpec.detectorFunctionName}, det), 1, []) & ...
              reshape(arrayfun(@(h) isequal(h.inputNumber, line), sm.HappSpec), 1, []));
   cur = GetCurrentState(sm);
   if isempty(ids),
     sm = happ_check_levels(sm, cur, ts);
     return;
   end;

   use = ids(1); dest = cur;
   for k = ids,
     [d, found] = happ_lookup(sm, cur, sm.HappSpec(k).name);
     if found, use = k; dest = d; break; end;
   end;

   sm = happ_enqueue(sm, use, dest, ts);
   if dest == cur,
     sm = happ_check_levels(sm, cur, ts);
   end;
   return;
