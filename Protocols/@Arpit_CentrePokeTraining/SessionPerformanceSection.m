% [x, y] = SessionPerformanceSection(obj, action, x,y)
%
% Reports overall performance. Uses training_stage from SideSection.
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
%          [ntrials, violation_rate, left_hit_frac, right_hit_frac, hit_frac]
%
%

% CDB, 23-March-2013

function [x, y] = SessionPerformanceSection(obj, action, x,y)

GetSoloFunctionArgs(obj);

switch action
	
	% ------------------------------------------------------------------
	%              INIT
	% ------------------------------------------------------------------
	
	case 'init'
		
		SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)], 'saveable', 0);

		DispParam(obj, 'ntrials', 0, x, y,'label','Session Trials', 'TooltipString', ...
			'trials done in this session'); 
        next_row(y);
        DispParam(obj, 'ntrials_stage', 0, x, y,'label','Stage Trials', 'TooltipString', ...
			'trials completed in this training stage'); 
        next_row(y);
        DispParam(obj, 'ntrials_stage_today', 0, x, y,'label','Stage Trials Today', 'TooltipString', ...
			'trials completed in this training stage'); 
        next_row(y);
		DispParam(obj, 'violation_rate', 0, x, y,'label','Session Violation', 'TooltipString', ...
			'Fraction of trials with a center poke violation in this session'); 
        next_row(y);
        DispParam(obj, 'timeout_rate', 0, x, y,'label','Session Timeout', 'TooltipString', ...
			'Fraction of trials with timeout in this session'); 
        next_row(y);
		DispParam(obj, 'violation_recent', 0, x, y,'label','Recent Violation', 'TooltipString', ...
			'Fraction of trials with a center poke violation in the past 20 trials'); 
        next_row(y);
		DispParam(obj, 'timeout_recent', 0, x, y,'label','Recent Timeout', 'TooltipString', ...
			'Fraction of trials with a center poke violation in the past 20 trials'); 
        next_row(y);
		DispParam(obj, 'violation_stage', 0, x, y,'label','Stage Violation', 'TooltipString', ...
			'Fraction of violations in this training stage'); 
        next_row(y);
		DispParam(obj, 'timeout_stage', 0, x, y,'label','Stage Timeout', 'TooltipString', ...
			'Fraction of timeouts in this training stage'); 
        next_row(y);
		SubheaderParam(obj, 'title', 'Overall Performance', x, y);
		next_row(y, 1.5);
		SoloParamHandle(obj, 'previous_parameters', 'value', []);
		
	% ------------------------------------------------------------------
	%              evaluate
	% ------------------------------------------------------------------

	case 'evaluate'
		
        if n_completed_trials >= 1
            this_stage_trial_counter_today = value(stages_trial_counter_today);
            this_stage_trial_counter = value(stages_trial_counter);
            ntrials_stage.value = this_stage_trial_counter(value(training_stage));
            ntrials_stage_today.value = this_stage_trial_counter_today(value(training_stage));

            this_stage_timeout_percent = value(stages_timeout_rate);
            this_stage_violation_percent = value(stages_violation_rate);
            violation_stage.value = this_stage_violation_percent(value(training_stage));
            timeout_stage.value = this_stage_timeout_percent(value(training_stage));
        end

        switch value(training_stage)
            case 1                  %%  center led on -> poke in the center -> go cue -> reward light and sound
                if n_completed_trials > 1
                    ntrials.value        = n_completed_trials;
                    violation_rate.value = nan;
                    timeout_rate.value = nan;
                end
                violation_recent.value = nan;
                timeout_recent.value = nan;

                violation_stage.value = nan;
                timeout_stage.value = nan;

                
            case {2,3}                  %%  center led on -> poke in the center -> go cue -> reward light and sound
                if n_completed_trials > 1
                    ntrials.value        = n_completed_trials;
                    violation_rate.value = nan;
                    timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
                end

                violation_recent.value = nan;
                violation_stage.value = nan;

                if n_completed_trials >= 20
                    timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
                else
                    timeout_recent.value = nan;
                end

            
            case {4,5,6,7,8}        

                if n_completed_trials > 1
                    ntrials.value        = n_completed_trials;
                    violation_rate.value = numel(find(violation_history))/n_completed_trials;
                    timeout_rate.value = numel(find(timeout_history))/n_completed_trials;
                end

                if n_completed_trials >= 20
                    timeout_recent.value = numel(find(timeout_history(end-19:end)))/20;
                    violation_recent.value = numel(find(violation_history(end-19:end)))/20;
                else
                    timeout_recent.value = nan;
                    violation_recent.value = nan;
                end
                
        end
		
        if nargout > 0
            x = [n_completed_trials, value(ntrials_stage), value(violation_rate), value(timeout_rate), value(violation_recent), ...
                value(timeout_recent), value(violation_stage), value(timeout_stage)];
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


