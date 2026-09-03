

function varargout = StimulusSection(obj, action, varargin)

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
        set_callback(StimulusShow, {mfilename, 'show_hide'}); %#ok<NODEF>
        next_row(y);
        oldx=x; oldy=y;    parentfig=double(gcf);
        SoloParamHandle(obj, 'myfig', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'],...
            'MenuBar', 'none', 'Name', mfilename, 'Units', 'normalized'), 'saveable', false);
        SoundManagerSection(obj, 'declare_new_sound', 'StimAUD1')
        SoloParamHandle(obj, 'thisstim', 'value', []);
        SoloParamHandle(obj, 'thisstimlog', 'value', []);
        
        %% Formatting graphics elements
        original_width = 0.45;
        original_height = 0.75;
        max_size = min(original_width, original_height);
        aspect_ratio = original_width / original_height;
        new_width = max_size;
        new_height = new_width / aspect_ratio;
        center_x = 0.5 - (new_width / 2);
        center_y = 0.5 - (new_height / 2);
        position_vector = [center_x center_y new_width new_height];
        set(value(myfig), 'Units', 'normalized', 'Name', mfilename, 'Position', position_vector);
        set(double(gcf), 'visible', 'off');
       

        % =========================================================
        % COLUMN 1: CONTINUOUS MODE PARAMS
        % =========================================================
        
        x = 10; y=5;
        next_row(y);
        
        NumeditParam(obj,'P_centre_region',0,x,y,'label','P_centre','TooltipString','probability for choosing stim near boundary. 0 = same probability as the rest, 1 = only choose from centre');
        next_row(y);
        NumeditParam(obj,'centre_region_width',0.1,x,y,'label','Centre Width','TooltipString','total width around boundary to be considered as central region');
        next_row(y);next_row(y);

        MenuParam(obj, 'Prob_Dist_Left',  {'Uniform','Exponential','Half Normal','Normal','Sinusoidal','Anti Exponential','Anti Half Normal','Anti Sinusoidal'}, ...
            'Uniform', x, y,'label','Left Dist', 'labelfraction', 0.35, 'TooltipString', sprintf(['\n Different Probability Distributions for Category A.\n', ...
            '\n''Normal - the mean is at mid point of range. Half Normal - truncated normal with mean at boundary.\n',...
            '\n''Anti Half Normal - the mean/max is at the side edge of the range.\n',...
            '\n''Sinosidal - using sine function instead of half normal and Anti Sinusoidal is when max is at the edge, same as anti half normal.\n']));
        set_callback(Prob_Dist_Left, {mfilename, 'Cal_Mean'});
        next_row(y);
        DispParam(obj, 'mean_Left', 0.01, x,y,'label','μ Left','TooltipString','mean/max log stim value for the left side distribution');
        next_row(y);
        NumeditParam(obj, 'sigma_Left', 0.15, x,y,'label','σ Left','TooltipString','sigma value for normal/half normal distribution or decay rate for exponential for the left side distribution');
        next_row(y);
        NumeditParam(obj, 'sigma_range_Left', 1, x,y,'label','Left Range','TooltipString',sprintf(['\n A way to reduce the range and increase more distribution towards mean\n', ...
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
        NumeditParam(obj, 'sigma_Right', 0.15, x,y,'label','σ Right','TooltipString','sigma value for normal/half normal distribution or decay rate for exponential for the left side distribution');
        next_row(y);
        NumeditParam(obj, 'sigma_range_Right', 1, x,y,'label','Right Range','TooltipString',sprintf(['\n A way to reduce the range and increase more distribution towards mean\n', ...
            '\n''signifying 3 Sigma (99.7 %%) value for the right side distribution, \n',...
            '\n''A value b/w range [0.2 - 1] is acceptable.']));
        set_callback(sigma_range_Right, {mfilename, 'Cal_Sigma'});
        next_row(y);next_row(y);
        MenuParam(obj, 'Category_Dist', {'Uniform','Hard A','Hard B'}, ...
            'Uniform', x, y, 'label','Category Dist', 'labelfraction', 0.35, 'TooltipString', sprintf(['\n Different Distributions for Category.\n', ...
            '\n''Depending upon the rule it will change switch the distributions for Left and Right.\n',...
            '\n''If its uniform on both then it will change the distribution to Exponential on one of the side\n',...
            '\n''depending upon the choice of rule']));
        set_callback(Category_Dist, {mfilename, 'Distribution_Switch'});
        next_row(y);next_row(y);
        PushbuttonParam(obj, 'plot_stim_dist', x,y , 'TooltipString', 'Plots the distribution with the new set of parameters');
        set_callback(plot_stim_dist, {mfilename, 'plot_stim_distribution'});

        % =========================================================
        % COLUMN 2: DISCRETE & FIXED PARAMS
        % =========================================================
        next_column(x); y=5; 
        next_row(y);
        
        % Discrete Params (Top of Col 2)
        NumeditParam(obj, 'n_discrete', 8, x, y, 'label', 'Stims/Side');
        next_row(y);
        NumeditParam(obj, 'boundary_fraction', 0.0, x, y, 'label', 'Bound. Offset');
        
        % Push 'y' down to visually align inside the Fixed Mode panel
        next_row(y); next_row(y); next_row(y); next_row(y); next_row(y);
        
        % Fixed Params (Bottom of Col 2)
        NumeditParam(obj,'FixedStim',0.028,x,y,'label','FixedStimValue');

        % =========================================================
        % COLUMN 3: GLOBAL STIMULUS PARAMS
        % =========================================================
        next_column(x); y=5;
        next_row(y);

        MenuParam(obj, 'Rule', {'S1>S_boundary Left','S1>S_boundary Right'}, ...
            'S1>S_boundary Left', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nThis buttom determines the rule\n', ...
            '\n''S1>S_boundary Left'' means if Aud1 > Aud_boundry then reward will be delivered from the left water spout and if Aud1 < Aud_boundry then water comes from right\n',...
            '\n''S1>S_boundary Right'' means if Aud1 < Aud_boundry then reward will be delivered from the left water spout and if Aud1 > Aud_boundry then water comes from right\n']));
        next_row(y);next_row(y);

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
    	DispParam(obj,'boundary',-3.9788,x,y,'label','boundary(log)','TooltipString','decision boundary for categorisation (log)');
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
        
        % Axes for Plotting
        hndl_uipanelplotaxes = uipanel('Units', 'normalized');
        set(hndl_uipanelplotaxes, ...
                'Units', 'normalized', ...
                'Parent', value(myfig), ...
                'Title', 'Stimuli Distribution', ...
                'Tag', 'uipanelstimplot', ...
                'Position', [0.06,0.52,0.8,0.42]);

        SoloParamHandle(obj, 'axstimplot', 'value', axes(hndl_uipanelplotaxes,'Units', 'normalized','Position', [0.07,0.07, ...
            0.8,0.85]), 'saveable', false);
        
        SoloParamHandle(obj, 'checkboxHist', 'value', ...
                uicontrol('Parent', hndl_uipanelplotaxes, ...
                'Units', 'normalized', ...
                'Style', 'checkbox', ...
                'String', 'Histogram', ...
                'TooltipString', 'Show/hide histogram', ...
                'Value', 0, ...
                'Tag', 'checkboxHist', ...
                'Position', [0.9     0.3    0.1     0.12]), ...
                'saveable', false);
        
        SoloParamHandle(obj, 'checkboxLegends', 'value', ...
                uicontrol('Parent', hndl_uipanelplotaxes, ...
                'Units', 'normalized', ...
                'Style', 'checkbox', ...
                'String', 'Legends', ...
                'TooltipString', 'Show/hide legends', ...
                'Value', 0, ...
                'Tag', 'checkboxlegend', ...
                'Position', [0.9     0.5    0.1     0.12]), ...
                'saveable', false);

        SoloParamHandle(obj, 'checkboxStim', 'value', ...
                uicontrol('Parent', hndl_uipanelplotaxes, ...
                'Units', 'normalized', ...
                'Style', 'checkbox', ...
                'String', 'ThisStim', ...
                'TooltipString', 'Show/hide present stim', ...
                'Value', 0, ...
                'Tag', 'checkboxStim', ...
                'Position', [0.9     0.7    0.1     0.12]), ...
                'saveable', false);

        SoloParamHandle(obj, 'plot_h', 'value', struct(), 'saveable', false); % Initialize output

        StimulusSection(obj,'Stimuli_State_change');

        % Plot the Distribution
        if strcmpi(Stimuli_State,'Full')
            StimulusSection(obj,'plot_stim_distribution');
            set(value(myfig), 'visible', 'off');
        end

        x=oldx; y=oldy;
        figure(parentfig);
        
        SoloFunctionAddVars('PsychometricSection', 'ro_args',{'Category_Dist';'Rule';'boundary';'n_discrete'});
            
        varargout{1} = x;
        varargout{2} = y;

    case 'prepare_next_trial'
        
        if ~strcmpi(Stimuli_State,'No Sound') % either distribution or fixed sound
            
             if strcmpi(Stimuli_State,'Full') % only run here if user selected full distribution
                StimulusSection(obj,'pick_current_continuous_stimulus');
             elseif strcmpi(Stimuli_State,'Discrete') % only run here if user selected discrete distribution
                StimulusSection(obj,'pick_current_discrete_stimulus');
             elseif strcmpi(Stimuli_State,'Fixed Stimuli') % only run here if user selected fixed
                StimulusSection(obj,'pick_current_fixed_stimulus');
             end
             
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
                A1_length = floor(T * srate);
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

            if n_done_trials > 0
                
                StimulusSection(obj,'update_stimulus_history');
                
                % Update the stim histogram and show chosen stimuli

                if value(StimulusShow) == 1 & strcmpi(Stimuli_State,'Full') % only run if the figure window is open and we have full distrubution

                    stim_values = value(thisstimlog);
                    stim_present = stim_values(n_done_trials);
                    stim_history = stim_values(1:end-1);

                    % figure out if legends,present stim and histogram to be plotted or not
                    legend_obj = value(checkboxLegends);
                    legend_draw = logical(legend_obj.Value);
                    
                    if n_done_trials < 10
                        hist_draw = false;
                    else
                        hist_obj = value(checkboxHist);
                        hist_draw = logical(hist_obj.Value);
                    end

                    stim_obj = value(checkboxStim);
                    stim_draw = logical(stim_obj.Value);
                    
                    if hist_draw || stim_draw
                        [~,~, handle_h] = CreateSamples_from_Distribution(...
                            'Mode', 'update_plot', ...
                            'ax_handle', value(axstimplot), ... % Get current axes handle
                            'plot_handles_in', value(plot_h), ...
                            'current_stimulus', stim_present,...
                            'samples_history_in',stim_history,...
                            'plot_histogram', hist_draw, ...
                            'plot_chosen_stimuli', stim_draw, ...
                            'plot_distribution', true, ...
                            'plot_legend',legend_draw...
                            );
                        plot_h.value = handle_h;
                        drawnow;
                        pause(0.01);
                    end   
                end
            end
        end

     %% pick_current_dicrete_stimulus
    case 'pick_current_discrete_stimulus'
        
        if frequency_categorization
            stim_min_log = log(value(minF1));
            stim_max_log = log(value(maxF1));
        else
            stim_min_log = log(value(minS1));
            stim_max_log = log(value(maxS1));
        end

        if (strcmpi(ThisTrial, 'LEFT') & strcmp(Rule,'S1>S_boundary Left')) | ...
                (strcmpi(ThisTrial, 'RIGHT') & strcmp(Rule,'S1>S_boundary Right'))

            edge_max = stim_max_log;
            edge_min = value(boundary);
            % edge_max is the non-boundary edge (away from boundary)
            non_boundary_edge = edge_max;
        else
            edge_min = stim_min_log;
            edge_max = value(boundary);
            % edge_min is the non-boundary edge (away from boundary)
            non_boundary_edge = edge_min;
        end

        % Generate discrete stimulus values based on NumberStimuli
        num_stimuli = value(n_discrete);

        if num_stimuli == 1
            % Single stimulus: use non-boundary edge value
            stim_i_log = non_boundary_edge;

        elseif num_stimuli == 2
            % Two values: non-boundary edge and middle
            middle_log = (edge_min + edge_max) / 2;
            stim_values = [non_boundary_edge, middle_log];
            stim_i_log = stim_values(randi(length(stim_values)));

        elseif num_stimuli == 4
            % Four values: non-boundary edge, progressively moving toward boundary
            middle_log = (edge_min + edge_max) / 2;

            if non_boundary_edge == edge_max
                % Moving from edge_max toward edge_min (boundary)
                between1 = (middle_log + edge_max) / 2;  % between middle and edge_max
                between2 = (edge_min + middle_log) / 2;  % between edge_min and middle
                stim_values = [edge_max, between1, middle_log, between2];
            else
                % Moving from edge_min toward edge_max (boundary)
                between1 = (edge_min + middle_log) / 2;  % between edge_min and middle
                between2 = (middle_log + edge_max) / 2;  % between middle and edge_max
                stim_values = [edge_min, between1, middle_log, between2];
            end
            stim_i_log = stim_values(randi(length(stim_values)));

        elseif num_stimuli == 8
            % Eight values: progressively filling from non-boundary edge toward boundary
            stim_values = linspace(non_boundary_edge, edge_min + edge_max - non_boundary_edge, num_stimuli);
            stim_i_log = stim_values(randi(length(stim_values)));

        else
            % General case: for any other NumberStimuli value
            % Create evenly distributed values from non-boundary edge toward the other edge
            other_edge = edge_min + edge_max - non_boundary_edge;
            stim_values = linspace(non_boundary_edge, other_edge, num_stimuli);
            stim_i_log = stim_values(randi(length(stim_values)));
        end


        thisstim.value=exp(stim_i_log);
        thisstimlog(n_done_trials+1) = stim_i_log;

        %% Case pick_current_stimulus
    case 'pick_current_continuous_stimulus'
            
            if frequency_categorization
                stim_min_log = log(value(minF1));
                stim_max_log = log(value(maxF1));
            else
                stim_min_log = log(value(minS1));
                stim_max_log = log(value(maxS1));
            end

            dist_sigma_left_multiplier = value(sigma_Left) * value(sigma_range_Left);
            dist_sigma_right_multiplier = value(sigma_Right) * value(sigma_range_Right);

            % The left-right side according the animal is not the same as left-right of
            % stim distribution because it depends upon the Rule whether Stim should be
            % considered left/right (below/up of boundary) based upon this rule.
            % Changing animals side reference to stimuli reference depending upon Rule
            % Even the setting in StimulusSection is based upon side not on the
            % basis of whether left or right of boundary

            if strcmp(Rule,'S1>S_boundary Left') % side left is right to stim boundary
                if strcmpi(ThisTrial, 'LEFT')
                    stim_side = 'right';
                else
                    stim_side = 'left';
                end
                dist_left = value(Prob_Dist_Right);
                dist_right = value(Prob_Dist_Left);
                range_percent_left = value(sigma_range_Right) * 100;
                range_percent_right = value(sigma_range_Left) * 100;
                dist_mean_left  = value(mean_Right);
                dist_mean_right  = value(mean_Left);
                dist_sigma_left = dist_sigma_right_multiplier * (value(boundary) - stim_min_log);
                dist_sigma_right = dist_sigma_left_multiplier * (stim_max_log - value(boundary));
                exp_decay_left = value(sigma_Right);
                exp_decay_right = value(sigma_Left);

            else % the rule is S1>S_boundary Right
                if strcmpi(ThisTrial, 'LEFT')
                    stim_side = 'left';
                else
                    stim_side = 'right';
                end
                dist_right = value(Prob_Dist_Right);
                dist_left = value(Prob_Dist_Left);
                range_percent_right = value(sigma_range_Right) * 100;
                range_percent_left = value(sigma_range_Left) * 100;
                dist_mean_right  = value(mean_Right);
                dist_mean_left  = value(mean_Left);
                dist_sigma_left = dist_sigma_left_multiplier * (value(boundary) - stim_min_log);
                dist_sigma_right = dist_sigma_right_multiplier * (stim_max_log - value(boundary));
                exp_decay_left = value(sigma_Left);
                exp_decay_right = value(sigma_Right);
            end

            if ~exist('LeftProb','var')
                LeftProb = SideSection(obj,'get_left_prob');
            end

            % Generate a single sample, explicitly chosen side 'left'
            [stim_i_log,~,~] = CreateSamples_from_Distribution(...
                'Mode', 'generate_single_sample', ...
                'chosen_side', stim_side, ... % Force pick from chosen side
                'left_edge_value', stim_min_log,...
                'boundary_value', value(boundary),...
                'right_edge_value', stim_max_log,...
                'left_probability', LeftProb, ... % These still define the overall PDF, but this pick is forced chosen side
                'right_probability', 1 - LeftProb, ...
                'left_dist_type', dist_left, ...
                'decay_rate_magnitude_left', exp_decay_left,...
                'normal_mean_left', dist_mean_left,...
                'normal_std_dev_left', dist_sigma_left,...
                'half_normal_std_dev_left', dist_sigma_left,...
                'range_percentage_left',range_percent_left , ...
                'right_dist_type', dist_right, ...
                'decay_rate_magnitude_right', exp_decay_right,...
                'normal_mean_right', dist_mean_right,...
                'normal_std_dev_right', dist_sigma_right,...
                'half_normal_std_dev_right', dist_sigma_right,...
                'range_percentage_right',range_percent_right, ...
                'P_central_region', value(P_centre_region), 'central_region_width', value(centre_region_width) ...
                );

        thisstim.value=exp(stim_i_log);
        thisstimlog(n_done_trials+1) = stim_i_log;

    case 'pick_current_fixed_stimulus' 

        stim_i_log = log(value(FixedStim));
        thisstim.value=exp(stim_i_log);
        thisstimlog(n_done_trials+1) = stim_i_log;

        %% Case plot stimuli distribution
    case 'plot_stim_distribution'

         if frequency_categorization
            stim_min_log = log(value(minF1));
            stim_max_log = log(value(maxF1));
        else
            stim_min_log = log(value(minS1));
            stim_max_log = log(value(maxS1));
         end

          dist_sigma_left_multiplier = value(sigma_Left) * value(sigma_range_Left);
          dist_sigma_right_multiplier = value(sigma_Right) * value(sigma_range_Right);

    % The left-right side according the animal is not the same as left-right of
    % stim distribution because it depends upon the Rule whether Stim should be
    % considered left/right (below/up of boundary) based upon this rule.
    % Changing animals side reference to stimuli reference depending upon Rule

        if strcmp(Rule,'S1>S_boundary Left') % side left is right to stim boundary
            dist_left = value(Prob_Dist_Right);
            dist_right = value(Prob_Dist_Left);
            range_percent_left = value(sigma_range_Right) * 100;
            range_percent_right = value(sigma_range_Left) * 100;
            dist_mean_left  = value(mean_Right);
            dist_mean_right  = value(mean_Left);
            dist_sigma_left = dist_sigma_right_multiplier * (value(boundary) - stim_min_log);
            dist_sigma_right = dist_sigma_left_multiplier * (stim_max_log - value(boundary));
            exp_decay_right = value(sigma_Left);
            exp_decay_left = value(sigma_Right);

        else % the rule is S1>S_boundary Right
            dist_right = value(Prob_Dist_Right);
            dist_left = value(Prob_Dist_Left);
            range_percent_right = value(sigma_range_Right) * 100;
            range_percent_left = value(sigma_range_Left) * 100;
            dist_mean_right  = value(mean_Right);
            dist_mean_left  = value(mean_Left);
            dist_sigma_left = dist_sigma_left_multiplier * (value(boundary) - stim_min_log);
            dist_sigma_right = dist_sigma_right_multiplier * (stim_max_log - value(boundary));
            exp_decay_left = value(sigma_Left);
            exp_decay_right = value(sigma_Right);
        end
            
          if ~exist('LeftProb','var')
            LeftProb = SideSection(obj,'get_left_prob');
          end

          % figure out if legends to be plotted or not
          legend_obj = value(checkboxLegends);
          legend_draw = logical(legend_obj.Value);


          [~,~, handle_h] = CreateSamples_from_Distribution(...
              'Mode', 'initialize_plot', ...
              'ax_handle', value(axstimplot), ... % Get current axes handle
              'plot_handles_in', value(plot_h), ...
              'plot_histogram', false, ...
              'plot_chosen_stimuli', false, ...
              'plot_distribution', true, ...
              'left_edge_value', stim_min_log,...
              'boundary_value', value(boundary),...
              'right_edge_value', stim_max_log,...
              'left_probability', LeftProb, ... % These still define the overall PDF, but this pick is forced chosen side
              'right_probability', 1 - LeftProb, ...
              'left_dist_type', dist_left, ...
              'normal_mean_left', dist_mean_left,...
              'decay_rate_magnitude_left', exp_decay_left,...
              'normal_std_dev_left', dist_sigma_left,...
              'half_normal_std_dev_left', dist_sigma_left,...
              'range_percentage_left',range_percent_left , ...
              'right_dist_type', dist_right, ...
              'decay_rate_magnitude_right', exp_decay_right,...
              'normal_mean_right', dist_mean_right,...
              'normal_std_dev_right', dist_sigma_right,...
              'half_normal_std_dev_right', dist_sigma_right,...
              'range_percentage_right',range_percent_right, ...
              'P_central_region', value(P_centre_region), 'central_region_width', value(centre_region_width), ...
              'plot_legend',legend_draw...
              );

          plot_h.value = handle_h;
          drawnow;
        
        

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
        
        make_invisible(sigma_Left);
         switch value(Prob_Dist_Left)
             case {'Half Normal', 'Anti Half Normal'}
                 make_visible(sigma_Left);
                 sigma_Left.value = 0.25;
             case 'Normal'
                 make_visible(sigma_Left);
                 sigma_Left.value = 0.25;
             case {'Exponential','Anti Exponential'}
                 make_visible(sigma_Left);
                 sigma_Left.value = 2.153;
         end

        % Mean
        if matches(value(Prob_Dist_Left),{'Uniform','Half Normal','Sinusoidal','Exponential'})
            mean_Left.value = value(boundary);
        else
            if strcmp(Rule,'S1>S_boundary Left')
                if matches(value(Prob_Dist_Left),{'Anti Half Normal','Anti Sinusoidal','Anti Exponential'})
                    mean_Left.value = edge_max_left;
                elseif matches(value(Prob_Dist_Left),'Normal')
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

        make_invisible(sigma_Right);
        switch value(Prob_Dist_Right)
             case {'Half Normal', 'Anti Half Normal'}
                 make_visible(sigma_Right);
                 sigma_Right.value = 0.25;
             case 'Normal'
                 make_visible(sigma_Right);
                 sigma_Right.value = 0.25;
             case {'Exponential','Anti Exponential'}
                 make_visible(sigma_Right);
                 sigma_Right.value = 2.153;
         end


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
                elseif matches(value(Prob_Dist_Right),'Normal')
                    mean_Right.value = (edge_min_right + value(boundary))/2;
                end
            end
        end
        
        StimulusSection(obj,'plot_stim_distribution');
        
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
            sigma_range_Left.value = 0.2;
        end
        if dist_sigma_multiplier > 1
            sigma_range_Left.value = 1;
        end
            
        make_invisible(sigma_Left);
         switch value(Prob_Dist_Left)
             case {'Half Normal', 'Anti Half Normal'}
                 make_visible(sigma_Left);
                 sigma_Left.value = 0.25;
             case 'Normal'
                 make_visible(sigma_Left);
                 sigma_Left.value = 0.25;
             case {'Exponential','Anti Exponential'}
                 make_visible(sigma_Left);
                 sigma_Left.value = 2.153;
         end

        % Calculation for Right Side Sigma
        dist_sigma_multiplier = value(sigma_range_Right);
        if dist_sigma_multiplier < 0.2
            sigma_range_Right.value = 0.2;
        end
        if dist_sigma_multiplier > 1
            sigma_range_Right.value = 1;
        end
        
        make_invisible(sigma_Right);
        switch value(Prob_Dist_Right)
             case {'Half Normal', 'Anti Half Normal'}
                 make_visible(sigma_Right);
                 sigma_Right.value = 0.25;
             case 'Normal'
                 make_visible(sigma_Right);
                 sigma_Right.value = 0.25;
             case {'Exponential','Anti Exponential'}
                 make_visible(sigma_Right);
                 sigma_Right.value = 2.153;
        end

    case 'stim_params'

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

                varargout{1} = [edge_min_right, value(boundary), edge_max_left];

            else % the rule is S1>S_boundary Right

                edge_min_left = stim_min_log;
                edge_max_left = value(boundary);
                edge_min_left = edge_max_left - dist_range_multiplier_left * (edge_max_left - edge_min_left);
                edge_max_right = stim_max_log;
                edge_min_right = value(boundary);
                edge_max_right = edge_min_right + dist_range_multiplier_right * (edge_max_right - edge_min_right);

                varargout{1} = [edge_min_left, value(boundary), edge_max_right];
            end

    %% Case frequency ON
    case 'FrequencyCategorization'
        if frequency_categorization == 1
            make_visible(maxF1);make_visible(minF1);make_visible(A1_freq);make_visible(volumeF1);
            make_invisible(maxS1);make_invisible(minS1);make_invisible(A1_sigma);
            make_invisible(fcut);make_invisible(lfreq);make_invisible(hfreq); make_invisible(filter_type);
            FixedStim.value = (value(maxF1) + value(minF1))/2;
        else
            make_visible(maxS1);make_visible(minS1);make_visible(A1_sigma);
            make_visible(fcut);make_visible(lfreq);make_visible(hfreq); make_visible(filter_type);
            make_invisible(maxF1);make_invisible(minF1);make_invisible(A1_freq); make_invisible(volumeF1);
            FixedStim.value = (value(maxS1) + value(minS1))/2;
        end

        if strcmpi(Stimuli_State,'Full')
            StimulusSection(obj,'Cal_Boundary'); % update the boundary
            StimulusSection(obj,'plot_stim_distribution');
        end

    %% Case get_stimuli
    % case 'get_stimuli'
    %     if nargout>0
    %         x=value(S1);
    %     end

    case 'Distribution_Switch'

        if strcmpi(Stimuli_State,'Full')
            
            switch value(Category_Dist)

                case 'Uniform'
                    Prob_Dist_Right.value = 'Uniform';
                    make_invisible(sigma_Right);
                    Prob_Dist_Left.value = 'Uniform';
                    make_invisible(sigma_Left);

                case 'Hard A'
                    if strcmp(Rule,'S1>S_boundary Right')
                        Prob_Dist_Right.value = 'Uniform';
                        make_invisible(sigma_Right);
                        Prob_Dist_Left.value = 'Exponential';
                        sigma_Left.value = 2.153;
                        make_visible(sigma_Left);
                    else
                        Prob_Dist_Right.value = 'Exponential';
                        sigma_Right.value = 2.153;
                        make_visible(sigma_Right);
                        Prob_Dist_Left.value = 'Uniform';
                        make_invisible(sigma_Left);
                    end

                case 'Hard B'
                    if strcmp(Rule,'S1>S_boundary Right')
                        Prob_Dist_Left.value = 'Uniform';
                        make_invisible(sigma_Left);
                        Prob_Dist_Right.value = 'Exponential';
                        make_visible(sigma_Right);
                        sigma_Right.value = 2.153;
                    else
                        Prob_Dist_Left.value = 'Exponential';
                        make_visible(sigma_Left);
                        sigma_Left.value = 2.153;
                        Prob_Dist_Right.value = 'Uniform';
                        make_invisible(sigma_Right);
                    end
            end

            % Checking if the distribution changed from previous value and then
            % only run the following script
            category_dist_history = get_history(Category_Dist);
            if n_done_trials == 0 || strcmpi(category_dist_history{n_done_trials},value(Category_Dist)) ~= 1
                StimulusSection(obj,'plot_stim_distribution');
                PsychometricSection(obj,'StimSection_Distribution_Switch');
            end

        end

    case 'Pushbutton_SwitchDistribution'
        dist = varargin{1};
        Category_Dist.value = dist;
        StimulusSection(obj,'Distribution_Switch');

    %% Case close
    case 'close'
        set(value(myfig), 'visible', 'off');
        % set(value(stim_dist_fig), 'visible', 'off');

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
        ps  = value(stimulus_history);
        ps1 = value(stimulus_distribution_history);
        ps2 = value(stimulus_right_distribution_history);
        ps3 = value(stimulus_left_distribution_history);

        if strcmpi(Stimuli_State, 'Full')
            ps(n_done_trials)  = value(thisstimlog(n_done_trials));
            ps1{n_done_trials} = value(Category_Dist);
            ps2{n_done_trials} = value(Prob_Dist_Right);
            ps3{n_done_trials} = value(Prob_Dist_Left);

        elseif strcmpi(Stimuli_State, 'Discrete')
            ps(n_done_trials)  = value(thisstimlog(n_done_trials));
            ps1{n_done_trials} = 'Uniform';
            ps2{n_done_trials} = 'Uniform';
            ps3{n_done_trials} = 'Uniform';

        elseif strcmpi(Stimuli_State, 'Fixed Stimuli')
            ps(n_done_trials)  = value(thisstimlog(n_done_trials));
            ps1{n_done_trials} = 'Fixed Stimuli';
            ps2{n_done_trials} = 'Fixed Stimuli';
            ps3{n_done_trials} = 'Fixed Stimuli';

        elseif strcmpi(Stimuli_State, 'No Sound')
            % Write sentinel values so history arrays always grow with n_done_trials.
            % NaN stim is filtered by ~isnan() guards throughout RealTimeAnalysis.
            % 'No Sound' distribution string is handled by the is_str filter.
            ps(n_done_trials)  = NaN;
            ps1{n_done_trials} = 'No Sound';
            ps2{n_done_trials} = 'No Sound';
            ps3{n_done_trials} = 'No Sound';
        end

        stimulus_history.value                    = ps;
        stimulus_distribution_history.value       = ps1;
        stimulus_right_distribution_history.value = ps2;
        stimulus_left_distribution_history.value  = ps3;

    case 'Stimuli_State_change'

        % 1. Hide/Disable Everything First

        make_invisible(P_centre_region); make_invisible(centre_region_width);
        make_invisible(Prob_Dist_Left); make_invisible(mean_Left); make_invisible(sigma_Left); make_invisible(sigma_range_Left);
        make_invisible(Prob_Dist_Right); make_invisible(mean_Right); make_invisible(sigma_Right); make_invisible(sigma_range_Right);
        make_invisible(Category_Dist); make_invisible(plot_stim_dist);
        make_invisible(n_discrete); make_invisible(boundary_fraction);
        make_invisible(FixedStim);

        % 2. Show only the active state elements
        switch Stimuli_State
            case 'Full'
                make_visible(P_centre_region); make_visible(centre_region_width);
                make_visible(Prob_Dist_Left); make_visible(mean_Left); make_visible(sigma_Left); make_visible(sigma_range_Left);
                make_visible(Prob_Dist_Right); make_visible(mean_Right); make_visible(sigma_Right); make_visible(sigma_range_Right);
                make_visible(Category_Dist); make_visible(plot_stim_dist);

            case 'Discrete'
                make_visible(n_discrete); make_visible(boundary_fraction);

            case 'Fixed Stimuli'
                make_visible(FixedStim);

                if frequency_categorization == 1
                    FixedStim.value = (value(maxF1) + value(minF1))/2;
                else
                    FixedStim.value = (value(maxS1) + value(minS1))/2;
                end
        end

        % 3. Handle Plot Visibility
        if strcmpi(Stimuli_State,'Fixed Stimuli')
            make_invisible(plot_h);
        else
            make_visible(plot_h);
        end

    %% Case hide
    case 'hide'
        StimulusShow.value = 0;
        set(value(myfig), 'visible', 'off');
        % set(value(stim_dist_fig), 'visible', 'off');

    %% Case show
    case 'show'
        StimulusShow.value = 1;
        set(value(myfig), 'visible', 'on');
        % set(value(stim_dist_fig), 'visible', 'on');

    %% Case Show_hide
    case 'show_hide'
        if StimulusShow == 1
            set(value(myfig), 'visible', 'on'); 
            % set(value(stim_dist_fig), 'visible', 'on');%#ok<NODEF> (defined by GetSoloFunctionArgs)
        else
            set(value(myfig), 'visible', 'off');
            % set(value(stim_dist_fig), 'visible', 'off');
        end

end

return;
