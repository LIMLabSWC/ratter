
% MATLAB script for calibrating sound pressure level using Arduino and serial communication in real-time.
%
% This script automates the process of calibrating a speaker using an Arduino and a sound level meter.
% It communicates with an Arduino to control speaker output and read sound pressure level (SPL) measurements.
% The script performs the following steps:
% 1. Establishes serial communication with the Arduino.
% 2. Creates a figure window with a table to display real-time SPL readings.
% 3. Iterates through a set of speaker output values, sending each value to the speaker (via a user-defined function).
% 4. At each speaker output level, the script reads the corresponding SPL from the Arduino.
% 5. The measured SPL values are displayed in the table in real-time.
% 6. After completing the measurements, the script displays the final calibration data and optionally plots the
%    relationship between speaker output and SPL, including a polynomial fit.
% 7. Includes error handling to ensure robust communication with the Arduino.

% Written by Arpit 2024

% Make sure you ran newstartup, then dispatcher('init'), and you're good to
% go!
%

function [obj] = Arpit_SoundCalibration(varargin)

% Default object is of our own class (mfilename); in this simplest of
% protocols, we inherit only from Plugins/@pokesplot

obj = class(struct, mfilename, soundmanager, soundui);

%---------------------------------------------------------------
%   BEGIN SECTION COMMON TO ALL PROTOCOLS, DO NOT MODIFY
%---------------------------------------------------------------

% If creating an empty object, return without further ado:
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty')),
    return;
end;

if isa(varargin{1}, mfilename), % If first arg is an object of this class itself, we are
    % Most likely responding to a callback from
    % a SoloParamHandle defined in this mfile.
    if length(varargin) < 2 || ~ischar(varargin{2}),
        error(['If called with a "%s" object as first arg, a second arg, a ' ...
            'string specifying the action, is required\n']);
    else action = varargin{2}; varargin = varargin(3:end); %#ok<NASGU>
    end;
else % Ok, regular call with first param being the action string.
    action = varargin{1}; varargin = varargin(2:end); %#ok<NASGU>
end;
if ~ischar(action), error('The action parameter must be a string'); end;

GetSoloFunctionArgs(obj);

%---------------------------------------------------------------
%   END OF SECTION COMMON TO ALL PROTOCOLS, MODIFY AFTER THIS LINE
%---------------------------------------------------------------


% ---- From here on is where you can put the code you like.
%
% Your protocol will be called, at the appropriate times, with the
% following possible actions:
%
%   'init'     To initialize -- make figure windows, variables, etc.
%
%   'update'   Called periodically within a trial
%
%   'prepare_next_trial'  Called when a trial has ended and your protocol
%              is expected to produce the StateMachine diagram for the next
%              trial; i.e., somewhere in your protocol's response to this
%              call, it should call "dispatcher('send_assembler', sma,
%              prepare_next_trial_set);" where sma is the
%              StateMachineAssembler object that you have prepared and
%              prepare_next_trial_set is either a single string or a cell
%              with elements that are all strings. These strings should
%              correspond to names of states in sma.
%                 Note that after the 'prepare_next_trial' call, further
%              events may still occur in the RTLSM while your protocol is thinking,
%              before the new StateMachine diagram gets sent. These events
%              will be available to you when 'trial_completed' is called on your
%              protocol (see below).
%
%   'trial_completed'   Called when 'state_0' is reached in the RTLSM,
%              marking final completion of a trial (and the start of
%              the next).
%
%   'close'    Called when the protocol is to be closed.
%
%
% VARIABLES THAT DISPATCHER WILL ALWAYS INSTANTIATE FOR YOU IN YOUR
% PROTOCOL:
%
% (These variables will be instantiated as regular Matlab variables,
% not SoloParamHandles. For any method in your protocol (i.e., an m-file
% within the @your_protocol directory) that takes "obj" as its first argument,
% calling "GetSoloFunctionArgs(obj)" will instantiate all the variables below.)
%
%
% n_done_trials     How many trials have been finished; when a trial reaches
%                   one of the prepare_next_trial states for the first
%                   time, this variable is incremented by 1.
%
% n_started trials  How many trials have been started. This variable gets
%                   incremented by 1 every time the state machine goes
%                   through state 0.
%
% parsed_events     The result of running disassemble.m, with the
%                   parsed_structure flag set to 1, on all events from the
%                   start of the current trial to now.
%
% latest_events     The result of running disassemble.m, with the
%                   parsed_structure flag set to 1, on all new events from
%                   the last time 'update' was called to now.
%
% raw_events        All the events obtained in the current trial, not parsed
%                   or disassembled, but raw as gotten from the State
%                   Machine object.
%
% current_assembler The StateMachineAssembler object that was used to
%                   generate the State Machine diagram in effect in the
%                   current trial.
%
% Trial-by-trial history of parsed_events, raw_events, and
% current_assembler, are automatically stored for you in your protocol by
% dispatcher.m. See the wiki documentation for information on how to access
% those histories from within your protocol and for information.
%
%


switch action

    %---------------------------------------------------------------
    %          CASE INIT
    %---------------------------------------------------------------

    case 'init'

        % Make default figure. We remember to make it non-saveable; on next run
        % the handle to this figure might be different, and we don't want to
        % overwrite it when someone does load_data and some old value of the
        % fig handle was stored as SoloParamHandle "myfig"
        SoloParamHandle(obj, 'myfig', 'saveable', 0); myfig.value = double(figure);

        % Make the title of the figure be the protocol name, and if someone tries
        % to close this figure, call dispatcher's close_protocol function, so it'll know
        % to take it off the list of open protocols.
        name = mfilename;
        set(value(myfig), 'Name', name, 'Tag', name, ...
            'closerequestfcn', [mfilename,'(''close'');'], 'MenuBar', 'none');


        %     Generate the sounds we need.
        soundserver = bSettings('get','RIGS','sound_machine_server');
        if ~isempty(soundserver)
            sr = SoundManagerSection(obj,'get_sample_rate');
            Fs=sr;
            lfreq=2000;
            hfreq=20000;
            freq = 100;
            T = 5;
            fcut = 110;
            filter_type = 'GAUS';
            A1_sigma = 0.0500;
            A2_sigma = 0.0306; %0.1230;%0.0260;
            A3_sigma = 0.0187; %0.0473;%0.0135;
            A4_sigma = 0.0114; %0.0182;%0.0070;
            A5_sigma = 0.0070;
            [rawA1 rawA2 normA1 normA2]=noisestim(1,1,T,fcut,Fs,filter_type);
            modulator=singlenoise(1,T,[lfreq hfreq],Fs,'BUTTER');
            AUD1=normA1(1:T*sr).*modulator(1:T*sr).*A1_sigma;
            AUD2=normA1(1:T*sr).*modulator(1:T*sr).*A2_sigma;
            AUD3=normA1(1:T*sr).*modulator(1:T*sr).*A3_sigma;
            AUD4=normA1(1:T*sr).*modulator(1:T*sr).*A4_sigma;
            AUD5=normA1(1:T*sr).*modulator(1:T*sr).*A5_sigma;
           
            if ~isempty(AUD2)
                SoundManagerSection(obj, 'declare_new_sound', 'left_sound', [AUD2';  AUD2'])
            end
            if ~isempty(AUD1)
                SoundManagerSection(obj, 'declare_new_sound', 'center_sound', [AUD1';  AUD1'])
            end
            if ~isempty(AUD3)
                SoundManagerSection(obj, 'declare_new_sound', 'right_sound', [AUD3';  AUD3'])
            end
            if ~isempty(AUD4)
                SoundManagerSection(obj, 'declare_new_sound', 'fourth_sound', [AUD4';  AUD4'])
            end
            if ~isempty(AUD5)
                SoundManagerSection(obj, 'declare_new_sound', 'fifth_sound', [AUD5';  AUD5'])
            end
            SoundManagerSection(obj, 'send_not_yet_uploaded_sounds');
        end

        % Get monitor dimensions for dynamic GUI sizing
        MP = get(0,'MonitorPositions');

        % Calculate individual group width based on screen dimensions and number of groups
        groupwidth = floor((MP(3)/2)/numel(linegroups));

        padding = 10 % padding around GUI elements

        % Calculate total width needed for all groups combined
        total_width = floor(numel(linegroups) * groupwidth+padding);
        total_height = 400 % total height of GUI
        
        label_height = 140 % height of port label
        button_height = 25

        % Center the GUI horizontally on screen
        left_pos = floor((MP(3) - total_width) / 2);

        % Set figure position with centered alignment and fixed height of 400 pixels
        % position vector: [left-right, down-up, width, height], the origo is
        % the bottom left corner
        set(value(myfig), 'Position', [left_pos, floor((MP(4)-total_height)/2), total_width, total_height]);

        % Initialize array to store line names
        line_names = [];

        % Iterate through each line group
        
            % Check if current group exists and has valid parameters
            if ~isempty(linegroups{i}) && ~isempty(linegroups{i}{1,2})
                % port label position
                SubheaderParam( ...
                    obj, ...
                    ['Input',linegroups{i}{1,2}], ...
                    {linegroups{i}{1,2};0},0,0, ...
                    'position',[((i-1)*groupwidth)+padding, ...
                    total_height-padding-label_height, ...
                    groupwidth-padding, ...
                    label_height ...
                    ]);

                % port label aesthetics
                set(get_ghandle(eval(['Input',linegroups{i}{1,2}])), ...
                    'FontSize',32, ...          % Large font size for visibility
                    'BackgroundColor',[0,1,0], ... % Green background
                    'HorizontalAlignment','center'); % Center align text

                % Store line name for later reference
                line_names(end+1) = linegroups{i}{1,2}; %#ok<AGROW>

                % Add sound controls based on line identifier
                if strcmp(linegroups{i}{1,2},'L') && ~isempty(soundserver)
                    % Left channel sound toggle
                    ToggleParam(obj, ...
                        'LeftSound', 0,0,0, ...
                        'position',[((i-1)*groupwidth)+padding, padding, groupwidth-padding,button_height], ...
                        'OnString', 'Sound Two ON',        ...
                        'OffString', 'Sound Two OFF');
                    set_callback(LeftSound,{mfilename,'play_left_sound'});

                elseif strcmp(linegroups{i}{1,2},'R') && ~isempty(soundserver)
                    % Right channel sound toggle
                    ToggleParam(obj, ...
                        'RightSound', 0,0,0, ...
                        'position',[((i-1)*groupwidth)+padding, padding, groupwidth-padding,button_height], ...
                        'OnString', 'Sound Three ON',       ...
                        'OffString', 'Sound Three OFF');
                    set_callback(RightSound,{mfilename,'play_right_sound'});

                elseif strcmp(linegroups{i}{1,2},'C') && ~isempty(soundserver)
                    % Center channel sound toggle
                    ToggleParam(obj, ...
                        'CenterSound', 0,0,0, ...
                        'position',[((i-1)*groupwidth)+padding, padding, groupwidth-padding,button_height], ...
                        'OnString', 'Sound One ON',      ...
                        'OffString', 'Sound One OFF');
                    set_callback(CenterSound,{mfilename,'play_center_sound'});

                elseif strcmp(linegroups{i}{1,2},'A') && ~isempty(soundserver)
                    % Additional channel sound toggle
                    ToggleParam(obj, ...
                        'FourthSound', 0,0,0, ...
                        'position',[((i-1)*groupwidth)+padding, padding, groupwidth-padding,button_height], ...
                        'OnString', 'Sound Four ON',      ...
                        'OffString', 'Sound Four OFF');
                    set_callback(FourthSound,{mfilename,'play_fourth_sound'});
                end

                % Handle case for empty line identifier but existing group
            elseif ~isempty(linegroups{i}) && isempty(linegroups{i}{1,2})
                ToggleParam(obj, ...
                    'FifthSound', 0,0,0, ...
                    'position',[((i-1)*groupwidth)+padding, padding, groupwidth-padding,button_height], ...
                    'OnString', 'Sound Five ON',       ...
                    'OffString', 'Sound Five OFF');
                set_callback(FifthSound,{mfilename,'play_fifth_sound'});
            end

            

        SoloParamHandle(obj,'LineGroups','value',linegroups);
        SoloParamHandle(obj,'LineNames','value',line_names);

        scr = timer;
        set(scr,'Period', 0.2,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
            'BusyMode','drop','TimerFcn',[mfilename,'(''close_continued'')']);
        SoloParamHandle(obj, 'stopping_complete_timer', 'value', scr);

        Arpit_SoundCalibration(obj,'prepare_next_trial');

        dispatcher('Run');


    case 'play_left_sound'
        %% play_left_sound
        if value(LeftSound) == 1
            SoundManagerSection(obj,'play_sound','left_sound');
        else
            SoundManagerSection(obj,'stop_sound','left_sound');
        end

    case 'play_right_sound'
        %% play_right_sound
        if value(RightSound) == 1
            SoundManagerSection(obj,'play_sound','right_sound');
        else
            SoundManagerSection(obj,'stop_sound','right_sound');
        end

    case 'play_center_sound'
        %% play_center_sound
        if value(CenterSound) == 1
            SoundManagerSection(obj,'play_sound','center_sound');
        else
            SoundManagerSection(obj,'stop_sound','center_sound');
        end

    case 'play_fourth_sound'
        %% play_fourth_sound
        if value(FourthSound) == 1
            SoundManagerSection(obj,'play_sound','fourth_sound');
        else
            SoundManagerSection(obj,'stop_sound','fourth_sound');
        end
    case 'play_fifth_sound'
        %% play_fifth_sound
        if value(FifthSound) == 1
            SoundManagerSection(obj,'play_sound','fifth_sound');
        else
            SoundManagerSection(obj,'stop_sound','fifth_sound');
        end
   
    case 'toggle16_2'
        %% case toggle1_2
        linegroups = value(LineGroups);
        dispatcher('toggle_bypass',log2(linegroups{16}{3,1}));

        %---------------------------------------------------------------
        %          CASE PREPARE_NEXT_TRIAL
        %---------------------------------------------------------------
    case 'prepare_next_trial'
        line_names = value(LineNames);
        sma = StateMachineAssembler('full_trial_structure','use_happenings',1); %,'n_input_lines',numel(line_names),'line_names',line_names);
        sma = add_state(sma, 'name', 'the_only_state', 'self_timer',1e4, 'input_to_statechange', {'Tup', 'final_state'});
        sma = add_state(sma, 'name', 'final_state',    'self_timer',1e4, 'input_to_statechange', {'Tup', 'check_next_trial_ready'});
        dispatcher('send_assembler', sma, 'final_state');

        %---------------------------------------------------------------
        %          CASE TRIAL_COMPLETED
        %---------------------------------------------------------------
    case 'trial_completed'


        %---------------------------------------------------------------
        %          CASE UPDATE
        %---------------------------------------------------------------
    case 'update'
        pe = parsed_events; %#ok<NASGU>
        linenames = value(LineNames);

        for i = 1:numel(linenames)
            poketimes = eval(['pe.pokes.',linenames(i)]);
            if ~isempty(poketimes) && isnan(poketimes(end,2))
                set(get_ghandle(eval(['Input',linenames(i)])),'BackgroundColor',[1,0,0]);

                str = get(get_ghandle(eval(['Input',linenames(i)])),'string');
                str{2} = size(poketimes,1);
                set(get_ghandle(eval(['Input',linenames(i)])),'string',str);

            else
                set(get_ghandle(eval(['Input',linenames(i)])),'BackgroundColor',[0,1,0]);
            end
        end

        %---------------------------------------------------------------
        %          CASE CLOSE
        %---------------------------------------------------------------
    case 'close'

        dispatcher('Stop');

        %Let's pause until we know dispatcher is done running
        set(value(stopping_complete_timer),'TimerFcn',[mfilename,'(''close_continued'');']);
        start(value(stopping_complete_timer));

    case 'close_continued'

        if value(stopping_process_completed)
            stop(value(stopping_complete_timer)); %Stop looping.
            %dispatcher('set_protocol','');

            if exist('myfig', 'var') && isa(myfig, 'SoloParamHandle') && ishandle(value(myfig)), %#ok<NODEF>
                delete(value(myfig));
            end
            delete_sphandle('owner', ['^@' class(obj) '$']);
            dispatcher('set_protocol','');
        end

    otherwise

        warning('Unknown action! "%s"\n', action); %#ok<WNTAG>
        end

return;

end
















function [normbase]=singlenoise(sigma_1,T,fcut,Fs,filter_type)

%%%%%%%%%%%%%%%%% Determines of the type of filter used %%%%%%%%%%%%%%%%%%%
%'LPFIR': lowpass FIR%%%%%'FIRLS': Least square linear-phase FIR filter design
%'BUTTER': IIR Butterworth lowpass filter%%%%%%'GAUS': Gaussian filter (window)
%'MOVAVRG': Moving average FIR filter%%%%%%%%'KAISER': Kaiser-window FIR filtering
% 'EQUIRIP':Eqiripple FIR filter%%%%% 'HAMMING': Hamming-window based FIR 
% T is duration of each signal in milisecond, fcut is the cut-off frequency                                     
% Fs is the sampling frequency
% outband=40;
% filter_type='BUTTER';

outband=60;
replace=1;
L=floor(T*Fs);% Length of signal

%%%%%%%%%%% produce position values %%%%%%%
pos1 = sigma_1 * randn(Fs,1);

% pos1(pos1>outband)=[];
% pos1(pos1<-outband)=[];
    
base = randsample(pos1,L,replace);
%%%% Filter the original position values %%%%%%
%filtbase=filt(base,fcut,Fs,filter_type);
hf = design(fdesign.bandpass('N,F3dB1,F3dB2',10,fcut(1),fcut(2),Fs));
filtbase=filter(hf,base);
normbase=filtbase./(max(abs(filtbase)));

end


function [base,target,normbase,normtarget]=noisestim(sigma_1,sigma_2,T,fcut,Fs,filter_type)

%%%%%%%%%%%%%%%%% Determines of the type of filter used %%%%%%%%%%%%%%%%%%%
%'LPFIR': lowpass FIR%%%%%'FIRLS': Least square linear-phase FIR filter design
%'BUTTER': IIR Butterworth lowpass filter%%%%%%'GAUS': Gaussian filter (window)
%'MOVAVRG': Moving average FIR filter%%%%%%%%'KAISER': Kaiser-window FIR filtering
% 'EQUIRIP':Eqiripple FIR filter%%%%% 'HAMMING': Hamming-window based FIR 
% T is duration of each signal in milisecond, fcut is the cut-off frequency                                     
% Fs is the sampling frequency
% outband=40;
replace=1;
L=floor(T*Fs);                      % Length of signal
% t=L*linspace(0,1,L)/Fs;          % time in miliseconds
%%%%%%%%%%% produce position values %%%%%%%
pos1 = sigma_1*randn(Fs,1);
% pos1(pos1>outband)=[];
% pos1(pos1<-outband)=[];
    
pos2 =sigma_2*randn(Fs,1);
% pos2(pos2>outband)=[];
% pos2(pos2<-outband)=[];
base = randsample(pos1,L,replace);
target = randsample(pos2,L,replace);
%%%% Filter the original position values %%%%%%
filtbase=filt(base,fcut,Fs,filter_type);
filttarget=filt(target,fcut,Fs,filter_type);
normbase=filtbase./(max(abs(filtbase)));
normtarget=filttarget./(max(abs(filttarget)));

end




function filtsignal=filt(signal,fcut,Fs,filter_type)
a=2;            % wp/ws used in butterworth method and LS linear FIR method
N=200;          % filter order used in lowpass FIR method
rp=3;           % passband ripple in dB used in butterworth method
rs=60;          % stopband attenuation in dB used in butterworth method
beta=0.1102*(rs-8.8);   %used in Kaiser window to obtain sidelobe attenuation of rs dB
if strcmp(filter_type, 'GAUS') || strcmp(filter_type, 'MOVAVRG')
window = fix(Fs/fcut);      % window size used in Gaussian and moving average methods
end
wp=2*fcut/Fs;               % normalized passband corner frequency wp, the cutoff frequency
ws=a*wp;                    % normalized stopband corner frequency

switch filter_type
    case 'BUTTER'   %Butterworth IIR filter
        if length(wp)>1
        ws(1)=2*(fcut(1)/2)/Fs;
        ws(2)=2*(fcut(2)+fcut(1)/2)/Fs;
        [n,wn]=buttord(wp,ws,rp,rs);
        [b,a]=butter(n,wn,'bandpass');
        else
        [n,wn]=buttord(wp,ws,rp,rs);
        [b,a]=butter(n,wn,'low');
        end
        filtsignal=filter(b,a,signal);%conventional filtering
    case 'LPFIR'    %Lowpass FIR filter
        d=fdesign.lowpass('N,Fc',N,fcut,Fs); % Fc is the 6-dB down point, N is the filter order(N+1 filter coefficients)
        Hd = design(d);
        filtsignal=filter(Hd.Numerator,1,signal); %conventional filtering
    case 'FIRLS'    %Least square linear-phase FIR filter design
        b=firls(255,[0 2*fcut/Fs a*2*fcut/Fs 1],[1 1 0 0]);
        filtsignal=filter(b,1,signal); %conventional filtering
    case 'EQUIRIP'  %Eqiripple FIR filter
        d=fdesign.lowpass('Fp,Fst,Ap,Ast',wp,ws,rp,rs);
        Hd=design(d,'equiripple');
        filtsignal=filter(Hd.Numerator,1,signal); %conventional filtering
    case 'MOVAVRG'  % Moving average FIR filtering, Rectangular window
        h = ones(window,1)/window;
        b = fir1(window-1,wp,h);
        filtsignal = filter(b, 1, signal);
    case 'HAMMING'  % Hamming-window based FIR filtering
        b = fir1(150,wp);
        filtsignal = filter(b, 1, signal);        
        filtsignal = filter(h, 1, signal);
    case 'GAUS'     % Gaussian-window FIR filtering
        h = normpdf(1:window, 0, fix(window/2));
        b = fir1(window-1,wp,h);
        filtsignal = filter(b, 1, signal);
    case 'GAUS1'    % Gaussian-window FIR filtering
        b = fir1(window-1,wp,gausswin(window,2)/window);
        filtsignal = filter(b, 1, signal);
    case 'KAISER'   %Kaiser-window FIR filtering
        h=kaiser(window,beta);
        b = fir1(window-1,wp,h);
        filtsignal = filter(b, 1, signal);     
        
    otherwise
    sprintf('filter_type is wrong!! havaset kojast!!')
end

end



% MATLAB script for calibrating sound pressure level using Arduino and serial communication in real-time

% --- Configuration ---
arduinoPort = 'COM3';            % Replace with the actual COM port of your Arduino
baudRate = 115200;
speakerOutputValues = 0:10:100; % Example range of speaker output values
numRepetitions = 3;            % Number of times to repeat each measurement
tableTitle = 'Speaker Calibration Data'; % Title for the table

% --- Initialize Serial Communication with Arduino ---
try
    % Create serial port object
    arduinoSerial = serial(arduinoPort, 'BaudRate', baudRate);
    % Open the serial port
    fopen(arduinoSerial);
    % Set a timeout to prevent MATLAB from waiting indefinitely
    arduinoSerial.Timeout = 10; % in seconds
    % Read the "Arduino Ready" message
    arduinoReady = fgetl(arduinoSerial);
    if ~strcmp(arduinoReady, 'Arduino Ready')
        error('MATLAB:ArduinoNotReady', 'Arduino did not send the "Ready" signal. Check the Arduino code and connection.');
    end
    disp('Arduino connected and ready.');

    % --- Create Figure and Table ---
    fig = figure('Name', tableTitle, 'NumberTitle', 'off');
    % Create an empty table in the figure
    hTable = uitable(fig, 'Data', zeros(0, numRepetitions + 1), ...
        'ColumnName', [{'SpeakerValue'}, arrayfun(@(i) ['SPL_Rep' num2str(i)], 1:numRepetitions, 'UniformOutput', false)], ...
        'RowName', [], ...
        'Position', [20 20 400 300]); % Adjust position as needed

    % --- Preallocate Data Storage (for efficiency) ---
    numValues = length(speakerOutputValues);
    dataMatrix = zeros(numValues * numRepetitions, numRepetitions + 1); % +1 for speakerValue

    % --- Calibration Loop ---
    disp('Starting calibration...');
    for i = 1:numValues
        speakerValue = speakerOutputValues(i);
        disp(['Setting speaker output to: ' num2str(speakerValue)]);

        % Store the speaker value in the data matrix
        dataMatrix((i - 1) * numRepetitions + 1:i * numRepetitions, 1) = speakerValue;

        for j = 1:numRepetitions
            fprintf('  Repetition %d: ', j);
            % *** Replace this with your function to control the speaker in MATLAB ***
            setSpeakerLevel(speakerValue); % Call the speaker control function
            % ----------------------------------------------------------------------

            % Read the SPL value from Arduino
            try
                splString = fgetl(arduinoSerial);
                splValue = str2double(splString);
                if isnan(splValue)
                    error('MATLAB:InvalidSPLValue', 'Received non-numeric SPL value from Arduino.');
                end
                disp(['Received SPL: ' num2str(splValue) ' dB']);
                dataMatrix((i - 1) * numRepetitions + j, j + 1) = splValue; % Store in matrix

            catch ME
                % Handle errors, such as timeout or non-numeric data
                disp(['Error: ' ME.message]);
                if (strcmp(ME.identifier, 'MATLAB:serial:fread:timeout'))
                    disp('  Timeout occurred while waiting for data from Arduino.');
                elseif (strcmp(ME.identifier, 'MATLAB:InvalidSPLValue'))
                    disp('  Non-numeric data received from Arduino.');
                end
                % Consider adding a 'continue' here to proceed to the next repetition
                % even if one fails. Otherwise, the script will stop.
                continue; % Add this to continue to the next iteration
            end
            pause(0.5); % Short pause

            % --- Update the Table in the Figure ---
            % Create a temporary table and update the figure's table
            tempTable = array2table(dataMatrix(1:i * numRepetitions, :), 'VariableNames', [{'SpeakerValue'}, arrayfun(@(i) ['SPL_Rep' num2str(i)], 1:numRepetitions, 'UniformOutput', false)]);
            set(hTable, 'Data', tempTable);
            drawnow; % Force the figure to update
        end
    end

    % --- Close Serial Port ---
    fclose(arduinoSerial);
    delete(arduinoSerial);
    clear arduinoSerial;

    % --- Display Results in a Table ---
    calibrationTable = array2table(dataMatrix, 'VariableNames', [{'SpeakerValue'}, arrayfun(@(i) ['SPL_Rep' num2str(i)], 1:numRepetitions, 'UniformOutput', false)]);
    disp(tableTitle);
    disp(calibrationTable);

    % --- Optional: Plot Calibration Data ---
    figure; % Create a new figure for the plot
    plot(calibrationTable.SpeakerValue, calibrationTable{:, 2:end}, '-o'); % Plot all repetitions
    xlabel('Speaker Output Value');
    ylabel('SPL (dB)');
    title('Speaker Calibration Curve');
    legend([columnNames{2:end}]);
    grid on;

    % --- Optional: Polynomial Fit and Display Equation ---
    degree = 2; % You can change the degree of the polynomial
    p = polyfit(calibrationTable.SpeakerValue, mean(calibrationTable{:, 2:end}, 2), degree); % Fit to the *mean* SPL
    fittedSPL = polyval(p, calibrationTable.SpeakerValue);
    hold on;
    plot(calibrationTable.SpeakerValue, fittedSPL, 'r-', 'LineWidth', 2); % Plot the fit
    hold off;
    % Display the polynomial equation
    equationString = poly2str(p, 'x'); % Use a helper function (defined below)
    disp(['Polynomial fit equation: SPL = ' equationString]);

catch ME
    % Handle any errors that occur during the process
    disp(['An error occurred: ' ME.message]);
    % Clean up the serial port if it was opened
    if exist('arduinoSerial', 'var') && isvalid(arduinoSerial)
        fclose(arduinoSerial);
        delete(arduinoSerial);
        clear arduinoSerial;
    end
end

% --- Function to simulate setting the speaker level (REPLACE THIS) ---
function setSpeakerLevel(value)
    % Replace this with the actual commands or functions to control the speaker.
    % This is just a placeholder for your specific speaker control mechanism.
    disp(['(Simulating setting speaker level to: ' num2str(value), ')']);
    pause(1); % Simulate speaker level change
end

% --- Helper function to convert polynomial coefficients to a string ---
function equationString = poly2str(p, varName)
    % Converts a polynomial coefficient vector (as returned by polyfit)
    % to a string representation of the polynomial equation.
    %
    % Example:
    %   p = [1 2 3];  % Coefficients for 1x^2 + 2x + 3
    %   varName = 'x';
    %   equationString = poly2str(p, varName);  % Returns '1x^2 + 2x + 3'

    n = length(p);
    equationString = '';
    for i = 1:n
        coeff = p(i);
        if coeff ~= 0
            if ~isempty(equationString)
                equationString = [equationString, ' + ']; % Use '+' sign (except for the first term)
            end
            if coeff == 1 && i < n %suppress 1
                % equationString = [equationString, varName];
            elseif coeff ~= 1
                equationString = [equationString, num2str(coeff)];
            end

            if i < n
                equationString = [equationString, varName];
                if i < n - 1
                    equationString = [equationString, '^', num2str(n - i)];
                end
            elseif coeff ~= 0
                equationString = [equationString, num2str(coeff)];
            end
        end
    end
    % Replace "+ -" with "-"
    equationString = strrep(equationString, '+ -', '-');
end
