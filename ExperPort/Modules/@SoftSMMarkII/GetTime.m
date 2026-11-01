function [time] = GetTime(sm)
   
   sm = get(sm.Fig, 'UserData');
   time = emu_time(sm);
   return;
   