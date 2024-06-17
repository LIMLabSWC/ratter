
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Growing nose in center time

% --- VAR NAMES: --- (do not edit this line)
% Maximum duration of center poke (including Go cue), in secs:
max_total_cp    6.2 	forceinit=1
% Standard Go cue duration
target_go_cue_duration  0.2
% CP_duration reached at the end of the last session
last_session_total_cp  0
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction           0.001
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment  0.001


% Initial startup trials over which to gradually grow cp duration
% Only do the initial startup stuff if cp_duration is longer than:
cp_duration_threshold_for_initial_trials  1.5
% Number of initial trials over which to gradually grow cp duration:
n_initial_trials                          10
% Starting total center poke duration:
starting_total_cp                         0.5


% Minimum CP_duration at which a settling_in legal_cbreak is different to
% the regular legal_cbreak:
start_settling_in_at      1000
% Once we've reached CP_duration > start_settling_in_at, the parameters of
% the settling in:
settling_in_time          0
settling_in_legal_cbreak  0.05




% --- TRAINING STRING: --- (do not edit this line)

% Check to see whether we're doing the initial startup stuff. Assumes that
% we're NOT changing the Go cue duration.
if SideSection_Total_CP_duration+0.0001 < last_session_total_cp & ...
		last_session_total_cp > cp_duration_threshold_for_initial_trials,
	% Check to see whether we're done with initial stuff within numerical
	% rounding error:
	if abs(last_session_total_cp - SideSection_Total_CP_duration) < 0.0001,
		SideSection_CP_duration.value = last_session_total_cp - SideSection_time_go_cue;
	elseif ~violation_history(end),
		increment = ...
			(last_session_total_cp - starting_total_cp)/(n_initial_trials - 1);
		SideSection_CP_duration.value = SideSection_CP_duration + increment;
	end;
elseif ~violation_history(end) && SideSection_Total_CP_duration < max_total_cp,
	% We're in regular increasing territory
	increment = SideSection_Total_CP_duration*cp_fraction;
	if increment < cp_minimum_increment,
		increment = value(cp_minimum_increment);
	end;
	% If we're growing the CP duration, grow the Go cue duration first
	% until it reaches its target; after that, grow CP_duration, the
	% pre-Go cue time.
	if SideSection_time_go_cue < target_go_cue_duration,
		SideSection_time_go_cue.value = SideSection_time_go_cue + increment;
	else
		SideSection_CP_duration.value = SideSection_CP_duration + increment;
	end;
end;
% make sure the total reflects all the changes:
callback(SideSection_CP_duration);

% Double-check that we don't go over the desired max value:
if SideSection_Total_CP_duration > max_total_cp,
	SideSection_CP_duration.value = max_total_cp - SideSection_time_go_cue;
	% once again, make sure the total reflects any the changes:
	callback(SideSection_CP_duration);
end;

% Settling in code:
if SideSection_CP_duration >= start_settling_in_at
	SideSection_SettlingIn_time.value       = value(settling_in_time);
	SideSection_settling_legal_cbreak.value = value(settling_in_legal_cbreak);
else
	SideSection_SettlingIn_time.value       = 0;
	SideSection_settling_legal_cbreak.value = value(SideSection_legal_cbreak);
end;




% --- END-OF-DAY LOGIC: -- (do not edit this line)

% Store the value of the total cp duration reached:
last_session_total_cp.value = value(SideSection_Total_CP_duration);

% Check whether we're going to do the initial startup trials on the next
% day:
if SideSection_Total_CP_duration > cp_duration_threshold_for_initial_trials,
	% Yup, doing initial startup.  Set CP_duration to the necessary duration:
	SideSection_CP_duration.value = starting_total_cp - SideSection_time_go_cue;
	% Error check, make sure we don't set it to something nonsensical:
	if SideSection_CP_duration < 0.001,
		SideSection_CP_duration = 0.001;
	end;
	% Callback to make sure the calculation of Total_CP_duration is made.
	callback(SideSection_CP_duration);
end;






% --- COMPLETION STRING: --- (do not edit this line)
0





