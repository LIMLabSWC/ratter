function [sm] = FlushQueue(sm)
    sm = get(sm.Fig, 'UserData');
    
    if (sm.debug),
      display(sprintf('FlushQueue: qsize %d',size(sm.EventQueue, ...
                                                  1)));
    end;

    % Added 2026: when inputs are scheduled ahead (VirtualRat) they are
    % applied in emulator-time order with the timers; see private/advance_to.m.
    % Without scheduled inputs the original loop below runs unchanged.
    if ~isempty(sm.RatCallback) || ~isempty(sm.PendingInputs),
      sm = flush_with_scheduled_inputs(sm);
      return;
    end;

    haveEvents = 1;

    while haveEvents,
       while(size(sm.EventQueue, 1)),
        sm = ProcessNextQueuedEvent(sm);
        now = emu_time(sm);      
        sm = ProcessTimers(sm, now);      
      end;

      now = emu_time(sm);      
      sm = ProcessTimers(sm, now);
      
      % below code is necessary because drawnow might cause an
      % inputclicked event which means that our sm 'pointer' needs
      % to be re-set.
      set(sm.Fig, 'UserData', sm);
      drawnow;
      sm = get(sm.Fig, 'UserData');
      
      haveEvents = size(sm.EventQueue, 1);

      if (haveEvents),
        sm = UpdateRunningSchedWavesGUI(sm);
        sm = UpdateCurrentTimeGUI(sm, now);
      end;
      
      if (sm.debug & haveEvents),
        disp(sprintf('flushqueue time: %05.5f', now));
      end;
    
    end;
      
    sm = UpdateRunningSchedWavesGUI(sm);
    sm = UpdateCurrentTimeGUI(sm);
    
    set(sm.Fig, 'UserData', sm);

    
    return;


% -----------------------------------------------------------------------
function [sm] = flush_with_scheduled_inputs(sm)
    now = emu_time(sm);
    sm  = advance_to(sm, now);
    set(sm.Fig, 'UserData', sm);
    drawnow;                              % let GUI clicks through, as above
    sm  = get(sm.Fig, 'UserData');
    if size(sm.EventQueue, 1),
      now = emu_time(sm);
      sm  = advance_to(sm, now);
    end;
    sm = UpdateRunningSchedWavesGUI(sm);
    sm = UpdateCurrentTimeGUI(sm, now);
    set(sm.Fig, 'UserData', sm);
    return;
