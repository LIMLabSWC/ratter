function [sm] = InputClickedCallback(sender, event, sm, ioLine)

    sm = get(sm.Fig, 'UserData');

    [m,n] = size(sm.InputEvents);

    if (m > 1), 
      error(['INTERNAL ERROR sm.InputEvents is not a vector!']); 
    end;

    [m,n] = size(sm.InputState);

    if (m > 1), 
      error(['INTERNAL ERROR sm.InputState is not a vector!']); 
    end;
    
    [m, n] = size(sm.InputState);

    if (m ~= 1), 
      error('INTERNAL ERROR InputState is not a vector!'); 
    end;

    if (n < ioLine),
      error(sprintf(['INTERNAL ERROR InputState does not contain the value' ...
      ' %d'], ioLine));
    end;
    
    oldVal = sm.InputState(1, ioLine);
    newVal = ~oldVal;
    
    sm.InputState(1, ioLine) = newVal;
    
    RedrawInputButton(sm, ioLine);
    
    % debug...
    if (sm.debug),   
      [ioLine, oldVal, newVal]
      sm.InputState
    end;

    ts = emu_time(sm);
    
    if sm.UseHappenings,
      % Added 2026: this trial's matrix uses happenings (Cin, Chi, ...)
      sm = happ_edge(sm, ioLine, newVal, ts);
    else

    if (oldVal > newVal),
      % edge-down transition..
      [i, evtColPos, v] = find(sm.InputEvents == -ioLine);
      for i=1:size(evtColPos, 2),
        sm = EventColTriggered(sm, evtColPos(1,i), ts);
      end;
    end;

    if (newVal > oldVal),
      % edge-up transition..
      [i, evtColPos, v] = find(sm.InputEvents == ioLine);
      for i=1:size(evtColPos, 2),
        sm = EventColTriggered(sm, evtColPos(1,i), ts);
      end;
    end;

    end; % if sm.UseHappenings

    if (sm.debug),
      disp(sprintf('inputclicked time: %05.5f', ts));
    end;

    set(sm.Fig, 'UserData', sm);
    
    return;
    