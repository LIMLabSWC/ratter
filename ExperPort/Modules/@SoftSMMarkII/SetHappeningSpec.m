% sm = SetHappeningSpec(sm, spec)   (added 2026)
%
%                Stores the happening specification that comes with the
%                next state matrix (StateMachineAssembler/send.m calls this
%                just before SetStateMatrix, as for @RTLSM2 and @BpodSM).
%                spec is a struct array with fields name,
%                detectorFunctionName, inputNumber and happId. It takes
%                effect together with that state matrix.
%
%                Supported detectors: line_in, line_out, line_high,
%                line_low, wave_in, wave_out, wave_high, wave_low.
%
function [sm] = SetHappeningSpec(sm, spec)

   reqfields = {'name', 'detectorFunctionName', 'inputNumber', 'happId'};
   if ~isstruct(spec) || ~isempty(setdiff(reqfields, fieldnames(spec))),
     error('SoftSMMarkII:BadSyntax', 'spec must be a structure with fields %s', ...
           sprintf('%s ', reqfields{:}));
   end;

   sm = get(sm.Fig, 'UserData');
   sm.NextHappSpec = spec;
   set(sm.Fig, 'UserData', sm);
   return;
