function [x, y] = RewardsSection(obj, action, x, y);    
%
% [x, y] = InitRewards_Display(x, y, obj);    
%
% args:    x, y                 current UI pos, in pixels
%          obj                  A locsamp3obj object
%
% returns: x, y                 updated UI pos
%
% Updates (and stores) history of various measures of hit (or reward
% rates); e.g. Hit rate for Last 20 trials, # Right rewards, etc.,
% Also updates the on-screen hit-rate display
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GetSoloFunctionArgs;
% SoloFunction('RewardsSection', 'rw_args', {'LastTrialEvents', 'hit_history'}, ...
%    'ro_args', {'RealTimeStates', 'side_list', 'n_done_trials', 'n_started_trials'});

switch action,
    case 'init',

        DispParam(obj, 'LeftRewards', 0, x, y); next_row(y);
        DispParam(obj, 'RightRewards',0, x, y); next_row(y);
        DispParam(obj, 'Rewards',     0, x, y); next_row(y);
        DispParam(obj, 'Trials',      0, x, y); next_row(y);
        
        next_row(y, 0.5);
        
        DispParam(obj, 'Last10',      0, x, y); next_row(y);
        DispParam(obj, 'Last20',      0, x, y); next_row(y);
        DispParam(obj, 'Last40',      0, x, y); next_row(y);
        DispParam(obj, 'Last80',      0, x, y); next_row(y);

        LastTrialevents.value = [];
        
    case 'update',
        Trials.value = Trials + 1;
        evs = value(LastTrialEvents);
        rts = value(RealTimeStates);

        % Find first left-right response after tone:
        if isfield(rts, 'leftover_sound'),
           u = find((ismember(evs(:,1), rts.leftover_sound) | ismember(evs(:,1), rts.wait_for_apoke))  & ...
                    (evs(:,2)==3 | evs(:,2)==5));
        else
           u = find(ismember(evs(:,1), rts.wait_for_apoke)  & ...
                    (evs(:,2)==3 | evs(:,2)==5));
        end;
        if isempty(u),% no wait-for-answer poke, must've been direct delivery
            % Find dirdel state and first left-right response after that
            u  = find(ismember(evs(:,1),rts.left_dirdel)  |  ...
                 ismember(evs(:,1),rts.right_dirdel));
            if ~isempty(u), 
                u2 = find(evs(u(1):end,2)==3  |  evs(u(1):end,2)==5);
                if ~isempty(u2), 
                    u = u2(1) + u(1)-1;
                else u = [];
                end;
            end;    
        end;
        % Now, did we go right when right was correct or left when left was
        % correct?
        if isempty(u), hit_history(n_done_trials) = 0; 
        else
           if     (evs(u(1),2)==3  &  side_list(n_done_trials)==1)  |  ...
                  (evs(u(1),2)==5  &  side_list(n_done_trials)==0)  |  ...
                  (evs(u(1),2)==3  &  side_list(n_done_trials)==1.25) | ...
                  (evs(u(1),2)==5  &  side_list(n_done_trials)==0.25),
              hit_history(n_done_trials) = 1;
           else
              hit_history(n_done_trials) = 0;
           end;
        end;

        u1 = find(ismember(evs(:,1),rts.left_reward));
        u2 = find(ismember(evs(:,1),rts.right_reward));

        % Count rewards
        if ~isempty(u1), LeftRewards.value  = LeftRewards+1;  end;
        if ~isempty(u2), RightRewards.value = RightRewards+1; end;
        if ~isempty(u1) | ~isempty(u2),
            Rewards.value = Rewards+1;
        end;
        
        % Update the GUI
        for del=[10 20 40 80],
            mn = max([1 n_done_trials-del]);
            muhits = mean(hit_history(mn:n_done_trials));
            eval(['Last' num2str(del) '.value = muhits;']);
        end;    

        % Set the global parsed last trial
        prevtrial.value = parse_trial(evs, rts);
        
        % Find the reaction time
        try,
           couts      = sort(prevtrial.center1(:,2));
           sideins    = sort([prevtrial.left1(:,1);prevtrial.right1(:,1)]);
           chordstart = prevtrial.chord(1,1);
           
           % u = min(find(couts>chordstart));
           v = min(find(sideins > chordstart));
           reaction_times(n_done_trials) = sideins(v) - chordstart;
        catch,
        end;
        % reset the events store
        push_history(LastTrialEvents);
        LastTrialEvents.value = [];
        
    otherwise,
        error(['Don''t know how to handle action ' action]);
end;    

    

    

