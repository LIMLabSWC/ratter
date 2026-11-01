% [x, y] = PerformanceSection(obj, action, x,y)
%
% Reports overall performance, plus the 2-step 4-cell hit table and the
% fraction of first pokes to the lit port.
%
% PARAMETERS:
% -----------
%
% action   One of:
%            'init'      To initialise the section and set up the GUI
%                        for it
%
%            'close'     Delete all of this section's GUIs and data
%
%            'reinit'    Delete all of this section's GUIs and data,
%                        and reinit, at the same position on the same
%                        figure as the original section GUI was placed.
%
%            'evalueta'  Look at history and compute hit fraction, etc.
%
% x, y     Only relevant to action = 'init'; they indicate the initial
%          position to place the GUI at, in the current figure window
%
% RETURNS:
% --------
%
% perf  When action == 'init', returns x and y, pixel positions on
%          the current figure, updated after placing of this section's GUI.
%       When action == 'evaluate', returns a vector with elements
%          [ntrials, violation_percent, left_hit_frac, right_hit_frac, hit_frac]
%
%

% CDB, 23-March-2013

function [x, y] = PerformanceSection(obj, action, x,y)

GetSoloFunctionArgs(obj);

switch action
	
	% ------------------------------------------------------------------
	%              INIT
	% ------------------------------------------------------------------
	
	case 'init'
		
		SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);

		% Two values per row (100 px each) so the section fits column 4
		DispParam(obj, 'ntrials', 0, x, y, 'position', [x y 100 20], 'label', 'trials', 'TooltipString', 'Trials done');
		DispParam(obj, 'ntrials_valid', 0, x, y, 'position', [x+100 y 100 20], 'label', 'valid', ...
			'TooltipString', 'Valid trials (not a violation, not a timeout)'); next_row(y);
		DispParam(obj, 'violation_percent', 0, x, y, 'position', [x y 100 20], 'label', 'viol', 'TooltipString', ...
			'Fraction of trials with a center poke violation');
		DispParam(obj, 'timeout_percent', 0, x, y, 'position', [x+100 y 100 20], 'label', 'timeout', 'TooltipString', ...
			'Fraction of trials with timeout'); next_row(y);
		DispParam(obj, 'Left_hit_frac', 0, x, y, 'position', [x y 100 20], 'label', 'Left hit', 'TooltipString', ...
			'Fraction of correct Left trials');
		DispParam(obj, 'Right_hit_frac', 0, x, y, 'position', [x+100 y 100 20], 'label', 'Right hit', 'TooltipString', ...
			'Fraction of correct Right trials'); next_row(y);
		DispParam(obj, 'hit_frac', 0, x, y, 'label', 'Hit fraction', 'TooltipString', ...
			'Fraction of correct trials'); next_row(y);

		% 2-step: session hit fraction in each trial cell (reward side x category)
		DispParam(obj, 'Hit_R_Loud',  NaN, x, y, 'position', [x y 100 20], 'label', 'R-Loud', 'TooltipString', 'Session hit fraction, reward right, loud');
		DispParam(obj, 'Hit_R_Quiet', NaN, x, y, 'position', [x+100 y 100 20], 'label', 'R-Quiet', 'TooltipString', 'Session hit fraction, reward right, quiet'); next_row(y);
		DispParam(obj, 'Hit_L_Loud',  NaN, x, y, 'position', [x y 100 20], 'label', 'L-Loud', 'TooltipString', 'Session hit fraction, reward left, loud');
		DispParam(obj, 'Hit_L_Quiet', NaN, x, y, 'position', [x+100 y 100 20], 'label', 'L-Quiet', 'TooltipString', 'Session hit fraction, reward left, quiet'); next_row(y);
		DispParam(obj, 'Chose_Lit', NaN, x, y, 'label', 'Chose lit port', 'TooltipString', ...
			'2-step trials: fraction of first pokes to the lit port. 0.5 = no light bias.'); next_row(y);
		SubheaderParam(obj, 'title', 'Overall Performance', x, y);
		next_row(y, 1.2);
		% SoloParamHandle(obj, 'previous_parameters', 'value', []);
        
		
	% ------------------------------------------------------------------
	%              evaluate
	% ------------------------------------------------------------------

	case 'evaluate'
		

        if n_done_trials > 1
            try
                ntrials.value        = n_done_trials;
                ntrials_valid.value = numel(find(~isnan(hit_history)));
                violation_percent.value = round(numel(find(violation_history))/n_done_trials*100)/100;
                timeout_percent.value = round(numel(find(timeout_history))/n_done_trials*100)/100;
                goods  = ~isnan(hit_history(1:n_done_trials));
                lefts  = previous_sides(1:n_done_trials)=='l';
                rights = previous_sides(1:n_done_trials)=='r';
                goods = goods(:);
                lefts = lefts(:);
                rights = rights(:);
                Left_hit_frac.value  = round(mean(hit_history(goods & lefts))*100)/100;   % 2 decimals: fits the half-width boxes
                Right_hit_frac.value = round(mean(hit_history(goods & rights))*100)/100;
                hit_frac.value       = round(mean(hit_history(goods))*100)/100;
            catch
            end
            try
                hh = value(hit_history); hh = hh(:);
                ce = value(cell_history); ce = ce(:);
                m = min(numel(hh), numel(ce)); hh = hh(1:m); ce = ce(1:m);
                names = {'Hit_L_Quiet', 'Hit_L_Loud', 'Hit_R_Quiet', 'Hit_R_Loud'};
                for c = 1:4
                    u = (ce == c) & ~isnan(hh);
                    if any(u), v = round(mean(hh(u))*100)/100; else, v = NaN; end
                    eval([names{c} '.value = v;']);
                end
                ch = value(choice_history); lh = value(light_history);
                m = min(numel(ch), numel(lh)); ch = ch(1:m); lh = lh(1:m);
                u = (lh == 'l' | lh == 'r') & (ch == 'l' | ch == 'r');
                if any(u), Chose_Lit.value = round(mean(ch(u) == lh(u))*100)/100; end
            catch
            end
        end

        if nargout > 0
            x = [n_done_trials, value(violation_percent), value(timeout_percent), value(Left_hit_frac), ...
                value(Right_hit_frac), value(hit_frac)];
        end

		
	% ------------------------------------------------------------------
	%              close
	% ------------------------------------------------------------------

	case 'close'
		% Delete all SoloParamHandles who belong to this object and whose
		% fullname starts with the name of this mfile:
		delete_sphandle('owner', ['^@' class(obj) '$'], ...
			'fullname', ['^' mfilename]);

		
	% ------------------------------------------------------------------
	%              reinit
	% ------------------------------------------------------------------

	case 'reinit'
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
		
end


