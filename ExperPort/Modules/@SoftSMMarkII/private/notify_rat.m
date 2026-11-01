function [sm] = notify_rat(sm, ts, reason)
% sm = notify_rat(sm, ts, reason)   (added 2026)
%
% Tells the attached rat (see SetRatCallback.m) what the machine is doing
% and queues the pokes it answers with. reason is 'state' (a new state was
% entered) or 'input' (its last scheduled poke has just been applied).
% The callback gets one struct and returns an N x 3 matrix
% [emulator_time line value] (or []).

   if isempty(sm.RatCallback), return; end;

   s = sm.CurrentState;
   name = '';
   if s+1 <= numel(sm.StateStrings) && ischar(sm.StateStrings{s+1}), name = sm.StateStrings{s+1}; end;
   sw = struct('id', {}, 'dioLine', {}, 'running', {});
   for i = 1:size(sm.SchedWaves, 1),
     w = sm.SchedWaves{i,1};
     sw(i).id = w.id; sw(i).dioLine = w.dioLine; sw(i).running = w.running;
   end;

   info = struct( ...
     'ts',             ts, ...
     'reason',         reason, ...
     'state',          s, ...
     'state_name',     name, ...
     'dout',           sm.ContOut, ...
     'input_state',    sm.InputState, ...
     'n_pending',      size(sm.PendingInputs, 1), ...
     'matrix',         sm.StateMatrix, ...
     'input_events',   sm.InputEvents, ...
     'tup_col',        GetTUPCol(sm), ...
     'use_happenings', sm.UseHappenings, ...
     'happ_spec',      sm.HappSpec, ...
     'sched_waves',    sw, ...
     'speed',          sm.Speed);
   info.happ_list     = sm.HappList;      % (cells can't go in struct() directly)
   info.output_routing = sm.OutputRouting;

   acts = [];
   try
     acts = feval(sm.RatCallback{1}, info, sm.RatCallback{2:end});
   catch err
     where = '';
     if ~isempty(err.stack), where = sprintf(' (%s line %d)', err.stack(1).name, err.stack(1).line); end
     fprintf(2, 'SoftSMMarkII: rat callback failed: %s%s\n', err.message, where);
   end;
   if ~isempty(acts),
     acts(:,1) = max(acts(:,1), ts);   % nothing can happen in the past
     sm.PendingInputs = sortrows([sm.PendingInputs ; acts(:,1:3)], 1);
   end;
   return;
