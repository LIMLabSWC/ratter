% <~> This is a modified version of GetEvents. See below.
%
function [EventList] = GetEvents2(sm, first, last)

    sm = get(sm.Fig, 'UserData');
    
    if (last > sm.EventCount),
      error(sprintf(['SoftSM only has %d events so far, not' ...
                     ' %d!'], sm.EventCount, last));
    end;
    
    EventList = sm.EventList(first:last,:);
    
    % <~> Return the column # instead of 2^(column #), as GetEvents2
    %       should. This matches the RTLSM.GetEvents2 method written as
    %       part of the switch to a format that allows the RTLSM to process
    %       more than 32 input columns correctly.
    %     Change made 2008.July.24 locally.
    raw = EventList(:,2);
    EventList(:,2) = log2(EventList(:,2));

    % Added 2026: events recorded while a happenings matrix was running
    % carry the happening id (stored as -id), and Tup is -1, which is what
    % StateMachineAssembler/disassemble_with_happenings expects (as Bpod).
    if any(sm.EventIsHapp(first:last)),
      h = find(sm.EventIsHapp(first:last));
      for k = h(:)',
        if     raw(k) < 0, EventList(k,2) = -raw(k);   % happening id
        elseif raw(k) > 0, EventList(k,2) = -1;        % Tup
        end;                                           % 0 (forced) stays -Inf
      end;
    end;
    
    return;
