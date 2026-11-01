function [sm] = happ_check_levels(sm, state, ts)
% sm = happ_check_levels(sm, state, ts)   (added 2026)
%
% Level happenings ('Chi', 'Clo', '<wave>_Hi', '<wave>_Lo'): if the state
% lists one that is true right now, the machine moves (first true one in
% the state's list wins). These are Bpod "conditions".

   if isempty(sm.HappSpec) || state+1 > numel(sm.HappList), return; end;
   L = sm.HappList{state+1};
   if isempty(L), return; end;

   names = {sm.HappSpec.name};
   for j = 1:2:numel(L)-1,
     k = find(strcmp(names, L{j}));
     if isempty(k), continue; end;
     k = k(end);
     dest = L{j+1};
     if dest == state, continue; end;
     n = sm.HappSpec(k).inputNumber;
     switch sm.HappSpec(k).detectorFunctionName,
       case 'line_high', istrue =  line_is_high(sm, n);
       case 'line_low',  istrue = ~line_is_high(sm, n);
       case 'wave_high', istrue =  wave_is_high(sm, n);   % n = wave id
       case 'wave_low',  istrue = ~wave_is_high(sm, n);
       otherwise,        istrue = 0;
     end;
     if istrue,
       sm = happ_enqueue(sm, k, dest, ts);
       return;
     end;
   end;
   return;


function [h] = line_is_high(sm, n)
   h = n <= numel(sm.InputState) && sm.InputState(n) ~= 0;
   return;


function [h] = wave_is_high(sm, waveId)
   h = 0;
   for i = 1:size(sm.SchedWaves, 1),
     sw = sm.SchedWaves{i, 1};
     if sw.id == waveId,
       h = sw.running && sw.didUP && ~sw.didDOWN;
       return;
     end;
   end;
   return;
