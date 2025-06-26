

function [x, y] = StimulusSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action

    % ------------------------------------------------------------------
    %              INIT
    % ------------------------------------------------------------------

    case 'init'
        if length(varargin) < 2
            error('Need at least two arguments, x and y position, to initialize %s', mfilename);
        end
        x = varargin{1}; y = varargin{2};

        ToggleParam(obj, 'StimulusShow', 0, x, y, 'OnString', 'Stimuli Show', ...
            'OffString', 'Stimuli Hidden', 'TooltipString', 'Show/Hide Stimulus panel');
        set_callback(StimulusShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
        next_row(y);

        oldx=x; oldy=y;    parentfig=double(gcf);

        SoloParamHandle(obj, 'myfig', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'],...
            'MenuBar', 'none', 'Name', mfilename), 'saveable', 0);
        screen_size = get(0, 'ScreenSize');
        set(value(myfig),'Position',[1 screen_size(4)-740, 400 400]); % put fig at top right
        set(double(gcf), 'Visible', 'off');

        SoundManagerSection(obj, 'declare_new_sound', 'StimAUD1')
        SoloParamHandle(obj, 'thisstim', 'value', []);
        SoloParamHandle(obj, 'thisstimlog', 'value', []);
        SoloParamHandle(obj, 'h1', 'value', []);

        x = 10; y=5;

        next_row(y);
        next_row(y);
        PushbuttonParam(obj, 'refresh_stimuli', x,y , 'TooltipString', 'Instantiates the stimuli given the new set of parameters');
        set_callback(refresh_stimuli, {mfilename, 'plot_stimuli'});


        next_row(y);
        next_row(y);
        MenuParam(obj, 'Rule', {'S1>S_boundary Left','S1>S_boundary Right'}, ...
            'S1>S_boundary Left', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nThis buttom determines the rule\n', ...
            '\n''S1>S_boundary Left'' means if Aud1 > Aud_boundry then reward will be delivered from the left water spout and if Aud1 < Aud_boundry then water comes from right\n',...
            '\n''S1>S_boundary Right'' means if Aud1 < Aud_boundry then reward will be delivered from the left water spout and if Aud1 > Aud_boundry then water comes from right\n']));
        next_row(y, 1);next_row(y, 1);

        MenuParam(obj, 'Prob_Dist_Left',  {'Uniform','Exponential','Half Normal','Normal','Sinusoidal','Anti Exponential','Anti Half Normal','Anti Sinusoidal'}, ...
            'Uniform', x, y,'label','Left Dist', 'labelfraction', 0.35, 'TooltipString', sprintf(['\n Different Probability Distributions for Category A.\n', ...
            '\n''Normal - the mean is at mid point of range. Half Normal - truncated normal with mean at boundary.\n',...
            '\n''Anti Half Normal - the mean/max is at the side edge of the range.\n',...
            '\n''Sinosidal - using sine function instead of half normal and Anti Sinusoidal is when max is at the edge, same as anti half normal.\n']));
        set_callback(Prob_Dist_Left, {mfilename, 'Cal_Mean'});
        next_row(y);
        DispParam(obj, 'mean_Left', 0.01, x,y,'label','μ Left','TooltipString','mean/max log stim value for the left side distribution');
    	next_row(y);
        DispParam(obj, 'sigma_Left', 0.01, x,y,'label','σ Left','TooltipString','sigma value(log) for normal distribution for the left side distribution');
        next_row(y);
        NumeditParam(obj, 'sigma_range_Left', 1, x,y,'label','3σ Left','TooltipString',sprintf(['\n A way to reduce the range and increase more distribution towards mean\n', ...
           '\n''signifying 3 Sigma (99.7%%) value for the left side distribution, \n',...
           '\n''A value b/w range [0.2 - 1] is acceptable.']));
    	set_callback(sigma_range_Left, {mfilename, 'Cal_Sigma'});
        next_row(y); next_row(y);

        MenuParam(obj, 'Prob_Dist_Right', {'Uniform','Exponential','Half Normal','Normal','Sinusoidal','Anti Exponential','Anti Half Normal','Anti Sinusoidal'}, ...
            'Uniform', x, y, 'label','Right Dist', 'labelfraction', 0.35, 'TooltipString', sprintf(['\n Different Probability Distributions for Category A.\n', ...
            '\n''Normal - the mean is at mid point of range (side edge - boundary). Half Normal - truncated normal with mean at boundary.\n',...
            '\n''Anti Half Normal - the mean/max is at the side edge of the range.\n',...
            '\n''Sinosidal - using sine function instead of half normal and Anti Sinusoidal is when max is at the edge, same as anti half normal']));
        set_callback(Prob_Dist_Right, {mfilename, 'Cal_Mean'});
        next_row(y);
        DispParam(obj, 'mean_Right', 0.01, x,y,'label','μ Right','TooltipString','mean/max log stim value for the right side distribution');
    	next_row(y);
        DispParam(obj, 'sigma_Right', 0.01, x,y,'label','σ Right','TooltipString','sigma value (log) for normal distribution for the right side distribution');
        next_row(y);
        NumeditParam(obj, 'sigma_range_Right', 1, x,y,'label','3σ Right','TooltipString',sprintf(['\n A way to reduce the range and increase more distribution towards mean\n', ...
            '\n''signifying 3 Sigma (99.7 %%) value for the right side distribution, \n',...
            '\n''A value b/w range [0.2 - 1] is acceptable.']));
    	set_callback(sigma_range_Right, {mfilename, 'Cal_Sigma'});
        next_row(y);

        next_column(x);
        y=5;
        next_row(y, 1)
        MenuParam(obj, 'filter_type', {'GAUS','LPFIR', 'FIRLS','BUTTER','MOVAVRG','KAISER','EQUIRIP','HAMMING'}, ...
            'GAUS', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nDifferent filters. ''LPFIR'': lowpass FIR ''FIRLS'': Least square linear-phase FIR filter design\n', ...
            '\n''BUTTER'': IIR Butterworth lowpass filter ''GAUS'': Gaussian filter (window)\n', ...
            '\n''MOVAVRG'': Moving average FIR filter ''KAISER'': Kaiser-window FIR filtering\n', ...
            '\n''EQUIRIP'':Eqiripple FIR filter ''HAMMING'': Hamming-window based FIR']));
        next_row(y);
    	NumeditParam(obj,'fcut',110,x,y,'label','fcut','TooltipString','Cut off frequency on the original white noise');
        next_row(y);
    	NumeditParam(obj,'lfreq',2000,x,y,'label','Modulator_LowFreq','TooltipString','Lower bound for the frequency modulator');
    	next_row(y);
    	NumeditParam(obj,'hfreq',20000,x,y,'label','Modulator_HighFreq','TooltipString','Upper bound for the frequency modulator');
        next_row(y);
        NumeditParam(obj,'minS1',0.007,x,y,'label','minS1','TooltipString','min sigma value for AUD1');
        set_callback(minS1, {mfilename, 'Cal_Boundary'});
        next_row(y);
    	NumeditParam(obj,'maxS1',0.05,x,y,'label','maxS1','TooltipString','max sigma value for AUD1');
        set_callback(maxS1, {mfilename, 'Cal_Boundary'});
        next_row(y);
        DispParam(obj, 'A1_sigma', 0.01, x,y,'label','A1_sigma','TooltipString','Sigma value for the first stimulus');
    	next_row(y);
    	NumeditParam(obj,'minF1',4,x,y,'label','minF1','TooltipString','min frequency value for AUD1');
        set_callback(minF1, {mfilename, 'Cal_Boundary'});
        next_row(y);
    	NumeditParam(obj,'maxF1',10,x,y,'label','maxF1','TooltipString','max frequency value for AUD1');
        set_callback(maxF1, {mfilename, 'Cal_Boundary'});
        next_row(y); 
        NumeditParam(obj,'volumeF1',0.007,x,y,'label','VolumeF1','TooltipString','volume of tone for AUD1');
        next_row(y);
        DispParam(obj, 'A1_freq', 0.01, x,y,'label','A1_freq','TooltipString','Sigma value for the first stimulus');
    	next_row(y);
    	DispParam(obj,'boundary',-3.9,x,y,'label','boundary(log)','TooltipString','decision boundary for categorisation (log)');
        next_row(y);
        MenuParam(obj, 'mu_location', {'center', 'side'}, ...
            'center', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf('\nLocation of boundary'));
        set_callback(mu_location, {mfilename, 'Cal_Boundary'});
        next_row(y);
        ToggleParam(obj, 'frequency_categorization', 0, x,y,...
            'OnString', 'Frequency(Tone)',...
            'OffString', 'Amplitude(Noise)',...
            'TooltipString', sprintf('If on (black) then it enables the presentation of pure tones'));
        set_callback(frequency_categorization, {mfilename, 'FrequencyCategorization'});
        make_invisible(maxF1);make_invisible(minF1);make_invisible(A1_freq);make_invisible(volumeF1);
        next_row(y);
        
        % next_column(y)
        SoloParamHandle(obj, 'stim_dist_fig', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
            'Name', 'StimulusPlot'), 'saveable', 0);
        set(double(gcf), 'Visible', 'off');
        ax = axes(value(stim_dist_fig),'Position',[0.1 0.1 0.8 0.8]);
        ylabel('log_e A','FontSize',16,'FontName','Cambria Math');
        set(ax,'Fontsize',15)
        xlabel('Sound Categorization','FontSize',16,'FontName','Cambria Math')
        SoloParamHandle(obj, 'ax', 'saveable', 0,  'value', ax);

        StimulusSection(obj,'plot_stimuli');

        x=oldx; y=oldy;
        figure(parentfig);
        
    case 'prepare_next_trial'
        if stimuli_on
            StimulusSection(obj,'pick_current_stimulus');
            srate=SoundManagerSection(obj,'get_sample_rate');
            Fs=srate;
            T=value(A1_time);

            if frequency_categorization
                % produce the tone
                A1_freq.value = value(thisstim);
                A1 = value(thisstimlog(n_done_trials+1));
                dur1 = A1_time*1000;
                bal=0;
                freq1=A1_freq*1000;
                vol=value(volumeF1);
                RVol=vol*min(1,(1+bal));
                LVol=vol*min(1,(1-bal));
                t=0:(1/srate):(dur1/1000);
                t = t(1:end-1);
                tw=sin(t*2*pi*freq1);
                RW=RVol*tw;
                %w=[LW;RW];
                AUD1 = RW;                
            else
                % produce noise pattern
                A1_length = round(A1_time * srate);
                A1_sigma.value = value(thisstim);
                A1 = value(thisstimlog(n_done_trials+1));
                [rawA1, rawA2, normA1, normA2]=noisestim(1,1,T,value(fcut),Fs,value(filter_type));
                modulator=singlenoise(1,T,[value(lfreq) value(hfreq)],Fs,'BUTTER');
                AUD1=normA1(1:A1_length) .* modulator(1:A1_length).*A1_sigma;
            end

            if ~isempty(AUD1)
                SoundManagerSection(obj, 'set_sound', 'StimAUD1', [AUD1';  AUD1'])
            end

            SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');

            % Plot current stimulus and move to saving stimulus history

            % if value(thisstimlog(n_done_trials+1)) > value(boundary)%value(numClass)
            %     set(value(h1), 'YData', value(A1), 'color',[0.4 0.8 0.1],'markerfacecolor',[0.4 0.8 0.1]);
            % else
            %     set(value(h1), 'YData', value(A1), 'color',[0.8 0.4 0.1],'markerfacecolor',[0.8 0.4 0.1]);
            % end

            if n_done_trials > 0
                if ~violation_history(n_done_trials) && ~timeout_history(n_done_trials)
                    StimulusSection(obj,'update_stimulus_history');
                else
                    StimulusSection(obj,'update_stimulus_history_nan');
                end
            end
        end
        %% Case pick_current_stimulus
    case 'pick_current_stimulus'
        if frequency_categorization
            stim_min_log = log(value(minF1));
            stim_max_log = log(value(maxF1));
        else
            stim_min_log = log(value(minS1));
            stim_max_log = log(value(maxS1));
        end

        if strcmpi(ThisTrial, 'LEFT')
            dist_type  = value(Prob_Dist_Left);
            dist_mean  = value(mean_Left);
            dist_sigma = value(sigma_Left);
            dist_range_multiplier = value(sigma_range_Left);
            if strcmp(Rule,'S1>S_boundary Left')
                edge_max = stim_max_log;
                edge_min = value(boundary);
                edge_max = edge_min + dist_range_multiplier * (edge_max - edge_min);
            else % the rule is S1>S_boundary Right
                edge_min = stim_min_log;
                edge_max = value(boundary);
                edge_min = edge_max - dist_range_multiplier * (edge_max - edge_min);
            end

        else % trial is Right
            dist_type  = value(Prob_Dist_Right);
            dist_mean  = value(mean_Right);
            dist_sigma = value(sigma_Right);
            dist_range_multiplier = value(sigma_range_Right);
            if strcmp(Rule,'S1>S_boundary Right')
                edge_max = stim_max_log;
                edge_min = value(boundary);
                edge_max = edge_min + dist_range_multiplier * (edge_max - edge_min);
            else % the rule is S1>S_boundary Left
                edge_min = stim_min_log;
                edge_max = value(boundary);
                edge_min = edge_max - dist_range_multiplier * (edge_max - edge_min);
            end
        end

        % Create a Stimuli with the selected Distribution and Side
        switch dist_type

            case 'Uniform' % uniform distribution
                stim_i_log = random('Uniform',edge_min,edge_max);

            case 'Exponential'

                lambda = 2.153 * (edge_max - edge_min); % In mice they are using 2.153 for normalized stim range [0 1]
                stim_i_log = edge_min - 1; % preinitialize for while loop
                while stim_i_log < edge_min || stim_i_log > edge_max
                    U = rand(1);
                    if edge_min == value(boundary) % exponentially decreasing
                        stim_i_log = edge_min + (-(1/lambda)*log(U)); % the distribution would be between range [0 1], so added the edge_min
                    else
                        stim_i_log = edge_max - (-(1/lambda)*log(U));
                    end
                end

            case 'Anti Exponential'

                lambda = 2.153 * (edge_max - edge_min); % In mice they are using 2.153 for normalized stim range [0 1]
                stim_i_log = edge_min - 1; % preinitialize for while loop
                while stim_i_log < edge_min || stim_i_log > edge_max
                    U = rand(1);
                    if edge_min == value(boundary) % exponentially decreasing
                        stim_i_log = edge_max - (-(1/lambda)*log(U)); % the distribution would be between range [0 1], so added the edge_min
                    else
                        stim_i_log = edge_min - ((1/lambda)*log(U));
                    end
                end

            case 'Half Normal'
                if edge_min == value(boundary)
                    stim_i_log = random('Half Normal',dist_mean,dist_sigma);
                    while stim_i_log < edge_min || stim_i_log > edge_max
                        stim_i_log = random('Half Normal',dist_mean,dist_sigma);
                    end
                else
                    stim_i_log = CreateSamples_from_Distribution('normal',dist_mean,dist_sigma,edge_min,edge_max,1);
                end

            case 'Anti Half Normal'

                stim_i_log = CreateSamples_from_Distribution('normal',dist_mean,dist_sigma,edge_min,edge_max,1);

            case 'Normal'
                stim_i_log = random('Normal',dist_mean,dist_sigma);
                while stim_i_log < edge_min || stim_i_log > edge_max
                    stim_i_log = random('Normal',dist_mean,dist_sigma);
                end

            case 'Sinusoidal' | 'Anti Sinusoidal'

                stim_i_log = CreateSamples_from_Distribution('Sinusoidal',dist_mean,dist_sigma,edge_min,edge_max,1);

        end

        thisstim.value=exp(stim_i_log);
        thisstimlog(n_done_trials+1) = stim_i_log;

        %% Case plot stimuli distribution
    case 'plot_stimuli'

         if frequency_categorization
            stim_min_log = log(value(minF1));
            stim_max_log = log(value(maxF1));
        else
            stim_min_log = log(value(minS1));
            stim_max_log = log(value(maxS1));
        end

            dist_range_multiplier_left = value(sigma_range_Left);
            dist_range_multiplier_right = value(sigma_range_Right);

            if strcmp(Rule,'S1>S_boundary Left')
                edge_max_left = stim_max_log;
                edge_min_left = value(boundary);
                edge_max_left = edge_min_left + dist_range_multiplier_left * (edge_max_left - edge_min_left);
                edge_max_right = value(boundary);
                edge_min_right = stim_min_log;
                edge_min_right = edge_max_right - dist_range_multiplier_right * (edge_max_right - edge_min_right);

            else % the rule is S1>S_boundary Right

                edge_min_left = stim_min_log;
                edge_max_left = value(boundary);
                edge_min_left = edge_max_left - dist_range_multiplier_left * (edge_max_left - edge_min_left);
                edge_max_right = stim_max_log;
                edge_min_right = value(boundary);
                edge_max_right = edge_min_right + dist_range_multiplier_right * (edge_max_right - edge_min_right);
            end

        
        cla(value(ax))
        
        StimuliDistribution_plot(value(ax),[stim_min_log, value(boundary), stim_max_log], Rule, ...
            value(Prob_Dist_Left),value(mean_Left),value(sigma_Left),[edge_min_left edge_max_left], ...
            value(Prob_Dist_Right),value(mean_Right),value(sigma_Right),[edge_min_right edge_max_right]);

        hold (value(ax),'on')
        xline([stim_min_log value(boundary) stim_max_log],'-',{'Stim Min','Boundary','Stim Max'});

        ylabel('log_e A','FontSize',16,'FontName','Cambria Math');
        set(value(ax),'Fontsize',15)
        xlabel('Sound Categorization','FontSize',16,'FontName','Cambria Math')

        % plot(xd,stim_min_log,'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
        % hold on
        % plot(xd,stim_max_log,'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
        % line([0,2], [value(boundary),value(boundary)]);
        % axis square
        % set(value(ax),'ytick',([stim_min_log, stim_max_log]),'xtick',xd);
        % set(value(ax),'yticklabel',([stim_min, stim_max]),'xticklabel','S1');
        % ylabel('\sigma_1 in log scale','FontSize',16,'FontName','Cambria Math');
        % set(value(ax),'Fontsize',15)
        % xlabel('S1','FontSize',16,'FontName','Cambria Math')


    %% Boundary Calculate
    case 'Cal_Boundary'
        if frequency_categorization
            val_boundary = (log(value(minF1)) + log(value(maxF1)))/2;
            min_val = log(value(minF1));
        else
            val_boundary = (log(value(minS1)) + log(value(maxS1)))/2;
            min_val = log(value(minS1));
        end
        if strcmp(mu_location,'center')
            boundary.value = val_boundary;
        elseif strcmp(mu_location,'side')
            boundary.value = (min_val + val_boundary)/2;
        end
        
        StimulusSection(obj,'Cal_Mean'); % update the mean and sigma values for each side

    %% Updated Mean/Max for Each Side based upon Distribution Selected
    case 'Cal_Mean'

        if frequency_categorization
            edge_max = log(value(maxF1));
            edge_min = log(value(minF1));
        else
            edge_max = log(value(maxS1));
            edge_min = log(value(minS1));
        end

        % Calculation for Left Side
        
        % Sigma

        dist_sigma_multiplier = value(sigma_range_Left);
        if dist_sigma_multiplier < 0.2
            dist_sigma_multiplier = 0.2;
        end
        if dist_sigma_multiplier > 1
            dist_sigma_multiplier = 1;
        end

        if strcmp(Rule,'S1>S_boundary Left')
            edge_min_left = value(boundary);
            edge_max_left = edge_min_left + dist_sigma_multiplier * (edge_max - edge_min_left);
        else % the rule is S1>S_boundary Right
            edge_max_left = value(boundary);
            edge_min_left = edge_max_left - dist_sigma_multiplier * (edge_max_left - edge_min);
        end

        sigma_Left.value = (edge_max_left - edge_min_left) / 3; % as we asked user to provide 3 sigma

        % Mean
        if matches(value(Prob_Dist_Left),{'Uniform','Half Normal','Sinusoidal','Exponential'})
            mean_Left.value = value(boundary);
        else
            if strcmp(Rule,'S1>S_boundary Left')
                if matches(Prob_Dist_Left,{'Anti Half Normal','Anti Sinusoidal','Anti Exponential'})
                    mean_Left.value = edge_max_left;
                elseif matches(Prob_Dist_Left,'Normal')
                    mean_Left.value = (edge_max_left + value(boundary))/2;
                end
            else
                if matches(value(Prob_Dist_Left),{'Anti Half Normal','Anti Sinusoidal','Anti Exponential'})
                    mean_Left.value = edge_min_left;
                elseif matches(value(Prob_Dist_Left),'Normal')
                    mean_Left.value = (edge_min_left + value(boundary))/2;
                end
            end
        end
        
        % Calculation for Right Side
        
        % Sigma
        dist_sigma_multiplier = value(sigma_range_Right);
        if dist_sigma_multiplier < 0.2
            dist_sigma_multiplier = 0.2;
        end
        if dist_sigma_multiplier > 1
            dist_sigma_multiplier = 1;
        end
        
        if strcmp(Rule,'S1>S_boundary Right')
            edge_min_right = value(boundary);
            edge_max_right = edge_min_right + dist_sigma_multiplier * (edge_max - edge_min_right);
        else % the rule is S1>S_boundary Right
            edge_max_right = value(boundary);
            edge_min_right = edge_max_right - dist_sigma_multiplier * (edge_max_right - edge_min);
        end

        sigma_Right.value = (edge_max_right - edge_min_right) / 3; % as we asked user to provide 3 sigma


        % Mean
        if matches(value(Prob_Dist_Right),{'Uniform','Half Normal','Sinusoidal','Exponential'})
            mean_Right.value = value(boundary);
        else
            if strcmp(Rule,'S1>S_boundary Right')
                if matches(value(Prob_Dist_Right),{'Anti Half Normal','Anti Sinusoidal','Anti Exponential'})
                    mean_Right.value = edge_max_right;
                elseif matches(value(Prob_Dist_Right),'Normal')
                    mean_Right.value = (edge_max_right + value(boundary))/2;
                end
            else
                if matches(value(Prob_Dist_Right),{'Anti Half Normal','Anti Sinusoidal','Anti Exponential'})
                    mean_Right.value = edge_min_right;
                elseif matches(Prob_Dist_Right,'Normal')
                    mean_Right.value = (edge_min_right + value(boundary))/2;
                end
            end
        end
        
    %% Calculate Sigma
    case 'Cal_Sigma'

        if frequency_categorization
            edge_max = log(value(maxF1));
            edge_min = log(value(minF1));
        else
            edge_max = log(value(maxS1));
            edge_min = log(value(minS1));
        end

        % Calculation for Left Side Sigma
        dist_sigma_multiplier = value(sigma_range_Left);
        if dist_sigma_multiplier < 0.2
            dist_sigma_multiplier = 0.2;
        end
        if dist_sigma_multiplier > 1
            dist_sigma_multiplier = 1;
        end
        sigma_Left.value = (dist_sigma_multiplier * (edge_max - edge_min)) / 3; % as we asked user to provide 3 sigma

        % Calculation for Right Side Sigma
        dist_sigma_multiplier = value(sigma_range_Right);
        if dist_sigma_multiplier < 0.2
            dist_sigma_multiplier = 0.2;
        end
        if dist_sigma_multiplier > 1
            dist_sigma_multiplier = 1;
        end
        sigma_Right.value = (dist_sigma_multiplier * (edge_max - edge_min)) / 3; % as we asked user to provide 3 sigma


    %% Case frequency ON
    case 'FrequencyCategorization'
        if frequency_categorization == 1
            make_visible(maxF1);make_visible(minF1);make_visible(A1_freq);make_visible(volumeF1);
            make_invisible(maxS1);make_invisible(minS1);make_invisible(A1_sigma);
            make_invisible(fcut);make_invisible(lfreq);make_invisible(hfreq); make_invisible(filter_type);           
        else
            make_visible(maxS1);make_visible(minS1);make_visible(A1_sigma);
            make_visible(fcut);make_visible(lfreq);make_visible(hfreq); make_visible(filter_type);
            make_invisible(maxF1);make_invisible(minF1);make_invisible(A1_freq); make_visible(volumeF1);          
        end

        StimulusSection(obj,'Cal_Boundary'); % update the boundary
        StimulusSection(obj,'plot_stimuli');

    %% Case get_stimuli
    % case 'get_stimuli'
    %     if nargout>0
    %         x=value(S1);
    %     end


    %% Case close
    case 'close'
        set(value(myfig), 'Visible', 'off');
        set(value(stim_dist_fig), 'Visible', 'off');
        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)) %#ok<NODEF>
            delete(value(myfig));
        end
        if exist('stim_dist_fig', 'var') && isa(stim_dist_fig, 'SoloParamHandle') && ishandle(value(stim_dist_fig)) %#ok<NODEF>
            delete(value(stim_dist_fig));
        end
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

    case 'update_stimulus_history'
        ps=value(stimulus_history);
        ps(n_done_trials)=value(thisstimlog(n_done_trials));
        stimulus_history.value=ps;

    case 'update_stimulus_history_nan'
        ps=value(stimulus_history);
        ps(n_done_trials)=value(thisstimlog(n_done_trials));%nan;
        stimulus_history.value=ps;

    %% Case hide
    case 'hide'
        StimulusShow.value = 0;
        set(value(myfig), 'Visible', 'off');
        set(value(stim_dist_fig), 'Visible', 'off');

    %% Case show
    case 'show'
        StimulusShow.value = 1;
        set(value(myfig), 'Visible', 'on');
        set(value(stim_dist_fig), 'Visible', 'on');

    %% Case Show_hide
    case 'show_hide'
        if StimulusShow == 1
            set(value(myfig), 'Visible', 'on'); 
            set(value(stim_dist_fig), 'Visible', 'on');%#ok<NODEF> (defined by GetSoloFunctionArgs)
        else
            set(value(myfig), 'Visible', 'off');
            set(value(stim_dist_fig), 'Visible', 'off');
        end

end

end
