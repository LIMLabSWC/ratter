
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Growing nose in center time

% --- VAR NAMES: --- (do not edit this line)
% Maximum duration of center poke, in secs:
cp_max    5 	forceinit=1
% Maximum value of CP_duration reached during the last session
cp_pre	2
% Fractional increment in center poke duration every time there is a non-cp-violation trial:
cp_fraction           0.002
% Minimum increment (in secs) in center poke duration every time there is a non-cp-violation trial:
cp_minimum_increment  0.001

% Minimum CP_duration at which a settling_in legal_cbreak is different to
% the regular legal_cbreak:
start_settling_in_at      0.5
% Once we've reached CP_duration > start_settling_in_at, the parameters of
% the settling in:
settling_in_time          0.25
settling_in_legal_cbreak  0.2

% --- TRAINING STRING: --- (do not edit this line)
if n_done_trials ==1
	cp_pre.value=value(SideSection_CP_duration);
	SideSection_CP_duration.value = 0.5;
elseif n_done_trials > 1 && n_done_trials <20 ...
        && ~violation_history(end)   && SideSection_CP_duration < cp_max
	slope = (value(cp_pre)-0.5)/19;
	SideSection_CP_duration.value = n_done_trials*slope + 0.5;
	end
elseif n_done_trials>20
	if ~violation_history(end) && SideSection_CP_duration < cp_max,
		increment = SideSection_CP_duration*cp_fraction;
		if increment < cp_minimum_increment,
			increment = value(cp_minimum_increment);
		end;
		SideSection_CP_duration.value = SideSection_CP_duration + increment;
	end;

	if SideSection_CP_duration >= start_settling_in_at
		SideSection_SettlingIn_time.value       = value(settling_in_time);
		SideSection_settling_legal_cbreak.value = value(settling_in_legal_cbreak);
	else
		SideSection_SettlingIn_time.value       = 0;
		SideSection_settling_legal_cbreak.value = value(SideSection_legal_cbreak);
	end;
end

% --- END-OF-DAY LOGIC: -- (do not edit this line)



% --- COMPLETION STRING: --- (do not edit this line)
0


