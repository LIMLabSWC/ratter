% Typical section code-- this file may be used as a template to be added 
% on to. The code below stores the current figure and initial position when
% the action is 'init'; and, upon 'reinit', deletes all SoloParamHandles 
% belonging to this section, then calls 'init' at the proper GUI position 
% again.


% [x, y] = YOUR_SECTION_NAME(obj, action, x, y)
%
% Section that takes care of YOUR HELP DESCRIPTION
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
% RETURNS:
% --------
%
% [x, y]   When action == 'init', returns x and y, pixel positions on
%          the current figure, updated after placing of this section's GUI. 
%
%
%%% CVS version control block - do not edit manually
%%%  $Revision: 588 $
%%%  $Date: 2007-09-11 12:34:25 -0400 (Tue, 11 Sep 2007) $
%%%  $Source$


function [x, y] = PerformancePlotSection(obj, action, varargin)
   
GetSoloFunctionArgs;
%%% Imported objects (see protocol constructor):

switch action
  case 'init',
    % Save the figure and the position in the figure where we are
    % going to start adding GUI elements:
    x = varargin{1};
    y = varargin{2};
    MaxTrialsLocal = varargin{3};
    
    SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)]);

    MyFigPosition = get(double(gcf),'Position');

    MarkerSize = 4;
 
    oldunits = get(double(gcf), 'Units'); set(double(gcf), 'Units', 'normalized');
    SoloParamHandle(obj, 'hAxesPerf', 'saveable', 0, 'value', axes('Position', [0.1, 0.52, 0.8, 0.24]));
    ColorBlue = 'c';%[153,157,84]/255;
    ColorChoc = 'm';%[19,255,103]/255;
    SoloParamHandle(obj, 'congdot', 'saveable', 0, 'value',...
                    plot(-1, 1, 's','Color',ColorBlue,'MarkerSize',MarkerSize));hold on;
    SoloParamHandle(obj, 'incongdot', 'saveable', 0, 'value',...
                    plot(-1, 1, 's','Color',ColorChoc,'MarkerSize',MarkerSize));hold on;
    
    SoloParamHandle(obj, 'kdot', 'saveable', 0, 'value',...
                    plot(-1, 1, 'ko','MarkerSize',MarkerSize-1)); hold on; % black dots
    
    SoloParamHandle(obj, 'NtrialsToPlot', 'type', 'edit', 'label', 'ntrials', ...
                    'labelpos', 'bottom','TooltipString', 'Number of trials in plot', ...
                    'value', 400, 'position', round([MyFigPosition(3:4).*[0.92,0.54], 35, 40]));
    set_callback(NtrialsToPlot, {mfilename, 'update_xlim'});
    SoloParamHandle(obj, 'WindowSize', 'type', 'edit', 'label', 'WindowSize', ...
                    'labelpos', 'bottom','TooltipString', 'Window size', ...
                    'value', 10, 'position', round([MyFigPosition(3:4).*[0.92,0.64], 35, 40]));
    set(get_ghandle(WindowSize),'Enable','off');
    
    SoloParamHandle(obj, 'PerformanceVec', 'value', NaN(MaxTrialsLocal,1));
    SoloParamHandle(obj, 'PerfCongVec', 'value', NaN(MaxTrialsLocal,1));
    SoloParamHandle(obj, 'PerfIncongVec', 'value', NaN(MaxTrialsLocal,1));

    SoloParamHandle(obj, 'LastTrialSPH','value',1);
   
    PerformancePlotSection(obj,'update',0,[]);
    
    
  case 'update'
    LastTrialSPH.value = varargin{1};
    HitHistoryLocal = varargin{2};
    if(nargin>4)
        IncongruentTrials = varargin{3};
    else
        IncongruentTrials = [];        
    end
    %xlim(value(hAxesPerf),[0,value(NtrialsToPlot)+1]);
    ylim(value(hAxesPerf),[-0.1,1.1]);
    ylabel(value(hAxesPerf),'Performance');
    LastTrial = value(LastTrialSPH);

    [mn, mx] = PerformancePlotSection(obj,'update_xlim',LastTrial);
    if(LastTrial>0)
        % -- Calculate total performance --
        TrialsToInclude = [max(1,LastTrial-value(WindowSize)+1):LastTrial];
        PerformanceVec(LastTrial) = mean(HitHistoryLocal(TrialsToInclude));
        %set(value(kdot), 'XData', [1:LastTrial], 'YData', PerformanceVec([1:LastTrial]));
        set(value(kdot), 'XData', [mn:mx], 'YData', PerformanceVec([mn:mx]));
        %%%fprintf('Performance at last trial: %0.4f\n',PerformanceVec(LastTrial));

        % -- Calculate performance congruent/incongruent --
        if(~isempty(IncongruentTrials))
            TheseCongTrials = TrialsToInclude(~IncongruentTrials(TrialsToInclude));
            PerfCongVec(LastTrial) = mean(HitHistoryLocal(TheseCongTrials));
            %%% BUG: it will give warning DivByZero if mean of empty vec.
            set(value(congdot), 'XData', [mn:mx], 'YData', PerfCongVec([mn:mx]));

            TheseIncongTrials = TrialsToInclude(IncongruentTrials(TrialsToInclude));
            PerfIncongVec(LastTrial) = mean(HitHistoryLocal(TheseIncongTrials));
            %%% BUG: it will give warning DivByZero if mean of empty vec.
            set(value(incongdot), 'XData', [mn:mx], 'YData', PerfIncongVec([mn:mx]));
        end
    end
    
    
  case 'update_xlim'
    %%LastTrialSPH.value = varargin{1};
    % -- Use the last value of LastTrialSPH --
    mx = max(value(LastTrialSPH), value(NtrialsToPlot));
    mn = max(1,mx-value(NtrialsToPlot)+1);   
    set(value(hAxesPerf), 'XLim', [mn-0.5 mx+0.5]);
    x = mn; y = mx;                     % Return these values

  case 'reinit',
    currfig = double(gcf);

    % Get the original GUI position and figure:
    x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));

    % Delete all SoloParamHandles who belong to this object and whose
    % fullname starts with the name of this mfile:
    delete_sphandle('owner', ['^@' class(obj) '$'], ...
      'fullname', ['^' mfilename]);

    % Reinitialise at the original GUI position and figure:
    [x, y] = feval(mfilename, obj, 'init', x, y);

    % Restore the current figure:
    figure(currfig);
end;


