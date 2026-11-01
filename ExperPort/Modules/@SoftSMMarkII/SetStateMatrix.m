% sm = SetStateMatrix(sm, Matrix state_matrix) 
%
%                This command defines the state matrix that governs
%                the control algorithm during behavior trials. 
%           
%                It is an M x N matrix where M is the number of
%                states (so each row corresponds to a state) and N
%                is the number of input events + output events per state.
%
%                This state_matrix can have nearly unlimited rows 
%                (i.e., states), and has a variable number of
%                columns, depending on how many input events are
%                defined.  
%
%                To specify the number of input events,
%                see SetInputEvents().  The default number of input
%                events is 6 (CIN, COUT, LIN, LOUT, RIN, ROUT).  In
%                addition to the input event columns, the state matrix
%                also has 2+N_OUTPUTS additional columns: TIMEOUT_STATE
%                TIMEOUT_TIME plus the columns defined by the SetOutputRouting.m call.
%
%                Note:
%                   (1) the part of the state matrix that is being
%                   run during intertrial intervals should remain
%                   constant in between any two calls of
%                   Initialize()
%                   (2) that SetStateMatrix() should only be called
%                   in between trials.
%
%                Added 2026: also accepts the name/value form used by
%                StateMachineAssembler/send.m (same as @RTLSM2/@BpodSM):
%                  SetStateMatrix(sm, mat, 'pend_sm_swap_flg', 1, ...
%                                 'use_happenings', happList_or_0)
%                where happList is the per-state happening list.
%
function [sm] = SetStateMatrix(sm, mat, varargin)

   set_on_state0_flag = 0;
   happList           = [];
   if numel(varargin) == 1,
     set_on_state0_flag = varargin{1};
   elseif numel(varargin) > 1,
     if mod(numel(varargin), 2) ~= 0,
       error('SetStateMatrix: optional arguments must be name/value pairs');
     end;
     for k = 1:2:numel(varargin),
       switch varargin{k},
         case 'pend_sm_swap_flg', set_on_state0_flag = varargin{k+1};
         case 'use_happenings',
           if iscell(varargin{k+1}), happList = varargin{k+1}; else happList = []; end;
         otherwise,
           error('SetStateMatrix: unknown option "%s"', varargin{k});
       end;
     end;
   end;
   
    sm = get(sm.Fig, 'UserData');

    nColsReqd = size(sm.UpAndComingInputEvents, 2) + 2 + ...
        length(sm.OutputRouting);

    if (size(mat, 2) ~= nColsReqd),
      error('Specified matrix has incorrect number of columns, expected %d but got %d!\nDid you forget to call SetOutputRouting.m or SetInputEvents.m?\n', nColsReqd, size(mat, 2));
    end;

    sm.NextStateMatrix = mat;
    sm.NextHappList    = happList;
    sm.SetStateMatrixOnState0 = set_on_state0_flag;

    set(sm.Fig, 'USerData', sm);

    if set_on_state0_flag == 0,
       sm = ReallySetStateMatrix(sm);
    end;
    
    
    