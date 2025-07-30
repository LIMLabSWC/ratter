%
% PARAMETERS:
% -----------
%
% obj      Default object argument.
%
% action   One of:
%
%            'prepare_next_trial'   
%
%            'init'
%
%
% RETURNS:
% --------

function [varargout] = StimulatorSection(obj, action, x, y)
   
GetSoloFunctionArgs(obj);

switch action
    
%% init
% ----------------------------------------------------------------
%
%       INIT
%
% ----------------------------------------------------------------
  
  case 'init'
      
      % diolines = bSettings('get','DIOLINES', 'all');
      % for i = 1:size(diolines,1); dionames{i} = diolines{i,1}; dionums(i) = diolines{i,2}; end %#ok<AGROW>
      % [dionums order] = sort(dionums);
      % dionames2 = cell(0);
      % for i = 1:length(dionums); if ~isnan(dionums(i)); dionames2{end+1} = dionames{order(i)}; end; end %#ok<AGROW>
           
      NumeditParam(obj,'StimStates', 1,x,y,'position',[x     y 100 20],'labelfraction',0.60);
      NumeditParam(obj,'StimLines',  1,x,y,'position',[x+100 y 100 20],'labelfraction',0.60); next_row(y);
      
      NumeditParam(obj,'StartDelay', 0,x,y,'position',[x     y 100 20],'labelfraction',0.60);
      NumeditParam(obj,'StimFreq',  20,x,y,'position',[x+100 y 100 20],'labelfraction',0.60); next_row(y);
      NumeditParam(obj,'PulseWidth',15,x,y,'position',[x     y 100 20],'labelfraction',0.60); 
      NumeditParam(obj,'NumPulses', 1,x,y,'position',[x+100 y 100 20],'labelfraction',0.60); next_row(y);
      
      DispParam(obj,'SD',0 ,x,y,'position',[x     y 50 20],'labelfraction',0.4);
      DispParam(obj,'SF',20,x,y,'position',[x+50  y 50 20],'labelfraction',0.4);
      DispParam(obj,'PW',15,x,y,'position',[x+100 y 50 20],'labelfraction',0.4);
      DispParam(obj,'NP',1,x,y,'position',[x+150 y 50 20],'labelfraction',0.4); next_row(y);  
      
      MenuParam(obj,'StimInterval',{'WholeCP_Duration','CP_DurationAfterPrestim','Prestim','S1','DelayDur','GoCue'},1,x,y,'labelfraction',0.30); next_row(y);
      set_callback(StimInterval, {mfilename, 'StimInterval'});
      
      MenuParam(obj,'StimOnSide',{'both','left','right'},1,x,y,'labelfraction',0.3); next_row(y);
      
      SC = state_colors(obj);
      WC = wave_colors(obj); 
      states = fieldnames(SC);
      waves  = fieldnames(WC);
      states(2:end+1) = states;
      states{1} = 'cp';
      states(end+1:end+length(waves)) = waves;
      
      MenuParam(obj,'StimState',states,1,x,y,'labelfraction',0.30); next_row(y);

      NumeditParam(obj,'StimProb',     0,x,y,'position',[x     y 100 20],'labelfraction',0.65);
      ToggleParam( obj,'ShuffleValues',0,x,y,'position',[x+100 y 100 20],'OnString','Shuffle','OffString','Lock');  next_row(y);
      
      dionames = {'none','Opto','Ephys'};
      
      MenuParam(obj,'StimLine',dionames,1,x,y,'labelfraction',0.30); next_row(y);
      set_callback(StimLine, {mfilename, 'StimSelected'});

      SoloParamHandle(obj, 'stimulator_history',   'value', []);
       
      make_invisible(StimStates); make_invisible(StimLines); make_invisible(StartDelay); make_invisible(StimFreq);
      make_invisible(PulseWidth); make_invisible(NumPulses); make_invisible(SD); make_invisible(SF);
      make_invisible(PW); make_invisible(NP); make_invisible(StimInterval); make_invisible(StimOnSide);
      make_invisible(StimState); make_invisible(StimProb); make_invisible(ShuffleValues);

      SubheaderParam(obj, 'title', 'Stimulator Section', x, y); next_row(y);

      SoloFunctionAddVars('ArpitSoundCatContinuousSMA', 'ro_args',{'StimLine'});

      varargout{1} = x;
      varargout{2} = y;
      
%% update_values
% -----------------------------------------------------------------------
%
%         UPDATE_VALUES
%
% -----------------------------------------------------------------------

  case 'StimSelected'

      if strcmpi(value(StimLine),'Opto')
          make_visible(StimStates); make_visible(StimLines); make_visible(StartDelay); make_visible(StimFreq);
          make_visible(PulseWidth); make_visible(NumPulses); make_visible(SD); make_visible(SF);
          make_visible(PW); make_visible(NP); make_visible(StimInterval); make_visible(StimOnSide);
          make_visible(StimState); make_visible(StimProb); make_visible(ShuffleValues);
      else
          make_invisible(StimStates); make_invisible(StimLines); make_invisible(StartDelay); make_invisible(StimFreq);
          make_invisible(PulseWidth); make_invisible(NumPulses); make_invisible(SD); make_invisible(SF);
          make_invisible(PW); make_invisible(NP); make_invisible(StimInterval); make_invisible(StimOnSide);
          make_invisible(StimState); make_invisible(StimProb); make_invisible(ShuffleValues);
      end

      if strcmpi(value(StimLine),'Ephys')
          dispatcher('set_trialnum_indicator_flag');
      else
          dispatcher('unset_trialnum_indicator_flag');
      end

  case 'update_values'
       
      if strcmpi(value(StimLine),'Opto')
    	  
          StimulatorSection(obj,'StimInterval');
          sh = value(stimulator_history); %#ok<NODEF>
          
          if ~dispatcher('is_running')
              %dispatcher is not running, last stim_hist not used, lop it off
              sh = sh(1:end-1);
          end

          if value(StimProb) == 0
              stimulator_history.value = [sh, 0];
          elseif rand(1) <= value(StimProb)
              stimulator_history.value = [sh, 1];            
          else
              stimulator_history.value = [sh, 0];
          end

      end
      
      if strcmpi(value(StimLine),'Ephys') & n_done_trials == 0
            dispatcher('set_trialnum_indicator_flag');
      end
      
      
      
%% prepare_next_trial
% -----------------------------------------------------------------------
%
%         PREPARE_NEXT_TRIAL
%
% -----------------------------------------------------------------------

  case 'prepare_next_trial'
      sh = value(stimulator_history); %#ok<NODEF>
      
      sma = x;

      sd = value(StartDelay); 
      sf = value(StimFreq);   
      pw = value(PulseWidth);
      np = value(NumPulses);  
      ss = value(StimStates);
      sl = value(StimLines);

      if value(ShuffleValues) == 1
          sd = sd(ceil(rand(1) * length(sd)));
          sf = sf(ceil(rand(1) * length(sf)));
          pw = pw(ceil(rand(1) * length(pw)));
          np = np(ceil(rand(1) * length(np)));
          ss = ss(ceil(rand(1) * length(ss)));
          sl = sl(ceil(rand(1) * length(sl)));
      else
          if length(unique([length(sd) length(sf) length(pw) length(np) length(ss) length(sl)])) > 1
              disp('Warning: param values in StimulatorSection have different lengths. Only first value will be used.');
              temp = 1;
          else
              temp = ceil(rand(1) * length(sd));
          end
          sd = sd(temp); sf = sf(temp); pw = pw(temp); np = np(temp); ss = ss(temp); sl = sl(temp);
      end
      
      pss = get(get_ghandle(StimState),'String'); %#ok<NODEF>
      psl = get(get_ghandle(StimLine), 'String'); %#ok<NODEF>
      if ss > length(pss)
          disp('StimState value greater than list of possible stim states');
      else
          StimState.value = ss;
          % disp('test ss');
          value(ss);
      end
          
      if sl > length(psl)
          slc = ['0',num2str(sl),'0'];
          z = find(slc == '0');
          if length(z) > 2
              sln = [];
              for i = 1:length(z)-1
                  sln(end+1) = str2num(slc(z(i)+1:z(i+1)-1)); %#ok<ST2NM,AGROW>
              end
              if any(sln > length(psl))
                  disp('StimLine value greater than list of possible stim lines');
              else
                  slname = psl{sln(1)};
                  for i=2:length(sln)
                      slname = [slname,'+',psl{sln(i)}]; %#ok<AGROW>
                  end
                  if sum(strcmp(psl,slname)) == 0
                      psl{end+1} = slname; 
                      set(get_ghandle(StimLine),'String',psl)
                  end
                  StimLine.value = find(strcmp(psl,slname)==1,1,'first');
                  sl = sln;
              end
          else
              disp('StimLine value greater than list of possible stim lines');
          end
      else
          StimLine.value  = sl;
      end
      
      for i = 1:length(sl)
          stimline = bSettings('get','DIOLINES',psl{sl(i)}); 
      
          sma = add_scheduled_wave(sma,...
              'name',          ['stimulator_wave',num2str(i)],...
              'preamble',      (1/sf)-(pw/1000),... %%%% Remember: change it such that if this is negative makes it 0
              'sustain' ,      pw/1000,...
              'DOut',          stimline,...
              'loop',          np-1);

          if sd ~= 0
              sma = add_scheduled_wave(sma,...
                  'name',['stimulator_wave_pause',num2str(i)],...
                  'preamble',sd,...
                  'trigger_on_up',['stimulator_wave',num2str(i)]);
          else
              sma = add_scheduled_wave(sma,...
                  'name',['stimulator_wave_pause',num2str(i)],...
                  'preamble',1,...
                  'trigger_on_up',['stimulator_wave',num2str(i)]);
          end
      end
      
      for i = 1:length(sl)
          if sh(end) == 1
              if strcmp(value(StimState),'none') == 0
                  if sd ~= 0
                      sma = add_stimulus(sma,['stimulator_wave_pause',num2str(i)],value(StimState));
                  else
                      sma = add_stimulus(sma,['stimulator_wave',num2str(i)],value(StimState));
                  end

                  SD.value = sd; SF.value = sf; PW.value = pw; NP.value = np;
              end
          else
              SD.value = 0; SF.value = 0; PW.value = 0; NP.value = 0;
          end
      end
      
      varargout{1} = sma; 

     
  %% Case StimInterval  
    case 'StimInterval'
        
        if strcmp(StimInterval, 'WholeCP_Duration')
            PulseWidth.value = Total_CP_duration*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = 0;
        elseif strcmp(StimInterval, 'CP_DurationAfterPrestim')
            PulseWidth.value = (Total_CP_duration - PreStim_time)*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = PreStim_time;
        elseif strcmp(StimInterval, 'Prestim')
            PulseWidth.value = PreStim_time*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = 0;
        elseif strcmp(StimInterval, 'S1')
            PulseWidth.value = A1_time*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = PreStim_time;
        elseif strcmp(StimInterval, 'DelayDur')
            PulseWidth.value = time_bet_aud1_gocue*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = PreStim_time + A1_time;
        elseif strcmp(StimInterval, 'GoCue')
            PulseWidth.value = time_go_cue*1000;
            StimFreq.value = 1000/PulseWidth;
            StartDelay.value = PreStim_time + A1_time + time_bet_aud1_gocue;                
        end
%% set
% -----------------------------------------------------------------------
%
%         SET
%
% -----------------------------------------------------------------------      
  case 'set'
    varname = x;
    newval  = y;
    
    try
        temp = 'SoloParamHandle';  %#ok<NASGU>
        eval(['test = isa(',varname,',temp);']);
        if test == 1
            eval([varname,'.value = newval;']);
        end
    catch  %#ok<CTCH>
        showerror;
        warning(['Unable to assign value: ',num2str(newval),' to SoloParamHandle: ',varname]);  %#ok<WNTAG>
    end

    
%% get
% -----------------------------------------------------------------------
%
%         GET
%
% -----------------------------------------------------------------------     
  case 'get'  
    varname = x;
    
    try
        temp = 'SoloParamHandle'; %#ok<NASGU>
        eval(['test = isa(',varname,',temp);']);
        if test == 1
            eval(['varargout{1} = value(',varname,');']);
        end
    catch %#ok<CTCH>
        showerror;
        warning(['Unable to get value from SoloParamHandle: ',varname]);  %#ok<WNTAG>
    end

    
%% reinit
% -----------------------------------------------------------------------
%
%         REINIT
%
% -----------------------------------------------------------------------     
  case 'reinit'
    currfig = double(gcf);

    % Delete all SoloParamHandles who belong to this object and whose
    % fullname starts with the name of this mfile:
    delete_sphandle('owner', ['^@' class(obj) '$'], ...
      'fullname', ['^' mfilename]);
    

    % Reinitialise at the original GUI position and figure:
    feval(mfilename, obj, 'init');

    % Restore the current figure:
    figure(currfig);
end


