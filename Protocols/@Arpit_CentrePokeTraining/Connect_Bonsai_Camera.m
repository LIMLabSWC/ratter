function Connect_Bonsai_Camera(obj,action)

GetSoloFunctionArgs(obj);


% C:\RatterVideos\ExpName\RateName\Videos_Protocolname_ExpName_RatName_date
% (the same format as Data file)

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
bonsai_path = 'C:\Users\Turin\Downloads\Bonsai\Bonsai.exe'; % Path of Bonsai App
file_path = 'C:\Users\Turin\Desktop\bonsai_script.bonsai';  % Path for .bonsai file 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch action

    case 'init'

        % --- Create UDP Port Object ---
        % This object can send to any destination without prior connection
        udpSender = udpport("datagram","IPV4",'LocalHost',bonsaiComputerIP,...
            'LocalPort',9091,'Tag','MATLABSender');
 
        SoloParamHandle(obj, 'UDPSender', 'value', udpSender);

        % Now that we have created the UPD connection, we can send commands
        % over OSC. Before that we need to open the Bonsai App

        command = sprintf('"%s" "%s" --start', bonsai_path, file_path);
        system([command, ' &']);

        % Before starting the streaming of Camera, I need to send the
        % file directory for saving the file otherwise Bonsai can run into
        % error as it will try saving files in the predefined folder in
        % bonsai and that can conflict with file already present there.

        oscMsg_file_directory = createOSCMessage(recording_command_address, [value(Video_Saving_Folder) '\Trial.avi']);
        write(udpSender, oscMsg_file_directory, "uint8", bonsaiComputerIP,bonsaiUdpPort);

       % OSC message to start the camera
        oscMsg_Camera_start = createOSCMessage(camera_command_address, startCommand);
        % the command to send message to Bonsai
        write(udpSender, oscMsg_Camera_start, "uint8", bonsaiComputerIP,bonsaiUdpPort);

        % NOTE: Ideally I should start saving the trials once the experimenter presses 
        % Run either on dispatcher or Runrats. But, I dont want to make the changes there
        % so would start recording as soon as the protocol is loaded and camera starts streaming 

    case 'next_trial'
        
        % in this I send a command to bonsai so that it creates a new file
        % for each trial

        filename = sprintf('%s//%s//%s',work_dir,exp_name,rat_name);
        oscMsg_filename = createOSCMessage(recording_command_address, filename);
        write(value(udpSender), oscMsg_filename, "uint8", bonsaiComputerIP,bonsaiUdpPort);

    case 'close'
            
        % this would stop the workflow
        oscMsg_Camera_stop = createOSCMessage("/camera", stopCommand);
        write(value(udpSender), oscMsg_Camera_stop, "uint8", bonsaiComputerIP,bonsaiUdpPort);

        % this is to kill the Bonsai app
        system('taskkill /F /IM Bonsai.exe');


end

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
        bonsaiExePath = bonsaiPath(64);
        addOptArray = '';
        addFlag = 0;
        external = 1;
    case 2
        bonsaiExePath = bonsaiPath(64);
        addFlag = 1;
        external = 1;
    case 3
        addFlag = 1;
        external = 1;
    case 4
        if isempty(bonsaiExePath)
            bonsaiExePath = bonsaiPath(64);
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

dirs = {'appdata', 'localappdata', 'programfiles', 'programfiles(x86)',...
    'C:\Software\Bonsai.Packages\Externals\Bonsai\Bonsai.Editor\bin\x86\Release',...
    'C:\Software\Bonsai.Packages\Externals\Bonsai\Bonsai.Editor\bin\x64\Release'...
    };
foundBonsai = 0;
dirIDX = 1;
while ~foundBonsai && (dirIDX <= length(dirs))
    pathout = fullfile(getenv(dirs{dirIDX}),'Bonsai', bonsaiEXE);    
    foundBonsai = exist(pathout, 'file');
    dirIDX = dirIDX +1;
end

if ~foundBonsai
    warning('could not find bonsai executable, please insert it manually');
    [fname fpath] = uigetfile( '*.exe', 'Provide the path to Bonsai executable');
    pathout = fullfile(fpath, fname);
end

end
