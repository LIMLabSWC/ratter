

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
    ylabel('log_e \sigma','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('Sequence','FontSize',16,'FontName','Cambria Math')

    SoloParamHandle(obj, 'axperf', 'saveable', 0, ...
                   'value', axes('Position', [0.5 0.5 0.45 0.45]));
    ylabel('log_e \sigma','FontSize',16,'FontName','Cambria Math');  
    set(value(axperf),'Fontsize',15)
    xlabel('Sequence','FontSize',16,'FontName','Cambria Math')
    
    SoundManagerSection(obj, 'declare_new_sound', 'StimAUD1')
    SoundManagerSection(obj, 'declare_new_sound', 'StimAUD2')
    SoundManagerSection(obj, 'declare_new_sound', 'StimAUD3')
    SoloParamHandle(obj, 'sequences', 'value', []);
    SoloParamHandle(obj, 'sequence_a', 'value', []);
    SoloParamHandle(obj, 'sequence_b', 'value', []);    
    SoloParamHandle(obj, 'thissequence', 'value', []);
%     SoloParamHandle(obj, 'pairs_d_psych', 'value', []);
%     SoloParamHandle(obj, 'pairs_u_psych', 'value', []);
    SoloParamHandle(obj, 'h1', 'value', []); 
    SoloParamHandle(obj, 'thisclass', 'value', []);

    y=5;
    MenuParam(obj, 'StimulusType', {'library', 'new'}, ...
      'new', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nnew means at each trial, a new noise pattern will be generated,\n' ...
      '"library" means for each trial stimulus is loaded from a library with limited number of noise patterns'])); next_row(y, 1.3)
    set_callback(StimulusType, {mfilename, 'StimulusType'});
	NumeditParam(obj,'nPatt',50,x,y,'label','Num Nois Patt','TooltipString','Number of Noise Patters for the library');
    
    next_row(y);
    next_row(y);
    PushbuttonParam(obj, 'refresh_sequences', x,y , 'TooltipString', 'Instantiates the sequences given the new set of parameters');
    set_callback(refresh_sequences, {mfilename, 'plot_sequences'});
    
    next_row(y);
    PushbuttonParam(obj, 'plot_performance', x,y , 'TooltipString', 'Plots the class design with mean performance for each class');
    set_callback(plot_performance, {mfilename, 'plot_perf'});
    
    next_row(y);
    next_row(y);
    MenuParam(obj, 'Rule', {'SeqA Left','SeqB Right'}, ...
      'SeqA Left', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nThis bottom determines the rule\n', ...
      '\n''SequenceA Left'' means if ABA then reward will be delivered from the left water spout and if ABB then water comes form right\n',...
      '\n''SequenceA Right'' means if ABB then reward will be delivered from the left water spout and if ABA then water comes from right\n'])); 
    next_row(y, 1)
%     ToggleParam(obj, 'midclass_pairs', 0, x,y,...
% 			'OnString', 'Mid Class Pairs ON',...
% 			'OffString', 'Mid Class Pairs OFF',...
% 			'TooltipString', sprintf('If on (Yellow) then stimulus pairs between the main class pairs will be included'));
%     set_callback(midclass_pairs, {mfilename, 'numClass'});
    
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
    DispParam(obj, 'A2_sigma', 0.01, x,y,'label','A2_sigma','TooltipString','Sigma value for the second stimulus');
	next_row(y);
    DispParam(obj, 'A3_sigma', 0.01, x,y,'label','A3_sigma','TooltipString','Sigma value for the third stimulus');
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
	DispParam(obj,'maxS',40,x,y,'label','maxS','TooltipString','max sigma value for AUD1');
    NumeditParam(obj,'s2_s1_ratio',2.6,x,y,'label','s2_s1_ratio','TooltipString','Intensity index i.e. Ind=(S1-S2)/(S1+S2)');
    next_row(y);
        next_row(y);
    ToggleParam(obj, 'psych_pairs', 0, x,y,...
        'OnString', 'Psych Pairs ON',...
        'OffString', 'Psych Pairs OFF',...
        'TooltipString', sprintf('If on (black) then it disable the presentation of psychometric pairs'));
 	next_row(y);
    NumeditParam(obj,'nPsych',6,x,y,'label','Num Psych Pairs','TooltipString','Number of psychometric pairs');
    next_row(y);
    NumeditParam(obj,'from',0.047,x,y,'label','lowest pair','TooltipString','Psychometric pairs will be put between this pair, and an upper pair based on Ratio');
    next_row(y);
    MenuParam(obj, 'psych_type', {'horizpairs', 'vertpairs'}, ...
      'horizpairs', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nhorizpairs means psychometric pairs will be built with "from" as their fixed S2 while S1 will increase,\n' ...
      '"vertpairs" means psychometric pairs will be built with "from" as their fixed S1 while S2 will increase'])); next_row(y, 1.3)
    NumeditParam(obj,'probpsych',0.9,x,y,'label','probpsych','TooltipString','probability of having a psychometric pair as the stimulus pair at each trial');
    disable(nPatt);
    next_column(x);    
    y=5;
    SoloParamHandle(obj, 'existing_numClass', 'value', 0, 'saveable', 0);
    SoloParamHandle(obj, 'my_window_info', 'value', [x, y, value(myfig)], 'saveable', 0);
    NumeditParam(obj,'numClass',4,x,y,'label','numClass','TooltipString','Number of stimulus pairs');
    
    set_callback_on_load(numClass, 2); %#ok<NODEF>
    set_callback(numClass, {mfilename, 'numClass'});
    numClass.value = 2; callback(numClass);
    StimulusSection(obj,'plot_sequences');



  case 'prepare_next_trial' 

    %% d or u?
    SideSection(obj,'get_current_side');
    
    StimulusSection(obj,'pick_current_stimulus');
       
    A1_sigma.value=value(thissequence(1));
    A2_sigma.value=value(thissequence(2));
    A3_sigma.value=value(thissequence(3)); 
    
    set(value(h1), 'XData', [1 2 3], 'Ydata', [log(value(A1_sigma)) log(value(A2_sigma)) log(value(A3_sigma))]);

    %% produce noise pattern 
    srate=SoundManagerSection(obj,'get_sample_rate');
    Fs=srate;
    T=max(value(A2_time),value(A1_time));
    
    %repeat same sound as A or B or generate a new one?
    [rawA1 , ~, normA1 normA2]=noisestim(1,1,T,value(fcut),Fs,value(filter_type));
    modulator=singlenoise(1,T,[value(lfreq) value(hfreq)],Fs,'BUTTER');
    AUD1=normA1(1:A1_time*srate).*modulator(1:A1_time*srate).*A1_sigma;
    AUD2=normA2(1:A2_time*srate).*modulator(1:A2_time*srate).*A2_sigma;

    if ~isempty(AUD1)
        SoundManagerSection(obj, 'set_sound', 'StimAUD1', [AUD1';  AUD1'])
    end
    if ~isempty(AUD2)
    SoundManagerSection(obj, 'set_sound', 'StimAUD2', [AUD2';  AUD2'])
    end
    
    if A3_sigma == A1_sigma & ~isempty(AUD1)
        SoundManagerSection(obj, 'set_sound', 'StimAUD3', [AUD1';  AUD1'])
    elseif A3_sigma == A2_sigma & ~isempty(AUD2)
        SoundManagerSection(obj, 'set_sound', 'StimAUD3', [AUD2';  AUD2'])
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
        StimulusSection(obj,'update_sequence_history');

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

            NumeditParam(obj,['probClass',num2str(newnum)],1,x,y,'label',['probClass ',num2str(newnum)],'TooltipString','Probability of this sequence');
            next_column(x); 
            DispParam(obj,['perfClass',num2str(newnum)],nan,x,y,'label',['perfClass ',num2str(newnum)],'TooltipString','Performance on this sequence');
            next_column(x); 
            DispParam(obj,['nTrialsClass',num2str(newnum)],0,x,y,'label',['nTrialsClass ',num2str(newnum)],'TooltipString','Number of trials on this sequence');
            next_row(y);  x = my_window_info(1);
            SoloParamHandle(obj, ['hperf',num2str(newnum)], 'value', 0);

         end;
         
         existing_numClass.value = value(numClass);
         figure(orig_fig);
         
      elseif numClass < existing_numClass,
         % If asking for fewer vars than exist, delete excess:
         for oldnum = (numClass*2+1):value(existing_numClass*2);
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
          new_class = (1):value(numClass*2);
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
      
      if value(psych_pairs) ==1
          SoloParamHandle(obj, 'my_window_info', 'value', [x, y, value(myfig)], 'saveable', 0);
          StimulusSection(obj,'PsychClass');
      end
      StimulusSection(obj,'plot_pairs');
      
    %% Case PsychClass
    case 'PsychClass' 
         orig_fig = gcf;
         my_window_visibility = get(my_window_info(3), 'Visible');
         x = my_window_info(1); y = my_window_info(2); figure(my_window_info(3));
         set(my_window_info(3), 'Visible', my_window_visibility);
         
      if nPsych > existing_numClassPsych,        %#ok<NODEF>

         next_row(y, 1+ value(existing_numClassPsych));
         new_class = (existing_numClassPsych + 1):value(nPsych);
         for newnum = new_class,
            DispParam(obj,['perfClass',num2str(newnum+numClass*2)],nan,x,y,'label',['perfClass ',num2str(newnum+numClass*2)],'TooltipString','Performance on this pair');
            next_column(x); 
            DispParam(obj,['nTrialsClass',num2str(newnum+numClass*2)],0,x,y,'label',['nTrialsClass ',num2str(newnum+numClass*2)],'TooltipString','Number of trials on this pair');
            next_row(y);  x = my_window_info(1);
            SoloParamHandle(obj, ['hperf',num2str(newnum+numClass*2)], 'value', 0);

         end;
         
         existing_numClassPsych.value = value(nPsych);
         figure(orig_fig);
         
      elseif nPsych < existing_numClassPsych,
         % If asking for fewer vars than exist, delete excess:
         for oldnum = (nPsych+1):value(existing_numClassPsych);
            sphname = ['perfClass' num2str(oldnum+numClass*2)];
            delete(eval(sphname));
            sphname = ['nTrialsClass' num2str(oldnum+numClass*2)];
            delete(eval(sphname));
         end;
         existing_numClassPsych.value = value(nPsych);
     
      end;
       
   
      varhandles = {};varhandles1 = {};varhandles2 = {};
      for i = 1:value(nPsych), 
            varhandles1 = [varhandles1 ; {eval(['perfClass' num2str(i+numClass*2)])}]; %#ok<AGROW>
            varhandles2 = [varhandles2 ; {eval(['nTrialsClass' num2str(i+numClass*2)])}]; %#ok<AGROW>
      end;
      load_solouiparamvalues(obj, 'ratname', 'rescan_during_load', varhandles1);
      load_solouiparamvalues(obj, 'ratname', 'rescan_during_load', varhandles2);

    %% Case StimulusType  
    case 'StimulusType'
    if strcmp(StimulusType, 'library');
        enable((nPatt));
        %disable(seed);
        %set(get_ghandle(seed), 'Enable', 'off');    
    else
        disable(nPatt);
    end
        
    %% Case pick_current_stimulus
    case 'pick_current_stimulus'
        
    if strcmp(Rule,'SeqA Left')
        if strcmp(ThisTrial, 'LEFT')
            thisclass(n_done_trials+1)=1;  %a
            thissequence.value = value(sequences(thisclass(n_done_trials+1),:));
        else
            thisclass(n_done_trials+1)=2;  %b
            thissequence.value = value(sequences(thisclass(n_done_trials+1),:));
        end
            
    elseif strcmp(Rule,'SeqA Right')
        
        if strcmp(ThisTrial, 'RIGHT')
            thisclass(n_done_trials+1)=1;  
            thissequence.value = value(sequences(thisclass,:));
        else
            thisclass(n_done_trials+1)=2;  
            thissequence.value = value(sequences(thisclass,:));
        end
    end
            
%             bag=[];
%             for cc=1:value(numClass)+(numClass-1)*value(midclass_pairs)
%                 eval(sprintf('pr=value(probClass%d);',cc+value(numClass))); 
%                 bag=[bag ones(1,(10-10*probpsych)*pr)*value(cc)];
%             end
%             
%             if psych_pairs ==1
%                 for cc=value(numClass)+1:value(numClass)+value(nPsych)/2
%                     bag = [bag ones(1,(probpsych*10))*value(cc)];
%                 end 
%             end
%             pp=randsample(bag,length(bag));
%             thispair=[pairs_u(pp(1),1) pairs_u(pp(1),2)];
%             if pp(1) > value(numClass)
%                 thisclass(n_done_trials+1)=pp(1)+numClass+nPsych/2;   
%             else
%                 thisclass(n_done_trials+1)=pp(1)+numClass;
%             end
%         else
%             
%             bag=[];
%             for cc=1:value(numClass)+(numClass-1)*value(midclass_pairs)
%                 eval(sprintf('pr=value(probClass%d);',cc));
%                 bag=[bag ones(1,(10-10*probpsych)*pr)*value(cc)];
%             end
%             
%             if psych_pairs ==1
%                 for cc=value(numClass)+1:value(numClass)+value(nPsych)/2
%                     bag = [bag ones(1,(probpsych*10))*(value(cc))];
%                 end 
%             end
%             pp=randsample(bag,length(bag));
%             thispair=[pairs_d(pp(1),1) pairs_d(pp(1),2)];
%             if pp(1) > value(numClass)
%                 thisclass(n_done_trials+1)=pp(1)+numClass;   
%             else
%             thisclass(n_done_trials+1)=pp(1);
%             end            
%         end;
%     elseif strcmp(Rule,'SequenceA Right')
%         if strcmp(ThisTrial, 'RIGHT')
%             bag=[];
%             for cc=1:value(numClass)+(numClass-1)*value(midclass_pairs)
%             eval(sprintf('pr=value(probClass%d);',cc+value(numClass))); 
%             bag=[bag ones(1,(10-10*probpsych)*pr)*value(cc)];
%             end
%     
%             if psych_pairs ==1
%                 for cc=value(numClass)+1:value(numClass)+value(nPsych)/2
%                     bag = [bag ones(1,(probpsych*10))*(value(cc)+numClass*2)];
%                 end 
%             end
%             
%             pp=randsample(bag,length(bag));
%             thispair=[pairs_u(pp(1),1) pairs_u(pp(1),2)];
%             if pp(1) > value(numClass*2)
%                 thisclass(n_done_trials+1)=pp(1)+numClass*2;   
%             else
%                 thisclass(n_done_trials+1)=pp(1)+numClass;
%             end
%             
%         else
%             bag=[];
%             for cc=1:value(numClass)+(numClass-1)*value(midclass_pairs)
%             eval(sprintf('pr=value(probClass%d);',cc));
%             bag=[bag ones(1,(10-10*probpsych)*pr)*value(cc)];
%             end
%             
%             if psych_pairs ==1
%                 for cc=value(numClass)+1:value(numClass)+value(nPsych)/2
%                     bag = [bag ones(1,(probpsych*10))*(value(cc)+numClass)];
%                 end 
%             end
%             
%             pp=randsample(bag,length(bag));
%             thispair=[pairs_d(pp(1),1) pairs_d(pp(1),2)];
%             
%             if pp(1) > value(numClass)
%                 thisclass(n_done_trials+1)=pp(1)+numClass;   
%             else
%             thisclass(n_done_trials+1)=pp(1);
%             end
%         end;
%     end
    
    %% Case make_sequences
    case 'make_sequences'
   %% make sequences of sigma values -sequences are ABA (a) and ABB (b)   
   
    Ind=(value(s2_s1_ratio-1))/(1+value(s2_s1_ratio));
    S1=value(minS1); 
    S2=S1*(1-Ind)/(1+Ind);
    
    sequences_all=[];
    sequences_all(:,1)=[S1 S1];
    sequences_all(:,2)=[S2 S2];
    sequences_all(:,3)=[S1 S2];
        
    
    sequence_a.value = sequences_all(1,:);
    sequence_b.value = sequences_all(2,:);
    sequences.value=sequences_all;
      
    %% Case plot_pais
    case 'plot_sequences'  
    StimulusSection(obj,'make_sequences');
    maxS.value=max(value(sequences(:)));
    %% plot the sequence set
    cla(value(ax))
    xd=repmat([1:1:3],1,2);
    yd=[log(value(sequences(1,:))) log(value(sequences(2,:)))];
    for ii=1:length(xd)
        axes(value(ax));
        plot(xd(ii),yd(ii),'s','MarkerSize',15,'MarkerEdgeColor',[0 0 0],'LineWidth',2)
        hold on
        eval(sprintf('hperf%d=text(xd(ii),yd(ii),num2str(ii));',ii));
        hold on
    end
    axis square
%      Ytick=get(value(ax),'YtickLabel');
%      Xtick=get(value(ax),'XtickLabel');
    %set(value(ax),'ytick',((yd(1:1:end))),'xtick',xd);
    %set(value(ax),'yticklabel',exp(yd(1:1:end)),'xticklabel',xd);
    set(value(ax),'ytick',([min(yd) max(yd)]),'xtick',(1:1:3));
    set(value(ax),'yticklabel',exp([min(yd) max(yd)]),'xticklabel',(1:1:3));
    ylabel('\sigma in log scale','FontSize',16,'FontName','Cambria Math');  
    set(value(ax),'Fontsize',15)
    xlabel('Sequence','FontSize',16,'FontName','Cambria Math')
    
    SideSection(obj,'get_current_side');
    StimulusSection(obj,'pick_current_stimulus');


        %% plot the sequence
        h1.value=plot([1 2 3],[log(value(A1_sigma)),log(value(A2_sigma)),log(value(A3_sigma))],'s','color',[0.8 0.4 0.1],'markerfacecolor',[0.8 0.4 0.1],'MarkerSize',15,'LineWidth',3);
        %LOGplotPairs(thesepairs(:,1),thesepairs(:,2),'s',15,'k',1,16,thispair(1),thispair(2),value(ax),'init')

  %% Case Plot_perf
    case 'plot_perf'
    %% make numClass sequence of sigma values   
    StimulusSection(obj,'make_stimuli'); 

    
    %% plot the sequence set
    cla(value(axperf))
    xd=repmat([1:1:3],1,2);
    yd=[log(value(sequences(1,:))) log(value(sequences(2,:)))];
    for ii=1:length(xd)
        axes(value(axperf));
        plot(xd(ii),yd(ii),'s','MarkerSize',31,'MarkerEdgeColor',[0 0 0],'LineWidth',1.5)
        hold on
        eval(sprintf('perf=value(perfClass%d);',ii))
        text(xd(ii)-0.14,yd(ii),num2str(round(perf*1000)/10));
        hold on
    end
    axis square
    set(value(ax),'ytick',((yd(1:1:end))),'xtick',xd);
    set(value(ax),'yticklabel',exp(yd(1:1:end)),'xticklabel',repmat([1:1:3],1,2));    
    ylabel('\sigma in log scale','FontSize',16,'FontName','Cambria Math'); 
    set(value(axperf),'Fontsize',15)
    xlabel('Sequence','FontSize',16,'FontName','Cambria Math')

       
    %% Case get_class_perform
    case 'get_class_perform'
        if nargout > 0,
            for ii=1:numClass
            eval(sprintf('final_perf(ii)=value(perfClass%d);',ii));
            end
            eval(sprintf('x=[value(perfClass%d) value(perfClass%d) value(perfClass%d) value(perfClass%d);]',1,value(numClass), value(numClass)+1,value(numClass)));
            y=final_perf;
        end
       
    %% Case get_sequence
    case 'get_sequence'
        if nargout>0
            x=value(sequence_a);
            y=value(sequence_b);
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
        
    %% Case update_sequences
    case 'update_sequence'
        StimulusSection(obj,'plot_sequences');

    case 'update_sequence_history'
        ps=value(sequence_history);
        ps(n_done_trials)=value(thisclass(n_done_trials));
        sequence_history.value=ps;

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
    