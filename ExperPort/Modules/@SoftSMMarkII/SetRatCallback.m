% sm = SetRatCallback(sm, fhandle, extra_args...)   (added 2026)
% sm = SetRatCallback(sm, [])        removes it
%
%                Attaches a simulated animal (see Modules/@VirtualRat).
%                fhandle(info, extra_args{:}) is called, in emulator time,
%                each time a new state is entered (info.reason = 'state')
%                and after the last scheduled poke has been applied
%                (info.reason = 'input'). It returns an N x 3 matrix
%                [emulator_time line value] of pokes to schedule, or [].
%                info has the current state, outputs, input lines, the
%                state matrix and the happening list, so the callback can
%                work with any protocol.
%
function [sm] = SetRatCallback(sm, fhandle, varargin)

   sm = get(sm.Fig, 'UserData');
   if isempty(fhandle),
     sm.RatCallback = {};
     sm.PendingInputs = zeros(0,3);
   elseif isa(fhandle, 'function_handle'),
     sm.RatCallback = [{fhandle} varargin];
   else
     error('SoftSMMarkII:BadSyntax', 'fhandle must be a function handle or []');
   end;
   set(sm.Fig, 'UserData', sm);
   return;
