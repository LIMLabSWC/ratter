% [] = state35(obj)    Method that gets called at the end of every trial
%
% This method assumes that it has been given read/write access to a SPH
% called n_done_trials (which will be updated by onw upon entry to
% state35.m), and read-only access to a SPH called
% trial_finished_actions. This last should be a cell vector of strings,
% each of which will be eval'd in sequence (type "help eval" at the
% Matlab prompt if you don't know what that means).
%
% If you put everything into trial_finished_actions, the code for this
% method should be universal for all protocols, and there should be no
% need for you to modify this file.
%

% CDB Feb 06


function [] = state35(obj)

    GetSoloFunctionArgs; 
    % SoloFunctionAddVars('state35', 'rw_args', 'n_done_trials', ...
    %         'ro_args', 'trial_finished_actions');
    n_done_trials.value = n_done_trials + 1;
    Trial_Counts.value = value(n_done_trials);
    for i=1:length(trial_finished_actions),
        eval(trial_finished_actions{i});
    end;    
    Write(olf_meter, 'Bank4_Valves',0);
    StopDAQ(rpbox('getstatemachine'));
  %   set(double(gca), 'ylim', [0 10]);
    
    n_started_trials.value = n_started_trials + 1;
    StartDAQ(rpbox('getstatemachine'),[1:8]);
    return;
    

