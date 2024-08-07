% [x, y] = WaterValvesSection(obj, action, x, y)
%
% Section that takes care of times for the water valves.
%
% PARAMETERS:
% -----------
%
% obj      Default object argument.
%
% action   One of:
%            'init'      To initialise the section and set up the GUI
%                        for it
%
%            'reinit'    Delete all of this section's GUIs and data,
%                        and reinit, at the same position on the same
%                        figure as the original section GUI was placed.
%
% x, y     Relevant to action = 'init'; they indicate the initial
%          position to place the GUI at, in the current figure window
%
%
% RETURNS:
% --------
%
% [x, y]   When action == 'init', returns x and y, pixel positions on
%          the current figure, updated after placing of this section's GUI. 
%

function [x, y] = WaterValvesSection(obj, action, x, y)
   
   GetSoloFunctionArgs;
   
   switch action
    case 'init',
      % Save the figure and the position in the figure where we are
      % going to start adding GUI elements:
      SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)]);

      % --- Water valve times
      EditParam(obj, 'RightWValveTime', 0.072, x, y);  next_row(y);
      EditParam(obj, 'LeftWValveTime',  0.072, x, y);  next_row(y);
      SoloFunctionAddVars('make_and_upload_state_matrix', 'ro_args', ...
                          {'LeftWValveTime', 'RightWValveTime'});

      next_row(y, 0.5);
      SubheaderParam(obj, 'title', 'Water Valves', x, y);
      next_row(y, 1.5);
      
    case 'reinit',
      currfig = double(gcf); 

      % Get the original GUI position and figure:
      x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));

      % Delete all SoloParamHandles who belong to this object and whose
      % fullname starts with the name of this mfile:
      delete_sphandle('owner',['^' class(obj) '$'],'fullname',['^' mfilename]);

      % Reinitialise at the original GUI position and figure:
      feval(mfilename, obj, 'init', x, y);

      % Restore the current figure:
      figure(currfig);      
   end;
   
   
      