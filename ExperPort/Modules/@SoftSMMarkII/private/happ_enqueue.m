function [sm] = happ_enqueue(sm, happId, nextState, ts)
% sm = happ_enqueue(sm, happId, nextState, ts)   (added 2026)
%
% Queues a happening event, the happenings counterpart of EnqueueEvent.m.
% The id is stored as -happId so it can't be mistaken for a column event
% (those are stored as 2^(col-1)); GetEvents2 turns it back into happId.

   currentState = GetCurrentState(sm);
   if isempty(nextState), nextState = currentState; end;

   if (sm.ReadyForTrialFlg && nextState == sm.ReadyForTrialJumpstate),
     nextState = 0;
     sm.ReadyForTrialFlg = 0;
   end;

   ct = size(sm.EventQueue, 1);
   sm.EventQueue(ct+1,1:4) = [ currentState -happId ts nextState ];
   return;
