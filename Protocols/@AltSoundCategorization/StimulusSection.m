

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
    set(gcf, 'Visible', 'off');
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
    SoloParamHandle(obj, 'thesestimuli', 'value', []);
    SoloParamHandle(obj, 'h1', 'value', []); 
    SoloParamHandle(obj, 'S1', 'value', []); 
    SoloParamHandle(obj, 'thisclass', 'value', []);
    SoloParamHandle(obj, 'thisstim', 'value', []);  
    
    y=5;
    MenuParam(obj, 'StimulusType', {'library', 'new'}, ...
      'new', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nnew means at each trial, a new noise pattern will be generated,\n' ...
      '"library" means for each trial stimulus is loaded from a library with limited number of noise patterns'])); next_row(y, 1.3)
    set_callback(StimulusType, {mfilename, 'StimulusType'});
	NumeditParam(obj,'nPatt',50,x,y,'label','Num Nois Patt','TooltipString','Number of Noise Patters for the library');
    
    next_row(y);
    next_row(y);
    PushbuttonParam(obj, 'refresh_stimuli', x,y , 'TooltipString', 'Instantiates the stimuli given the new set of parameters');
    set_callback(refresh_stimuli, {mfilename, 'plot_stimuli'});
    
    next_row(y);
    PushbuttonParam(obj, 'plot_performance', x,y , 'TooltipString', 'Plots the class design with mean performance for each class');
    set_callback(plot_performance, {mfilename, 'plot_perf'});
    
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
    DispParam(obj, 'A1_sigma', 0.01, x,y,'label','A1_sigma','TooltipString','Sigma value for the first stimulus');
	next_row(y);
	NumeditParam(obj,'fcut',110,x,y,'label','fcut','TooltipString','Cut off frequency on the original white noise');
    next_row(y);
	NumeditParam(obj,'lfreq',2000,x,y,'label','Modulator_LowFreq','TooltipString','Lower bound for the frequency modulator');
	next_row(y);
	NumeditParam(obj,'hfreq',20000,x,y,'label','Modulator_HighFreq','TooltipString','Upper bound for the frequency modulator');	
    next_row(y);
% 	NumeditParam(obj,'outband',60,x,y,'label','Outband','TooltipString','outband on the distribution from which white noise is produced');
%     next_row(y);
	NumeditParam(obj,'minS1',0.007,x,y,'label','minS1','TooltipString','min sigma value for AUD1');
    next_row(y);
	NumeditParam(obj,'maxS1',0.05,x,y,'label','maxS1','TooltipString','max sigma value for AUD1');
    next_row(y);
    MenuParam(obj, 'DistributionType', {'narrow_gauss','wide_gauss','bimodal', 'gmm', 'uniform'}, ...
      'narrow_gauss', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nDifferent distributions']));     
    set_callback(DistributionType, {mfilename, 'DistributionType'});
 
    y=5;
    next_column(x);
    SoloParamHandle(obj, 'existing_numClass', 'value', 0, 'saveable', 0);
    SoloParamHandle(obj, 'my_window_info', 'value', [x, y, value(myfig)], 'saveable', 0);
    NumeditParam(obj,'numClass',9,x,y,'label','numClass','TooltipString','Number of stimuli');
    
    set_callback_on_load(numClass, 9); %#ok<NODEF>
    set_callback(numClass, {mfilename, 'numClass'});
    numClass.value = 9; callback(numClass);
    StimulusSection(obj,'plot_stimuli');


  case 'prepare_next_trial' 

    %% d or u?
    SideSection(obj,'get_current_side');
    StimulusSection(obj,'pick_current_stimulus');
    A1_sigma.value=exp(value(thisstim));
 
    set(value(h1), 'YData', log(value(A1_sigma)));

    %% produce noise pattern 
    srate=SoundManagerSection(obj,'get_sample_rate');
    Fs=srate;
    T=value(A1_time);
    [rawA1 rawA2 normA1 normA2]=noisestim(1,1,T,value(fcut),Fs,value(filter_type));
    modulator=singlenoise(1,T,[value(lfreq) value(hfreq)],Fs,'BUTTER');
    AUD1=normA1(1:A1_time*srate).*modulator(1:A1_time*srate).*A1_sigma;

    if ~isempty(AUD1)
        SoundManagerSection(obj, 'set_sound', 'StimAUD1', [AUD1';  AUD1'])
    end

    SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');

    if n_done_trials >0
        
        if ~violation_history(n_done_trials) && ~timeout_history(n_done_trials) 
            eval(sprintf('nTrialsClass%d.value=nTrialsClass%d+1;',thisclass(n_done_trials),thisclass(n_done_trials)));
            eval(sprintf('nt = value(nTrialsClass%d);',thisclass(n_done_trials)));
            if nt == 1
                eval(sprintf('perfClass%d.value = 0;',thisclass(n_done_trials)))
            end
            eval(sprintf('perfClass%d.value=(perfClass%d * (nTrialsClass%d - 1) +%d)/nTrialsClass%d;',thisclass(n_done_trials),thisclass(n_done_trials),thisclass(n_done_trials),hit_history(n_done_trials),thisclass(n_done_trials)));
        end
        StimulusSection(obj,'update_stimulus_history');

%         xd=log(thispair(1));
%         yd=log(thispair(2));
%         axes(value(axperf));
%         eval(sprintf('delete(hperf%d);',thisclass(n_done_trials)));
%         eval(sprintf('text(xd,yd,num2str(value(perfClass%d)));',thisclass(n_done_trials)));
%         %eval(sprintf('set(value(hperf%d), ''XData'', %f, ''Ydata'', %f);',thisclass(n_done_trials),xd,yd));

    end

    
    %% Case new_numClass
  case 'new_numClass'
    for cc=1:20    
        eval(sprintf('disable(probClass%d)',cc)) 
    end
    for cc=1:2*value(numClass)
        eval(sprintf('enable(probClass%d)',cc)) 
    end
    
    %% case numClass
  case 'numClass',
      
      if numClass > existing_numClass,        %#ok<NODEF>
         orig_fig = gcf;
         my_window_visibility = get(my_window_info(3), 'Visible');
         x = my_window_info(1); y = my_window_info(2); figure(my_window_info(3));
         set(my_window_info(3), 'Visible', my_window_visibility);
         
         next_row(y, 1+ value(existing_numClass));
         new_class = (existing_numClass + 1):value(numClass);
         for newnum = new_class,

            NumeditParam(obj,['probClass',num2str(newnum)],1,x,y,'label',['probClass ',num2str(newnum)],'TooltipString','Probability of this stimulus');
            next_column(x); 
            DispParam(obj,['perfClass',num2str(newnum)],nan,x,y,'label',['perfClass ',num2str(newnum)],'TooltipString','Performance on this stimulus');
            next_column(x); 
            DispParam(obj,['nTrialsClass',num2str(newnum)],0,x,y,'label',['nTrialsClass ',num2str(newnum)],'TooltipString','Number of trials on this stimulus');
            next_row(y);  x = my_window_info(1);
            SoloParamHandle(obj, ['hperf',num2str(newnum)], 'value', 0);

         end;
         
         existing_numClass.value = value(numClass);
         figure(orig_fig);
         
      elseif numClass < existing_numClass,
         % If asking for fewer vars than exist, delete excess:
         for oldnum = (value(numClass)+1):value(existing_numClass);
            sphname = ['probClass' num2str(oldnum)];
            delete(eval(sphname));
            sphname = ['perfClass' num2str(oldnum)];
            delete(eval(sphname));
            sphname = ['nTrialsClass' num2str(oldnum)];
            delete(eval(sphname));
         end;
         existing_numClass.value = value(numClass);
     
      else
          x = my_window_info(1); y = my_window_info(2);
          new_class = (1):value(numClass);
            for newnum = new_class,
                next_row(y);
            end;
      end
       
      % Now check for whether we are in the middle of load settings or load
      % data.
   
      varhandles = {};varhandles1 = {};varhandles2 = {};
      for i = 1:value(numClass), 
            varhandles = [varhandles ; {eval(['probClass' num2str(i)])}]; %#ok<AGROW>
            varhandles1 = [varhandles1 ; {eval(['perfClass' num2str(i)])}]; %#ok<AGROW>
            varhandles2 = [varhandles2 ; {eval(['nTrialsClass' num2str(i)])}]; %#ok<AGROW>
      end;
      load_solouiparamvalues(obj, 'ratname', 'rescan_during_load', varhandles);
      load_solouiparamvalues(obj, 'ratname', 'rescan_during_load', varhandles1);
      load_solouiparamvalues(obj, 'ratname', 'rescan_during_load', varhandles2);
      
      StimulusSection(obj,'plot_stimuli');
      
    %% Case StimulusType  
    case 'StimulusType'
    if strcmp(StimulusType, 'library');
        enable((nPatt));
        %disable(seed);
        %set(get_ghandle(seed), 'Enable', 'off');    
    else
        disable(nPatt);
    end
        
    
    %% Case DistributionType
    case 'DistributionType'
    %put way to modulate dist type in session %TODO change settings and
    %display mu sigma
%     if strcmp(DistributionType,'narrow_gauss');
%         mu = 5;
%         sigma = 4.3;
%     end
        
    
    % SET DIST PARAMS here and call in below function
   
    %% Case pick_current_stimulus
    case 'pick_current_stimulus'
        
    global_bag=[];
    %StimulusSection(obj,'DistributionType');
    %uniform (same as in SoundCat)
    if strcmp(DistributionType,'uniform')
        mu = median(1:value(numClass));
        prob_all = ones(1,value(numClass));
        if mod(mu,2)
            prob_all(median(1:value(numClass))) = prob_all(median(1:value(numClass)))/2; %divide by two probability of bouundary class as it belongs to both L and R trials
        end
        for cc=1:value(numClass)
            global_bag=[global_bag ones(1,(10*prob_all(cc))*1)*(cc)];
        end

    %gaussian (wide or narrow)
    elseif strcmp(DistributionType,'wide_gauss')||strcmp(DistributionType,'narrow_gauss')
        if strcmp(DistributionType,'wide_gauss')
            mu = median(1:value(numClass));
            sigma = 4.3;
        else
            mu = median(1:value(numClass));
            sigma = 2.1;
        end

        max_trials = 150;

        x = linspace(1,value(numClass),value(numClass)); % odd number for symmetric distribution
        xU = x + 0.5; xL = x - 0.5;
        prob = normcdf(xU, mu, sigma) - normcdf(xL, mu, sigma);
        prob_all = prob / sum(prob); %normalize the probabilities so their sum is 1
        if mod(mu,2) % if boundary is presented
            prob_all(median(1:value(numClass))) = prob_all(median(1:value(numClass)))/2; %divide by two probability of bouundary class as it belongs to both L and R trials
        end
        global_bag = randsample(1:value(numClass),max_trials,true,prob_all); %ask about number of samples


    %bimodal %% TODO change probabilities
    elseif strcmp(DistributionType,'bimodal')||strcmp(DistributionType,'gmm')
        max_trials = 150./2;
        mu = median(1:median(1:value(numClass)));
        sigma = 1.5;
        x = linspace(1,median(1:value(numClass)),median(1:value(numClass)));
        xU = x + 0.5; xL = x - 0.5;
        prob = normcdf(xU, mu, sigma) - normcdf(xL, mu, sigma);
        prob = prob / sum(prob);
        nums =  randsample(1:median(1:value(numClass)),max_trials,true,prob); 
%         x1 = [value(numClass)./2+1:1:value(numClass)];  
%         x1U = x1 + 0.5; x1L = x1 - 0.5; 
%         prob = normcdf(x1U, mu, sigma) - normcdf(x1L, mu, sigma);
%         prob = prob / sum(prob) ;
        nums1 =  randsample(median(1:value(numClass)):value(numClass),max_trials,true,prob);
        if strcmp(DistributionType,'bimodal')
            prob_tot = [prob(1:end-1) prob];
            prob_all = prob_tot / sum(prob_tot);
            if mod(mu,2) % if boundary is presented
                prob_all(median(1:value(numClass))) = prob_all(median(1:value(numClass)))/2; %divide by two probability of bouundary class as it belongs to both L and R trials
            end
            global_bag = randsample(1:value(numClass),max_trials*2,true,prob_all);
        elseif strcmp(DistributionType,'gmm')
            prob_tot = [prob(1:end-1) prob(1)*2 prob(2:end)];
            prob_all = prob_tot / sum(prob_tot);
            if mod(mu,2) % if boundary is presented
                prob_all(median(1:value(numClass))) = prob_all(median(1:value(numClass)))/2; %divide by two probability of bouundary class as it belongs to both L and R trials
            end
            global_bag = randsample(1:value(numClass),max_trials*2,true,prob_all);
        end
    end
    
    for i = 1:value(numClass)
        if i==median(1:value(numClass))
            eval(sprintf('probClass%d.value = prob_all(i)*2;',i))
        else
            eval(sprintf('probClass%d.value = prob_all(i);',i))
        end
    end
    
    B = unique(global_bag);
    out = [B,histc(global_bag,B)];
    
     if strcmp(Rule,'S2>S_boundry Left')
        if strcmp(ThisTrial, 'LEFT')
%             bag=[];
%             for cc=1:value(numClass)/2
%                 eval(sprintf('pr=value(probClass%d);',cc+value(numClass)/2)); 
%                 bag=[bag ones(1,(10)*pr)*(cc+value(numClass)/2)];
%             end
            bag_high = global_bag(global_bag>=median(1:value(numClass)));
            pp=randsample(bag_high,length(bag_high));
            thisstim.value=value(S1(pp(1)));
            thisclass(n_done_trials+1)=pp(1);   

        else
            
%             bag=[];
%             for cc=1:value(numClass)/2
%                 eval(sprintf('pr=value(probClass%d);',cc));
%                 bag=[bag ones(1,(10)*pr)*value(cc)];
%             end
            bag_low = global_bag(global_bag<=median(1:value(numClass)));
            pp=randsample(bag_low,length(bag_low));
            thisstim.value=value(S1(pp(1)));
            thisclass(n_done_trials+1)=pp(1);            
        end;
        
    elseif strcmp(Rule,'S2>S_boundry Right')
        if strcmp(ThisTrial, 'RIGHT')
%             bag=[];
%             for cc=1:value(numClass)/2
%                 eval(sprintf('pr=value(probClass%d);',cc+value(numClass)/2)); 
%                 bag=[bag ones(1,(10)*pr)*(cc+value(numClass)/2)];
%             end
            bag_high = global_bag(global_bag>=median(1:value(numClass)));
            pp=randsample(bag_high,length(bag_high));
            thisstim.value=value(S1(pp(1)));
            thisclass(n_done_trials+1)=pp(1);
            
        else
%             bag=[];
%             for cc=1:value(numClass)/2
%                 eval(sprintf('pr=value(probClass%d);',cc));
%                 bag=[bag ones(1,(10)*pr)*value(cc)];
%             end
            bag_low = global_bag(global_bag<=median(1:value(numClass)));
            pp=randsample(bag_low,length(bag_low));            
            pp=randsample(bag,length(bag));
            thisstim.value=value(S1(pp(1)));
            thisclass(n_done_trials+1)=pp(1); 
        end;
      end
    
           
    %% Case make_stimuli
    case 'make_stimuli'
   %% make numClass of sigma values 
    S1.value = [];
    S1(1)=log(value(minS1));
    S1(value(numClass))=log(value(maxS1));
    steps = (S1(value(numClass)) - S1(1))./(value(numClass)-1);
    for ii=2:value(numClass)-1
        S1(ii)=S1(ii-1)+steps;    
    end
    
      
    %% Case plot_pais
    case 'plot_stimuli'  
    StimulusSection(obj,'make_stimuli');  
    
    %% plot the stimulus 
    cla(value(ax))
    xd=1;
    yd=(value(S1));
    for ii=1:length(yd)
        axes(value(ax));
        plot(xd,yd(ii),'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
        hold on
        eval(sprintf('hperf%d=text(xd,yd(ii),num2str(ii));',ii));
        hold on
    end
    axis square
%      Ytick=get(value(ax),'YtickLabel');
%      Xtick=get(value(ax),'XtickLabel');
    set(value(ax),'ytick',((yd(1:1:end))),'xtick',xd);
    set(value(ax),'yticklabel',exp(yd(1:1:end)),'xticklabel','S1');
    ylabel('\sigma_1 in log scale','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('S1','FontSize',16,'FontName','Cambria Math')

    SideSection(obj,'get_current_side');
    StimulusSection(obj,'pick_current_stimulus');
    
    A1_sigma.value=exp(value(thisstim));

    %% plot the stimulus
    h1.value=plot(xd,log(value(A1_sigma)),'s','color',[0.8 0.4 0.1],'markerfacecolor',[0.8 0.4 0.1],'MarkerSize',15,'LineWidth',3);

  %% Case Plot_perf
    case 'plot_perf'
    %% make numClass stimulus of sigma values   
    StimulusSection(obj,'make_stimuli'); 
    
    %% plot the stimulus set
    cla(value(axperf))
    xd=1;
    yd=value(S1);
    for ii=1:length(yd)
        axes(value(axperf));
        plot(xd,yd(ii),'s','MarkerSize',31,'MarkerEdgeColor',[0 0 0],'LineWidth',1.5)
        hold on
        eval(sprintf('perf=value(perfClass%d);',ii))
        text(xd-0.14,yd(ii),num2str(round(perf*1000)/10));
        hold on
    end
    axis square
    set(value(ax),'ytick',((yd(1:1:end))),'xtick',xd);
    set(value(ax),'yticklabel',exp(yd(1:1:end)),'xticklabel','S1');
    ylabel('\sigma_1 in log scale','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('S1','FontSize',16,'FontName','Cambria Math')
    set(value(axperf),'Fontsize',15)

         

    %% Case get_class_perform
    case 'get_class_perform'
        if nargout > 0
            for ii=1:value(numClass)
            eval(sprintf('final_perf(ii)=value(perfClass%d);',ii));
            end
            eval(sprintf('x=[value(perfClass%d) value(perfClass%d);]',1,value(numClass)));
            y=final_perf;
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
        ps(n_done_trials)=value(thisclass(n_done_trials));
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
    