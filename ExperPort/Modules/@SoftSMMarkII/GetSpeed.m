% speed = GetSpeed(sm)   (added 2026)   Emulator speed factor; see SetSpeed.m
function [speed] = GetSpeed(sm)
   sm = get(sm.Fig, 'UserData');
   speed = sm.Speed;
   return;
