function [x, y] = BlockControl(obj, action, x, y)
% This file is mainly connected with OdorSection and RewardsSection

GetSoloFunctionArgs;
switch action,
    case 'init',
        NumeditParam(obj, 'block_size', 20, x, y, 'label','Trials/Block');
        next_row(y);
        MenuParam(obj, 'remind', {'on','off'}, 2, x, y);
        
        SoloParamHandle(obj, 'block', 'value', struct('mix_id',{1}, 'mix_diff',0,...
            'left_valve',{1}, 'right_valve',{2}, 'score', 0, 'score_lft',0, 'score_rt', 0));
        SoloParamHandle(obj, 'block_count', 'value', 1);
        SoloParamHandle(obj, 'trial_count', 'value', 0);
        next_row(y);
        NumeditParam(obj, 'score_pass',85, x, y, 'label', 'acceptable score', 'labelfraction',0.6);
        next_row(y);
        MenuParam(obj, 'block_update', {'upon_score', 'upon_block','stay','interlv', 'go_probe'}, 1,x, y);
        next_row(y);
                   
        MenuParam(obj, 'mixid_rept',{'all', 1, 2, 3, 4, 5, 6, 7, 8},'all' , x,y, 'position',[x y 100 20]);
        NumeditParam(obj,'repts', 40, x, y, 'position', [x+50 y 150 20],...
            'labelpos', 'left', 'TooltipString', 'Number of repeats for each mixture in the random condition');
        SoloParamHandle(obj, 'mix_repts', 'value', ones(1,8)*value(repts)); 
        
        SoloParamHandle(obj, 'randrepeatpool','value',[]); SoloParamHandle(obj,'init_interlv_pool','value',[]);
        SoloParamHandle(obj, 'userspecify', 'value', 0);
                SoloFunctionAddVars('OdorSection', 'ro_args', {'block', 'block_count'});
        SoloFunctionAddVars('OdorSection', 'rw_args', {'randrepeatpool', 'userspecify','block_update'});
        SoloFunctionAddVars('make_and_upload_state_matrix', 'ro_args', {'randrepeatpool'});
        set_callback({block_update, repts}, {mfilename, 'rand_interlv'});
        
%        next_row(y);
%        MenuParam(obj, 'plot_options',{'Score';'Hits';'Miss';'False'},1,x,y);
%        set_callback(plot_options, {'BlockControl', 'update_plot'});
        next_row(y);    
        SubheaderParam(obj, 'title', 'Block Control', x, y);
      
        % store the value of rat performance, with columns: Score, Hits, Miss, False
%        SoloParamHandle(obj, 'perform_left', 'value', ones(maxtrials,4)*(-1)); 
%        SoloParamHandle(obj, 'perform_right', 'value', ones(maxtrials,4)*(-1)); 
%        SoloParamHandle(obj, 'perform_overall', 'value', ones(maxtrials,4)*(-1));
        SoloParamHandle(obj, 'blk_scr_lft', 'value', []);
        SoloParamHandle(obj, 'blk_scr_rt', 'value', []);
        SoloParamHandle(obj, 'blk_scr', 'value', []);
        SoloParamHandle(obj, 'reminded', 'value', 0);
        SoloParamHandle(obj, 'after_remind', 'value', 0);        
  %      SoloFunctionAddVars('RewardsSection', 'ro_args', {'block_size','block_count','perform_left', 'perform_right',...
   %         'perform_overall','block_left','block_right','block_overall'});
        
       
  %-------- Initilize a plot monitoring rats perfomance-------------
        oldunits = get(gcf, 'Units'); set(gcf, 'Units', 'normalized');
        SoloParamHandle(obj, 'h1',  'value', axes('Position', [0.08, 0.52, 0.8, 0.25])); hold on; % axes
        % Plot performance against trial number (over sliding window)
   %     SoloParamHandle(obj, 'sliding_left',  'value', plot(-1, 1, 'b*')); hold on; %
   %     SoloParamHandle(obj, 'sliding_right',  'value', plot(-1, 1, 'mo')); hold on; %
   %     SoloParamHandle(obj, 'Legend','value',legend('Left','Right','Location',[0.09 0.74 0.12 0.06]));
        %SoloParamHandle(obj, 'perform_bars',  'value', bar(value(perform)); % bar plot of performance till now
        %set(gca,'XTickLabel',{'Score';'Hits';'Miss';'False'}, ...
        %    get(gca, 'YLabel'),'String', 'Percentage'); 
   %     SoloParamHandle(obj, 'h2',  'value', axes('Position', [0.56, 0.52, 0.4, 0.25])); % axes
        % Plot performance against trial number (over blocks)
        SoloParamHandle(obj, 'block_left',  'value', plot(-1, 1, 'b*')); hold on; %
        SoloParamHandle(obj, 'block_right',  'value', plot(-1, 1, 'm*')); hold on; %
        SoloParamHandle(obj, 'block_overall', 'value', plot(-1, 1, 'g-o','LineWidth',1)); hold on;
       % SoloParamHandle(obj, 'Legend','value',legend('Left','Right','Location','NorthWest'));
       
        set(get(value(h1), 'XLabel'),'String','Blocks');
        set(get(value(h1), 'YLabel'),'String','Percentage Score');
        title(value(h1), '        Block Average Plot','Color','b');
        
    %    set(get(value(h2), 'XLabel'),'String','Blocks');
    %    title(value(h2), 'Block Average Plot','Color','b');
        
        set_saveable({h1;block_left;block_right}, 0);
        set(gcf, 'Units', oldunits);
        BlockControl(obj, 'rand_interlv');
        
    case 'user_specify'
        % if user changed the bgrd_ID which is specified in OdorSection.m
        % change the id accordingly in block structure here.
        block(value(block_count)).mix_id = value(mix_ID);
        userspecify.value = 1;
        OdorSection(obj,'update_odor');
        reminded.value = 0;
        
    case 'rand_interlv'
        if strcmp(value(block_update),'interlv')
           if ~isempty(value(randrepeatpool))
               randrepeatpool.value = [];
           end;
           if ~ischar(value(mixid_rept))
               mix_repts(value(mixid_rept)) = value(repts);
           else
               mix_repts.value = ones(1,8)*value(repts);
           end;
           for i = 1: length(value(all_mix))
               randrepeatpool.value = [value(randrepeatpool) ones(1, mix_repts(i))*i];
           end;
           r = randperm(size(value(randrepeatpool),2));
           randrepeatpool.value = randrepeatpool(r);
       end;
       init_interlv_pool.value = value(randrepeatpool); % random permutated pool for interleaved trials
    case 'update'
        block_updated = 0;
        sides_till_now = side_list(1:n_done_trials);
        % the number of current block
        blk = value(block_count);
        % count the number of trials finished in the current block
        trial_count.value = n_done_trials - (block_count-1)*block_size;
        % store the background name to the field "bgrd" of the structure of
        % current block. The "bgrd_name" is specified in OdorSection
        block(blk).mix_diff = value(mix_diff); 
        %%%%% specify the valve ID of odor with left or right target.
        %%%%% currently correlated with bgrd ID number.
        block(blk).left_valve = value(L_valve);
        block(blk).right_valve = value(R_valve);            
        if trial_count>= block_size
            left_rw = LeftRewards(n_done_trials - block_size + 1 : n_done_trials);
            right_rw = RightRewards(n_done_trials - block_size + 1 : n_done_trials);
            left_trial_id = find(sides_till_now(n_done_trials - block_size + 1 : n_done_trials));
            right_trial_id = find(sides_till_now(n_done_trials - block_size + 1 : n_done_trials) == 0);
            
            % percent correct choice in the last block
            block(blk).score = sum(left_rw + right_rw)/block_size*100;
            blk_scr.value = [value(blk_scr) block(blk).score];
            % percent correct choice of the left trials in the last block
            block(blk).score_lft = sum(left_rw)/length(left_trial_id)*100;
            blk_scr_lft.value = [value(blk_scr_lft) block(blk).score_lft];
            % percent correct choice of the right trials in the last block
            block(blk).score_rt =  sum(right_rw)/length(right_trial_id)*100;
            blk_scr_rt.value = [value(blk_scr_rt) block(blk).score_rt];
            
            % Next update the next block upon 4 options
            
            if strcmp(value(block_update), 'upon_score')
             %   WaterDelivery.value = 3;
                    % update next block upon rats performance
                    % now with overall score
                    if block(blk).score >= score_pass
                        % change background odor to next one
                        block(blk+1).mix_id = block(blk).mix_id + 1;
                        if value(reminded)
                          block(blk+1).mix_id = value(after_remind);
                          reminded.value = 0;
                        end;
                        % if all backgrounds are run through, start from
                        % the first one again.
                        if block(blk+1).mix_id> length(value(all_mix))
                            %block(blk+1).mix_id = 1;
                            block(blk+1).mix_id = block(blk).mix_id;
                        end
                        block_updated = 1;
                   %elseif current block score <= 50, remind with pure targets
                    elseif block(blk).score <= 50 && strcmp(value(remind),'on')
                        block(blk+1).mix_id = 1;
                        after_remind.value = block(blk).mix_id;
                        reminded.value = 1;
                    else
                        block(blk+1).mix_id = block(blk).mix_id;
                    end
              %      bgrd_ID.value = block(blk+1).bgrd;
            elseif strcmp(value(block_update), 'upon_block')
              %  WaterDelivery.value = 3;
                   % update next block anyway
                    block(blk+1).mix_id = block(blk).mix_id + 1;
                    if block(blk+1).mix_id > length(value(all_mix))
                        block(blk+1).mix_id = 1;
                    end
              %      bgrd_ID.value = block(blk+1).bgrd;
                    block_updated = 1;
            
            % Not update blockwise, but with random bgrds
            elseif strcmp(value(block_update), 'interlv')
                block(blk+1).mix_id = block(blk).mix_id;
                
            elseif strcmp(value(block_update), 'stay')
                block(blk+1).mix_id = block(blk).mix_id;
                %WaterDelivery.value = 3;
                    % do nothing
          %  elseif strcmp(value(block_update), 'go_probe')
           %         WaterDelivery.value = 4;
            %        block(blk+1).bgrd = block(blk).bgrd;
             %       block_updated = 1;
            end
            
            blk = blk+1;
            block_count.value = blk;
            
           % update performance plotting
%         new_start = 1;
%        if block_updated
%            new_start = (block_count-1)*block_size+1;
%        end
%        if ~strcmp(value(block_update),'upon_block')
%            left_index = find(sides_till_now(new_start:n_done_trials));
%            right_index = find(sides_till_now(new_start:n_done_trials) == 0);
%            if length(left_index) >=block_size/2 & sides_till_now(n_done_trials)
%                perform_left(n_done_trials,2) = sum(LeftRewards(left_index(end-block_size/2+1:end))); % left hits over the last 20 trials
%                perform_left(n_done_trials,1) = (perform_left(n_done_trials,2)/block_size/2)*100; % left score over the last 20 trials
%                perform_left(n_done_trials,3) = block_size/2 - perform_left(n_done_trials,2); % left missed trials
%                perform_left(n_done_trials,4) = 0;  % not decided yet
%            end
%            if length(right_index) >= block_size/2 & ~sides_till_now(n_done_trials)
%                perform_right(n_done_trials,2) = sum(RightRewards(right_index(end-block_size/2+1:end))); % right hits over the last 20 trials
%                perform_right(n_done_trials,1) = (perform_right(n_done_trials,2)/block_size/2)*100; % ritht score over the last 20 trials
%                perform_right(n_done_trials,3) = block_size/2 - perform_right(n_done_trials,2); % right missed trials
%                perform_right(n_done_trials,4) = 0;  % not decided yet
%            end
%        end
            block_xdata = (1:blk-1);
   %         z = find(block_left_ydata < 0);
    %        block_left_x(z) = [];
    %        block_left_ydata(z) = [];
            set(value(block_left),'XData',block_xdata,'YData',value(blk_scr_lft));
            
   %         block_right_x(z) = [];
   %         block_right_ydata(z) = [];
            set(value(block_right),'XData',block_xdata,'YData',value(blk_scr_rt));
            set(value(block_overall), 'XData', block_xdata, 'YData', value(blk_scr));
            set(value(h1), 'XTick',(1:1:blk-1), 'YGrid','on');
        end
%    BlockControl('update_plot');

%    case 'update_plot'
        %temp_end = n_done_trials - BlockSize + 1;
        
%        switch value(performance_plot),
%            case 'Score'
%                sliding_left_ydata = perform_left(1:n_done_trials,1);
%                sliding_right_ydata = perform_right(1:n_done_trials,1);
        
%            case 'Hits'
%                sliding_left_ydata = perform_left(1:n_done_trials,2);
%                sliding_right_ydata = perform_right(1:n_done_trials,2);
%                y_label = '# Hits in Last Block';
%            case 'Miss'
%                sliding_left_ydata = perform_left(1:n_done_trials,3);
%                sliding_right_ydata = perform_right(1:n_done_trials,3);
%                y_label = '# Missed trials';
%            case 'False'
%                sliding_left_ydata = perform_left(1:n_done_trials,4);
%                sliding_right_ydata = perform_right(1:n_done_trials,4);
%                y_label = 'Percentage False';
%        end
        
%        sliding_left_x = (1:n_done_trials);
%        z = find(sliding_left_ydata < 0);
%        sliding_left_ydata(z) = [];
%        sliding_left_x(z) = [];
%        set(value(sliding_left),'XData', sliding_left_x, 'YData',sliding_left_ydata);
        
%        sliding_right_x = (1:n_done_trials);
%        z = find(sliding_right_ydata < 0);
%        sliding_right_ydata(z) = [];
%        sliding_right_x(z) = [];
%        set(value(sliding_right),'XData', sliding_right_x, 'YData',sliding_right_ydata);
        
        
    otherwise,
        error(['Don''t know how to handle action ' action]);
end
        
