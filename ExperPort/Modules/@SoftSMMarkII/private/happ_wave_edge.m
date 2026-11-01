function [sm] = happ_wave_edge(sm, waveId, in_or_out, ts)
% sm = happ_wave_edge(sm, waveId, in_or_out, ts)   (added 2026)
%
% A scheduled wave went up ('in', end of preamble) or down ('out', end of
% sustain) while a happenings matrix is running: records <wave>_In or
% <wave>_Out, moves the state machine if the current state lists it, then
% checks the state's 'hi'/'lo' happenings.

   if isempty(sm.HappSpec), return; end;
   det = ['wave_' in_or_out];
   ids = find(reshape(strcmp({sm.HappSpec.detectorFunctionName}, det), 1, []) & ...
              reshape(arrayfun(@(h) isequal(h.inputNumber, waveId), sm.HappSpec), 1, []));   % inputNumber = wave id (see add_scheduled_wave.m)
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
