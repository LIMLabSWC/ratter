

function [x, y] = SoundSection(obj, action, varargin)

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
    
    ToggleParam(obj, 'SoundsShow', 0, x, y, 'OnString', 'Sounds', ...
      'OffString', 'Sounds', 'TooltipString', 'Show/Hide Sounds panel'); 
    set_callback(SoundsShow, {mfilename, 'show_hide'}); %#ok<NODEF> (Defined just above)
    next_row(y);
    oldx=x; oldy=y;    parentfig=double(gcf);

    SoloParamHandle(obj, 'myfig', 'value', figure('Position', [100 100 560 440], ...
      'closerequestfcn', [mfilename '(' class(obj) ', ''hide'');'], 'MenuBar', 'none', ...
      'Name', mfilename), 'saveable', 0);
    set(double(gcf), 'Visible', 'off');
    x=10;y=10;

    [x,y]=SoundInterface(obj,'add','ViolationSound',x,y,'Volume',0.005,'Freq',1000,'Duration',0.5); 
%     [x,y]=SoundInterface(obj,'add','ViolationSound',x,y,'Style','WhiteNoise','Volume',0.01);    
    [x,y]=SoundInterface(obj,'add','TimeoutSound',x,y,'Style','WhiteNoise','Volume',0.08,'Duration',0.5);
    [x,y]=SoundInterface(obj,'add','RewardSound',x,y,'Style','Bups','Volume',1,'Freq',5,'Duration',1.5);
    [x,y]=SoundInterface(obj,'add','ErrorSound',x,y,'Style','WhiteNoise','Volume',0.08);
    next_column(x);
    y=10;
    [x,y]=SoundInterface(obj,'add','GoSound',x,y,'Style','Tone','Volume',0.005,'Freq',3000,'Duration',0.2);
	SoundInterface(obj, 'disable', 'GoSound', 'Dur1');	
    SoundInterface(obj, 'disable', 'GoSound', 'Freq1');
    [x,y]=SoundInterface(obj,'add','SOneSound',x,y,'Style','Tone','Volume',0.005,'Freq',3000,'Duration',0.2);
    [x,y]=SoundInterface(obj,'add','STwoSound',x,y,'Style','WhiteNoise','Volume',0.08);
    
    x=oldx; y=oldy;
    figure(parentfig);
    
  case 'hide',
    SoundsShow.value = 0; set(value(myfig), 'Visible', 'off');

  case 'show',
    SoundsShow.value = 1; set(value(myfig), 'Visible', 'on');

  case 'show_hide',
    if SoundsShow == 1, set(value(myfig), 'Visible', 'on'); %#ok<NODEF> (defined by GetSoloFunctionArgs)
    else                   set(value(myfig), 'Visible', 'off');
    end;
    
end
    