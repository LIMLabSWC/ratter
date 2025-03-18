 
function [x, y] = PlayStimuli(obj, action, varargin)
GetSoloFunctionArgs(obj);

switch action,
    
  case 'init'
      
    if length(varargin) < 2,
      error('Need at least two arguments, x and y position, to initialize %s', mfilename);
    end;
    x = varargin{1}; y = varargin{2};
    
    ToggleParam(obj, 'StimuliPlayShow', 0, x, y, 'OnString', 'StimToPlay', ...
      'OffString', 'StimToPlay', 'TooltipString', 'Show/Hide Sounds panel'); 
    set_callback(StimuliPlayShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
    next_row(y);
    oldx=x; oldy=y;    parentfig=double(gcf);

    SoloParamHandle(obj, 'myfig', 'value', figure('Position', [100 100 560 440], ...
      'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
      'Name', mfilename), 'saveable', 0);
    set(double(gcf), 'Visible', 'off');
    x=10;y=10;
    
    MenuParam(obj, 'filter_type', {'GAUS','LPFIR', 'FIRLS','BUTTER','MOVAVRG','KAISER','EQUIRIP','HAMMING'}, ...
    'GAUS', x, y, 'labelfraction', 0.35, 'TooltipString', sprintf(['\nDifferent filters. ''LPFIR'': lowpass FIR ''FIRLS'': Least square linear-phase FIR filter design\n', ...
    '\n''BUTTER'': IIR Butterworth lowpass filter ''GAUS'': Gaussian filter (window)\n', ...
    '\n''MOVAVRG'': Moving average FIR filter ''KAISER'': Kaiser-window FIR filtering\n', ...
    '\n''EQUIRIP'':Eqiripple FIR filter ''HAMMING'': Hamming-window based FIR'])); 
    next_row(y, 1.3)
    NumeditParam(obj, 'A1_sigma', 0.01, x,y,'label','A1_sigma','TooltipString','Sigma value for the stimulus');
    next_row(y);
    NumeditParam(obj,'fcut',110,x,y,'label','fcut','TooltipString','Cut off frequency on the original white noise');
    next_row(y);
    NumeditParam(obj,'lfreq',2000,x,y,'label','Modulator_LowFreq','TooltipString','Lower bound for the frequency modulator');
    next_row(y);
    NumeditParam(obj,'hfreq',20000,x,y,'label','Modulator_HighFreq','TooltipString','Upper bound for the frequency modulator');	
    next_row(y);
    NumeditParam(obj,'dur',0.5,x,y,'label','dur','TooltipString','duration of stimulus in ms');	
    next_row(y);
    
    sname='GaussNoise';
    
    srate=SoundManagerSection(obj,'get_sample_rate');
    Fs=srate;
    replace=1;
    T=dur;
    L=floor(T*Fs);                      % Length of signal
    sigma_1=1;

    pos1 = sigma_1*randn(Fs,1); 
    base = randsample(pos1,L,replace);
    filtbase=filt(base,fcut,Fs,value(filter_type));
    normbase=filtbase./(max(abs(filtbase)));

    mod1 = sigma_1*randn(Fs,1);
    mod1 = randsample(mod1,L,replace);
    hf = design(fdesign.bandpass('N,F3dB1,F3dB2',10,value(lfreq),value(hfreq),Fs));
    filtmod=filter(hf,mod1);
    modulator=filtbase./(max(abs(filtmod)));

    AUD1=normbase(1:dur*srate).*modulator(1:dur*srate).*A1_sigma;
    w=[AUD1';  AUD1'];
    SoundManagerSection(obj, 'declare_new_sound', sname);
    SoundManagerSection(obj, 'set_sound',sname,w)
    
    SubheaderParam(obj, [sname 'Head'], sname, x,y,'TooltipString','');
    PushbuttonParam(obj, [sname 'Play'], x,y, 'label', 'Play', 'position', [x y 30 20]);
    set_callback(eval([sname 'Play']),{'SoundManagerSection', 'play_sound', sname});
    PushbuttonParam(obj, [sname 'Stop'], x,y, 'label', 'Stop', 'position', [x+30 y 30 20]);
    set_callback(eval([sname 'Stop']),{'SoundManagerSection', 'stop_sound', sname});
    
    x=oldx; y=oldy;
    figure(parentfig);
    
  case 'hide',
    StimuliPlayShow.value = 0; set(value(myfig), 'Visible', 'off');

  case 'show',
    StimuliPlayShow.value = 1; set(value(myfig), 'Visible', 'on');

  case 'show_hide',
    if StimuliPlayShow == 1, set(value(myfig), 'Visible', 'on'); %#ok<NODEF> (defined by GetSoloFunctionArgs)
    else                   set(value(myfig), 'Visible', 'off');
    end;
end
