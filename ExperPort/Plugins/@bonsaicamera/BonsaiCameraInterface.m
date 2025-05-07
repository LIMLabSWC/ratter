%% BonsaiCameraInterface - MATLAB class interface to control USB camera via Bonsai using OSC messages.
%
% This class enables communication between MATLAB and a Bonsai workflow for controlling a USB-based camera.
% It uses Open Sound Control (OSC) messages transmitted over UDP to start and stop the camera feed, as well
% as to specify the location where video recordings should be saved.
%
% Dependencies:
% - Camera_Control.bonsai: Bonsai workflow file (must be saved in the same folder as this class file)
% - private/createOSCMessage.m: Helper function to format OSC messages
% - private/runBonsaiWorkflow.m: Helper function to launch Bonsai with a specific workflow
%
% Initialization ('init' action):
% Initialization ('init' action):
% - Requires exactly five input arguments in the following order:
%   1. x-position of the camera control toggle button (UI element in Solo GUI)
%   2. y-position of the camera control toggle button
%   3. Protocol name
%   4. Experimenter name
%   5. Rat name
% - If any of these are missing or fewer than five arguments are provided, the initialization will result in an error.

% - Launches the Bonsai workflow using runBonsaiWorkflow.m This function is used to start a Bonsai workflow (.bonsai file) from within MATLAB.
% It builds and executes a command to launch the Bonsai executable with the selected workflow,
% allowing automated and optionally parameterized workflow startup.

% - Sets up a UDP sender object to communicate via OSC.

% - Automatically creates a structured directory for saving video files in the format:
%   C:\ratter_Videos\<Experimenter>\<Rat>\video_@<Protocol>_<Experimenter>_<Rat>_<Date>[a-z]
%   A suffix is appended if there are multiple sessions on the same date.

% - Sends initial OSC messages to set the video save path and begin streaming.
%
% Switch-case structure:
%
% 'init'           : Initializes UI toggle, starts Bonsai workflow, sets up save directory and UDP sender.
% 'camera_connection' : Sends OSC messages to start or stop the camera feed. Also sends the video path to Bonsai.
% 'next_trial'     : Sends a new video save path to Bonsai to separate trial recordings.
% 'close'          : Stops the camera, deletes the UDP sender object, and terminates Bonsai and CMD processes.
%
% Notes:
% - Uses IP 127.0.0.1 and port 9090 for sending OSC messages to Bonsai.
% - Messages use the OSC addresses "/camera" and "/record" with "start"/"stop" commands.

function [varargout] = BonsaiCameraInterface(obj,action,varargin)

% If creating an empty object, return without further ado:
if nargin==0 || (nargin==1 && ischar(varargin{1}) && strcmp(varargin{1}, 'empty'))
   return;
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
bonsai_workflow_Path = fullfile(scriptDirectory,'Camera_Control.bonsai');
foundworkflow = isfile(bonsai_workflow_Path);
if ~foundworkflow
    warning('could not find bonsai executable, please insert it manually');
    [bonsai_fname, bonsai_fpath] = uigetfile( '*.bonsai', 'Provide the path to Bonsai executable');
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

        switch length(varargin)
            case 2
                protocol_name = 'protocol_name';
                experimenter_name = 'experimenter';
                rat_name = 'ratname';
            case 3
                protocol_name = varargin{3};
                experimenter_name = 'experimenter';
                rat_name = 'ratname';
            case 4
                protocol_name = varargin{3};
                experimenter_name = varargin{4};
                rat_name = 'ratname';
            case 5
                protocol_name = varargin{3};
                experimenter_name = varargin{4};
                rat_name = varargin{5};
        end

        current_dir = cd;
        ratter_dir = extractBefore(current_dir,'ratter');
        main_dir_video = [ratter_dir 'ratter_Videos'];
        date_str = regexprep(char(datetime('today','Format','yyyy-MM-dd')), '[^0-9]', '');
        video_foldername = sprintf('video_@%s_%s_%s_%s',protocol_name,experimenter_name,rat_name,date_str);
        rat_dir = sprintf('%s\\%s\\%s',main_dir_video,experimenter_name,rat_name);
        video_save_dir = sprintf('%s\\%s\\%s\\%s',main_dir_video,experimenter_name,rat_name,video_foldername);
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

return
