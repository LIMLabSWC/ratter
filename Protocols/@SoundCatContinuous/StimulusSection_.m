

function [x, y] = StimulusSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action,
    
  % ------------------------------------------------------------------
  %              INIT
  % ------------------------------------------------------------------    

  case 'init'
    if length(varargin) < 2,
      error('Need at least two arguments, x and y position, to initialize %s', mfilename);
    end;
    x = varargin{1}; y = varargin{2};
    
    ToggleParam(obj, 'StimulusShow', 0, x, y, 'OnString', 'Stimuli', ...
      'OffString', 'Stimuli', 'TooltipString', 'Show/Hide Stimulus panel'); 
    set_callback(StimulusShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
    next_row(y);
    
    SoloParamHandle(obj, 'myfig', 'value', figure('closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
      'Name', mfilename), 'saveable', 0);
    screen_size = get(0, 'ScreenSize');
    set(value(myfig),'Position',[1 screen_size(4)-740, 1000 1000]); % put fig at top right
    set(double(gcf), 'Visible', 'off');
    x=10;y=10;
         
    SoloParamHandle(obj, 'ax', 'saveable', 0, ...
                   'value', axes('Position', [0.01 0.5 0.45 0.45]));
    ylabel('log_e A','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('Sound Categorization','FontSize',16,'FontName','Cambria Math')

    SoloParamHandle(obj, 'axperf', 'saveable', 0, ...
                   'value', axes('Position', [0.5 0.5 0.45 0.45]));
    ylabel('log_e A','FontSize',16,'FontName','Cambria Math');  
    set(value(axperf),'Fontsize',15)
    xlabel('Sound Categorization','FontSize',16,'FontName','Cambria Math')
    
    SoundManagerSection(obj, 'declare_new_sound', 'StimAUD1')
    SoloParamHandle(obj, 'thisstim', 'value', []);  
    SoloParamHandle(obj, 'thisstimlog', 'value', []);
    SoloParamHandle(obj, 'h1', 'value', []); 
    
    y=5;
    
    next_row(y);
    next_row(y);
    PushbuttonParam(obj, 'refresh_stimuli', x,y , 'TooltipString', 'Instantiates the stimuli given the new set of parameters');
    set_callback(refresh_stimuli, {mfilename, 'plot_stimuli'});
    
    
    next_row(y);
    next_row(y);
    MenuParam(obj, 'Rule', {'S2>S_boundry Left','S2>S_boundry Right'}, ...
      'S2>S_boundry Left', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nThis bottom determines the rule\n', ...
      '\n''S2>S_boundry Left'' means if Aud2 > Aud_boundry then reward will be delivered from the left water spout and if Aud2 < Aud_boundry then water comes form right\n',...
      '\n''S2>S_boundry Right'' means if Aud2 < Aud_boundry then reward will be delivered from the left water spout and if Aud2 > Aud_boundry then water comes from right\n'])); 
    next_row(y, 1)
    
    next_column(x);
    y=5;
    MenuParam(obj, 'filter_type', {'GAUS','LPFIR', 'FIRLS','BUTTER','MOVAVRG','KAISER','EQUIRIP','HAMMING'}, ...
      'GAUS', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nDifferent filters. ''LPFIR'': lowpass FIR ''FIRLS'': Least square linear-phase FIR filter design\n', ...
      '\n''BUTTER'': IIR Butterworth lowpass filter ''GAUS'': Gaussian filter (window)\n', ...
      '\n''MOVAVRG'': Moving average FIR filter ''KAISER'': Kaiser-window FIR filtering\n', ...
      '\n''EQUIRIP'':Eqiripple FIR filter ''HAMMING'': Hamming-window based FIR'])); 
    next_row(y, 1)
	NumeditParam(obj,'fcut',110,x,y,'label','fcut','TooltipString','Cut off frequency on the original white noise');
    next_row(y);
	NumeditParam(obj,'lfreq',2000,x,y,'label','Modulator_LowFreq','TooltipString','Lower bound for the frequency modulator');
	next_row(y);
	NumeditParam(obj,'hfreq',20000,x,y,'label','Modulator_HighFreq','TooltipString','Upper bound for the frequency modulator');	
    next_row(y);
    DispParam(obj, 'A1_sigma', 0.01, x,y,'label','A1_sigma','TooltipString','Sigma value for the first stimulus');
	next_row(y);
    DispParam(obj, 'A1_freq', 0.01, x,y,'label','A1_freq','TooltipString','Sigma value for the first stimulus');
	next_row(y);
	NumeditParam(obj,'minS1',0.007,x,y,'label','minS1','TooltipString','min sigma value for AUD1');
    next_row(y);
	NumeditParam(obj,'maxS1',0.05,x,y,'label','maxS1','TooltipString','max sigma value for AUD1');
    next_row(y);
	NumeditParam(obj,'minF1',1,x,y,'label','minF1','TooltipString','min frequency value for AUD1');
    next_row(y);
	NumeditParam(obj,'maxF1',9,x,y,'label','maxF1','TooltipString','max frequency value for AUD1');
    next_row(y);
	NumeditParam(obj,'boundary',0,x,y,'label','boundary','TooltipString','decision boundary for categorisation (log)');
    next_row(y);
    NumeditParam(obj,'mu',0,x,y,'label','mu','TooltipString','mean of distribution');
    next_row(y);
        ToggleParam(obj, 'frequency_categorization', 0, x,y,...
        'OnString', 'frequency ON',...
        'OffString', 'frequency OFF',...
        'TooltipString', sprintf('If on (black) then it enables the presentation of pure tones'));
    next_row(y);
    MenuParam(obj, 'DistributionType', {'uniform','unim-unif', 'unif-unim'}, ...
      'uniform', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nDifferent distributions']));     
    set_callback(DistributionType, {mfilename, 'DistributionType'});
    if frequency_categorization
        boundary.value = (log(value(minF1)) + log(value(maxF1)))/2;
    else
        boundary.value = (log(value(minS1)) + log(value(maxS1)))/2;
    end
    StimulusSection(obj,'plot_stimuli');
    
    set_callback(frequency_categorization, {mfilename, 'FrequencyCategorization'});
    
    case 'prepare_next_trial' 

    %% d or u?
    
    SideSection(obj,'get_current_side');
    StimulusSection(obj,'pick_current_stimulus');
    if frequency_categorization
        A1_freq.value=exp(value(thisstim));
        A1_sigma.value=0;
        A1 = log(value(A1_freq));
    else
        A1_sigma.value=exp(value(thisstim));
        A1_freq.value=0;
        A1 = log(value(A1_sigma));
    end
    
%     value(thisstimlog(n_done_trials+1)) - value(boundary)
    if value(thisstimlog(n_done_trials+1)) > value(boundary)%value(numClass)
        set(value(h1), 'YData', value(A1), 'color',[0.4 0.8 0.1],'markerfacecolor',[0.4 0.8 0.1]);
    else
        set(value(h1), 'YData', value(A1), 'color',[0.8 0.4 0.1],'markerfacecolor',[0.8 0.4 0.1]);
    end

    % Plot current stimulus and move to saving stimulus history
    
    %% produce noise pattern 
    srate=SoundManagerSection(obj,'get_sample_rate');
    Fs=srate;
    T=value(A1_time);
    
    if frequency_categorization
        dur1 = A1_time*1000;
        bal=0;
        freq1=A1_freq*1000;
        vol=0.002;
        RVol=vol*min(1,(1+bal));LVol=vol*min(1,(1-bal));
        t=0:(1/srate):(dur1/1000); t = t(1:end-1);
        tw=sin(t*2*pi*freq1);
        RW=RVol*tw;
        %w=[LW;RW];
        AUD1 = RW;
    else
        [rawA1 rawA2 normA1 normA2]=noisestim(1,1,T,value(fcut),Fs,value(filter_type));
        modulator=singlenoise(1,T,[value(lfreq) value(hfreq)],Fs,'BUTTER');
        AUD1=normA1(1:A1_time*srate).*modulator(1:A1_time*srate).*A1_sigma;
    end

    if ~isempty(AUD1)
        SoundManagerSection(obj, 'set_sound', 'StimAUD1', [AUD1';  AUD1'])
    end

   
    SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
    
    if n_done_trials >0
        
        if ~violation_history(n_done_trials) && ~timeout_history(n_done_trials) 
            StimulusSection(obj,'update_stimulus_history');
        else
            StimulusSection(obj,'update_stimulus_history_nan');
        end
    end


    %% Case make_stimuli
    case 'make_stimuli'
    if nargout>0
        if frequency_categorization
            stim_min_log = log(value(minF1));
            stim_max_log = log(value(maxF1));
        else
            stim_min_log = log(value(minS1));
            stim_max_log = log(value(maxS1)); 
        end
        
        stim_range_log = stim_max_log - stim_min_log;
        if strcmp(DistributionType,'uniform')
            stim_i_log = stim_min_log + rand() * (stim_max_log - stim_min_log);
            %stim_i = exp(stim_i_log)
        elseif strcmp(DistributionType,'unim-unif')
            stim_i_log = stim_min_log + rand() * (stim_max_log - stim_min_log);
            if stim_i_log < (stim_max_log + stim_min_log) / 2
                for i = 1:30
                    stim_i_log = stim_i_log - 0.01 * sin(2 * pi * 0.5 * (stim_i_log - stim_min_log) / (stim_range_log/2));
                end
            end
        elseif strcmp(DistributionType,'unif-unim')
            stim_i_log = stim_min_log + rand() * (stim_max_log - stim_min_log);
            if stim_i_log > (stim_max_log + stim_min_log) / 2
                for i = 1:30
                    stim_i_log = stim_i_log - 0.01 * sin(2 * pi * 0.5 * (stim_i_log - stim_min_log) / (stim_range_log/2));
                end
            end
        end
        x = stim_i_log;
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
     if strcmp(Rule,'S2>S_boundry Left')
        if strcmp(ThisTrial, 'LEFT')
            stim_i_log = stim_min_log;
            while stim_i_log <= value(boundary)
                stim_i_log = StimulusSection(obj,'make_stimuli');
            end
            %stim_i = exp(stim_i_log);     
        else
            stim_i_log = stim_max_log;
            while stim_i_log >= value(boundary)
                stim_i_log = StimulusSection(obj,'make_stimuli');
            end
            %stim_i = exp(stim_i_log);        
        end
      elseif strcmp(Rule,'S2>S_boundry Right')
        if strcmp(ThisTrial, 'LEFT')
            stim_i_log = stim_max_log;
            while stim_i_log >= value(boundary)
                stim_i_log = StimulusSection(obj,'make_stimuli');
            end
            %stim_i = exp(stim_i_log);     
        else
            stim_i_log = stim_min_log;
            while stim_i_log <= value(boundary)
                stim_i_log = StimulusSection(obj,'make_stimuli');
            end
            %stim_i = exp(stim_i_log);        
        end        
     end
     thisstim.value=stim_i_log;
     thisstimlog(n_done_trials+1)= stim_i_log;  
     %disp(exp(value(thisstimlog)))
      
    %% Case plot_pais
    case 'plot_stimuli'  
    
    %% plot the stimuli
    if frequency_categorization
        boundary.value = (log(value(minF1)) + log(value(maxF1)))/2;
        stim_min_log = log(value(minF1));
        stim_max_log = log(value(maxF1));
        stim_min = value(minF1);
        stim_max = value(maxF1);
        
    else
        boundary.value = (log(value(minS1)) + log(value(maxS1)))/2;
        stim_min_log = log(value(minS1));
        stim_max_log = log(value(maxS1)); 
        stim_min = value(minS1);
        stim_max = value(maxS1);
    end  
    cla(value(ax))
    xd=1;
    axes(value(ax));
    plot(xd,stim_min_log,'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
    hold on
    plot(xd,stim_max_log,'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
    line([0,2], [value(boundary),value(boundary)]);
    axis square
    set(value(ax),'ytick',([stim_min_log, stim_max_log]),'xtick',xd);
    set(value(ax),'yticklabel',([stim_min, stim_max]),'xticklabel','S1');
    ylabel('\sigma_1 in log scale','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('S1','FontSize',16,'FontName','Cambria Math')

    SideSection(obj,'get_current_side');
    StimulusSection(obj,'pick_current_stimulus');
    
    A1 = value(thisstim);

    %% plot the stimulus;
    if value(thisstim) > value(boundary)%value(numClass)
        h1.value=plot(xd,value(A1),'s','color',[0.4 0.8 0.1],'markerfacecolor',[0.4 0.8 0.1],'MarkerSize',15,'LineWidth',3);
    else
        h1.value=plot(xd,value(A1),'s','color',[0.8 0.4 0.1],'markerfacecolor',[0.8 0.4 0.1],'MarkerSize',15,'LineWidth',3);
    end
         
        
    %% Case frequency ON
    case 'FrequencyCategorization'
        if frequency_categorization == 1
            enable(maxF1);enable(minF1);
            StimulusSection(obj,'plot_stimuli');
        else
            disable(maxF1);disable(minF1);
            StimulusSection(obj,'plot_stimuli');
        end
        
    %% Case get_stimuli
    case 'get_stimuli'
        if nargout>0
            x=value(S1);
        end

        
    %% Case close    
    case 'close'
		% Delete all SoloParamHandles who belong to this object and whose
		% fullname starts with the name of this mfile:
        if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)), %#ok<NODEF>
            delete(value(myfig));
        end;
		delete_sphandle('owner', ['^@' class(obj) '$'], ...
			'fullname', ['^' mfilename]);
        
    %% Case update_stimuli
    case 'update_stimuli'
        StimulusSection(obj,'plot_stimuli');

    case 'update_stimulus_history'
        ps=value(stimulus_history);
        ps(n_done_trials)=value(thisstimlog(n_done_trials));
        stimulus_history.value=ps;
        
    case 'update_stimulus_history_nan'
        ps=value(stimulus_history);
        ps(n_done_trials)=nan;
        stimulus_history.value=ps;

    %% Case hide
    case 'hide',
        StimulusShow.value = 0; set(value(myfig), 'Visible', 'off');
    %% Case show
    case 'show',
        StimulusShow.value = 1; set(value(myfig), 'Visible', 'on');
    %% Case Show_hide
    case 'show_hide',
        if StimulusShow == 1, set(value(myfig), 'Visible', 'on'); %#ok<NODEF> (defined by GetSoloFunctionArgs)
        else                   set(value(myfig), 'Visible', 'off');
        end;
    end
    