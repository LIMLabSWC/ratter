function [varargout] = BonsaiCameraInterface(obj,action,varargin)

% If creating an empty object, return without further ado:
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty'))
   return;
end

GetSoloFunctionArgs(obj);

if isa(varargin{1}, mfilename) % If first arg is an object of this class itself, we are
   % Most likely responding to a callback from a SoloParamHandle defined in this mfile.
   if length(varargin) < 2 || ~ischar(varargin{2})
      error(['If called with a "%s" object as first arg, a second arg, a ' ...
         'string specifying the action, is required\n']);
   else 
       action = varargin{2}; varargin = varargin(3:end); %#ok<NASGU>
   end
else % Ok, regular call with first param being the action string.
   action = varargin{1}; varargin = varargin(2:end); %#ok<NASGU>
end

GetSoloFunctionArgs(obj);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% DO NOT CHANGE THEM UNLESS YOU MAKE THE SAME CHANGES IN BONSAI %%%%%%%%%

% UDP Connection Parameters to connect to Bonsai
bonsaiComputerIP = '127.0.0.1'; % IP address of the PC running Bonsai (use '127.0.0.1' if same PC)
bonsaiComputer_name = 'Receiver';
bonsaiUdpPort = 9090;         % Port configured in Bonsai's UdpReceiver
% Sending the Command to Turn on the Camera. Remember to use this
% as in Bonsai I am using the address as /camera and using
% condition to compare the arriving message. The message could only
% be 'start' or 'stop' with '/camera' address for bonsai to react
startCommand = "start";       % Use string type. MUST MATCH Bonsai Filter Value
stopCommand = "stop";         % Use string type. MUST MATCH Bonsai Filter Value
camera_command_address = "/camera"; % Use string type. MUST MATCH Bonsai Address Value
recording_command_address = "/record";  % Use string type. MUST MATCH Bonsai Address Value

% The location of Bonsai workflow in the system. In this case it is saved
% within the ratter > ExpertPort > Plugins > @bonsaicamera folder
scriptFullPath = mfilename('fullpath'); % Path of running the current script
scriptDirectory = fileparts(scriptFullPath);
bonsai_workflow_Path = fullfile(scriptDirectory,'Bonsai_Camera_Control','Camera_Control.bonsai');
foundworkflow = exist("bonsai_workflow_Path",'file');
if ~foundworkflow
    warning('could not find bonsai executable, please insert it manually');
    [bonsai_fname bonsai_fpath] = uigetfile( '*.exe', 'Provide the path to Bonsai executable');
    bonsai_workflow_Path = fullfile(bonsai_fpath, bonsai_fname);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Make the action case insensitive
action = lower(action);

switch action

    case 'init'

        if length(varargin) < 2
            error('Need at least two arguments, x and y position, to initialize %s', mfilename);
        end

        x = varargin{1};
        y = varargin{2};
        varargout{1} = x;
        varargout{2} = y;

        ToggleParam(obj, 'CameraControl', 1, x, y, 'OnString', 'Camera ON', ...
            'OffString', 'Camera OFF', 'TooltipString', 'Turn On/Off the streaming and Saving of Camera Feed');
        set_callback(CameraControl, {mfilename, 'camera_connection'}); %#ok<NODEF> (Defined just above)
        next_row(y);

        %% STEP 1: Start the Bonsai app to control the USB based Camera

        % Run the Bonsai App with the workflow
        
        % bonsai_path = bonsaiPath(32);
        % command = sprintf('"%s" "%s" --start', bonsai_path, bonsai_file_path);
        % system([command, ' &']);

        % Bonsai app and the workflow is being run by helper function
        
        runBonsaiWorkflow(bonsai_workflow_Path);        
        pause(5); % wait few seconds for software to open before continuing



        %% STEP 2: DECLARING AND FOLDER LOCATION FOR SAVING THE VIDEOS

        % The video files are saved in the folder format declared below
        % C:\RatterVideos\ExpName\RateName\Videos_Protocolname_ExpName_RatName_date
        % (the same format as Data file)

        current_dir = cd;
        ratter_dir = extractBefore(current_dir,'ratter');
        main_dir_video = [ratter_dir 'ratter_Videos'];
        date_str = regexprep(char(datetime('today','Format','yyyy-MM-dd')), '[^0-9]', '');
        video_foldername = sprintf('video_@%s_%s_%s_%s',name,expmtr,rname,date_str);
        rat_dir = sprintf('%s\\%s\\%s',main_dir_video,expmtr,rname);
        video_save_dir = sprintf('%s\\%s\\%s\\%s',main_dir_video,expmtr,rname,video_foldername);
        % We have the general structure of folder save location, now need to
        % check if there is any other folder for same date. We will add a
        % alphabet in the end based upon the no. of files present.
        if exist(rat_dir,'dir') == 7
            listing = dir(rat_dir);
            folderNames_rat_dir = {listing(find([listing.isdir])).name};
            folderNames_rat_dir = folderNames_rat_dir(~ismember(folderNames_rat_dir,{'.','..'})); % Remove the '.' and '..' entries (current and parent directories)
            sessions_today = length(find(contains(folderNames_rat_dir,video_foldername))); % number of folders containing the video foldername
            video_save_dir = [video_save_dir char(sessions_today + 97)];
        else
            video_save_dir = [video_save_dir char(97)];
        end
        mkdir(video_save_dir);
        SoloParamHandle(obj, 'Video_Saving_Folder', 'value', video_save_dir);
        
        % --- Create UDP Port Object ---
        % This object can send to any destination without prior connection
        udpSender = udpport("datagram","IPV4",'LocalHost',bonsaiComputerIP,...
            'LocalPort',9091,'Tag','MATLABSender');
 
        SoloParamHandle(obj, 'UDPSender', 'value', udpSender, 'saveable', 0);
        


        %% STEP 3: START STREAMING AND SAVING OF THE VIDEO
        
        BonsaiCameraInterface(obj,'camera_connection');


   

    %% Camera connection On/Off    
    case 'camera_connection'

        if CameraControl == 1 % User Selected to Reconnect & Restart the feed from the Camera 

            % Now that we have created the UPD connection, we can send commands
        % over OSC. 
        % Before starting the streaming of Camera, I need to send the
        % file directory for saving the file otherwise Bonsai can run into
        % error as it will try saving files in the predefined folder in
        % bonsai and that can conflict with file already present there.

            oscMsg_file_directory = createOSCMessage(recording_command_address, [value(Video_Saving_Folder) '\Trial.avi']);
            % write(udpSender, oscMsg_file_directory, "uint8", bonsaiComputerIP,bonsaiUdpPort);

            % OSC message to start the camera
            oscMsg_Camera_start = createOSCMessage(camera_command_address, startCommand);
            % the command to send message to Bonsai
            write(value(UDPSender), oscMsg_Camera_start, "uint8", bonsaiComputerIP,bonsaiUdpPort);

            pause(3);
            
            % NOTE: Ideally I should start saving the trials once the experimenter presses
            % Run either on dispatcher or Runrats. But, I dont want to make the changes there
            % so would start recording as soon as the protocol is loaded and camera starts streaming

            write(value(UDPSender), oscMsg_file_directory, "uint8", bonsaiComputerIP,bonsaiUdpPort);

        else % User Stopped the streaming and saving OF VIDEO

            % this stops saving and streaming of the camera
            oscMsg_Camera_stop = createOSCMessage("/camera", stopCommand);
            write(value(UDPSender), oscMsg_Camera_stop, "uint8", bonsaiComputerIP,bonsaiUdpPort);

        end

     
     %% next trial   
     %  SEND STRING TO BONSAI AT THE END OF THE TRIAL TO SAVE NEXT TRIAL IN
     %  NEW VIDEO FILE
     case 'next_trial'
        
        % in this I send a command to bonsai so that it creates a new file
        % for each trial

        oscMsg_file_directory = createOSCMessage(recording_command_address, [value(Video_Saving_Folder) '\Trial.avi']);
        write(value(UDPSender), oscMsg_file_directory, "uint8", bonsaiComputerIP,bonsaiUdpPort);
    
    %% close bonsai and command window
    case 'close'
            
        % this would stop the workflow
        oscMsg_Camera_stop = createOSCMessage("/camera", stopCommand);
        write(value(UDPSender), oscMsg_Camera_stop, "uint8", bonsaiComputerIP,bonsaiUdpPort);

        delete(value(UDPSender)); % delete the UDP Port

        % this is to kill the Bonsai app and cmd
        system('taskkill /F /IM Bonsai.exe');
        system('taskkill /F /IM cmd.exe');


end


%%%%%%%%%%%%%%% ADD 0N Functions %%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function oscPacket = createOSCMessage(address, arg)
    % Ensure address and arg are char (not string)
    if isstring(address)
        address = char(address);
    end
    if isstring(arg)
        arg = char(arg);
    end

    % Helper to pad with nulls to 4-byte alignment
    function bytes = padNulls(str)
        strBytes = uint8([str, 0]);  % null-terminated
        padding = mod(4 - mod(length(strBytes), 4), 4);
        bytes = [strBytes, zeros(1, padding, 'uint8')];
    end

    % Address (e.g., "/camera", "/record")
    addrBytes = padNulls(address);

    % Type Tag String (e.g., ",s" for a single string argument)
    typeTag = ',s';
    tagBytes = padNulls(typeTag);

    % Argument (e.g., "start")
    argBytes = padNulls(arg);

    % Combine all parts
    oscPacket = [addrBytes, tagBytes, argBytes];
end


function runBonsaiWorkflow(workflowPath, addOptArray, bonsaiExePath, external)

%% addOptArray = {'field', 'val', 'field2', 'val2'};
%% check the input
switch nargin
    case 1
        bonsaiExePath = bonsaiPath(32);
        addOptArray = '';
        addFlag = 0;
        external = 1;
    case 2
        bonsaiExePath = bonsaiPath(32);
        addFlag = 1;
        external = 1;
    case 3
        addFlag = 1;
        external = 1;
    case 4
        if isempty(bonsaiExePath)
            bonsaiExePath = bonsaiPath(32);
        end
        addFlag = 1;
        
    otherwise
        error('Too many variables');
end



%% write the command
optSuffix = '-p:';
startFlag = '--start';
noEditorFlag = '--noeditor'; %use this instead of startFlag to start Bonsai without showing the editor
cmdsep = ' ';
if external
command = [['"' bonsaiExePath '"'] cmdsep ['"' workflowPath '"'] cmdsep startFlag];
else
command = [['"' bonsaiExePath '"']  cmdsep ['"' workflowPath '"'] cmdsep noEditorFlag];
end
ii = 1;
commandAppend = '';
if addFlag
    while ii < size(addOptArray,2)
        commandAppend = [commandAppend cmdsep optSuffix addOptArray{ii} '="' num2str(addOptArray{ii+1}) '"' ];
        ii = ii+2;
    end
end

if external
    command = [command commandAppend ' &'];
else
    command = [command commandAppend];
end
%% run the command
[sysecho] = system(command);
end


%% parse the addOptArray
function out = parseAddOptArray(addOptArray)
addOpt = cell(length(addOptArray)/2,2);
for ii =  1:length(addOpt)
    addOpt{ii,1} = addOptArray{2*ii-1}; %gets the propriety
    addOpt{ii,2} = addOptArray{2*ii}; %gets the value
end
out = addOpt;
end


function pathout = bonsaiPath(x64x86)

%%version of bonsai
if nargin <1; x64x86 = 64; end
switch x64x86
    case {'64', 64, 'x64', 1, '64bit'}
        bonsaiEXE = 'Bonsai64.exe';
    case {32, '32', 'x86', 0, '32bit'}
        bonsaiEXE = 'Bonsai.exe';
end

dirs = {'appdata', 'localappdata', 'programfiles', 'programfiles(x86)','USERPROFILE'};
foundBonsai = 0;
dirIDX = 1;
while ~foundBonsai && (dirIDX <= length(dirs))
    pathout = fullfile(getenv(dirs{dirIDX}),'Bonsai', bonsaiEXE);  
    foundBonsai = exist(pathout, 'file');
    dirIDX = dirIDX +1;
end

if ~foundBonsai
    pathout = fullfile(getenv(dirs{5}),'Desktop',bonsaiEXE);
    foundBonsai = exist(pathout, 'file');
end

if ~foundBonsai
    warning('could not find bonsai executable, please insert it manually');
    [fname fpath] = uigetfile( '*.exe', 'Provide the path to Bonsai executable');
    pathout = fullfile(fpath, fname);
end

end


end