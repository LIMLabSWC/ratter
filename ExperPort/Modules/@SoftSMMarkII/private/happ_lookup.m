function [dest, found] = happ_lookup(sm, state, happName)
% [dest, found] = happ_lookup(sm, state, happName)   (added 2026)
%
% Where happening happName takes the machine from this state, according to
% the current happening list. found = 0 (and dest = state) if this state
% does not list the happening.

   dest = state; found = 0;
   if state+1 > numel(sm.HappList), return; end;
   L = sm.HappList{state+1};
   for j = 1:2:numel(L)-1,
     if strcmp(L{j}, happName),
       dest = L{j+1}; found = 1;   % keep the last one, as Bpod does
     end;
   end;
   return;
