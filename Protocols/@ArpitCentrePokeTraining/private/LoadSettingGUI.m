% REMOVE THE SETTINGS/PRE OPENED GUI
try
    flush
catch
end

% START FRESH & SET THE REQUIRED DIRECTORY
getenv('USERPROFILE');
getenv('HOMEDRIVE');
getenv("SYSTEMROOT");

current_dir = cd;
ratter_dir = extractBefore(current_dir,'ratter');
ratter_modules_dir = fullfile(ratter_dir, 'ratter', 'ExperPort');
cd(ratter_modules_dir);

% START BPOD

% Identify the bpod port before starting
bpodPort = getOrSetCOMPort();
disp(['Using COM Port: ' bpodPort]);
bpod(bpodPort);
newstartup;

% PRESENT THE USER WITH THE CHOICE OF EXPERIMENTER/RAT

% Let's identify all the experimenter and their respective rats
try
    Experimenter_Name = bdata('select distinct experimenter from rats where extant=1 order by experimenter');
catch %#ok<CTCH>
    disp('ERROR: Unable to connect to MySQL Server');
    Experimenter_Name = '';
end

if ~isempty(Experimenter_Name)
    for n_exp = 1:numel(Experimenter_Name)
        ratnames = bdata(['select ratname from rats where experimenter="',Experimenter_Name{n_exp},'" and extant=1']);
        Rat_Name{n_exp} = sortrows(strtrim(ratnames));
    end
end

Exp_Rat_Map = containers.Map(Experimenter_Name, Rat_Name);

% Create figure
fig = figure('Name', 'Dynamic Button GUI', ...
    'Position', [500, 300, 600, 400], ...
    'MenuBar', 'none', ...
    'NumberTitle', 'off', ...
    'Color', [0.9 0.9 0.9]);

% Create main buttons with resize callback
buttonHandles = createButtons(fig, Experimenter_Name, @(src, ~) mainButtonCallback(src, Exp_Rat_Map, fig));

% Setup resize behavior
set(fig, 'ResizeFcn', @(src, ~) resizeButtons(src, buttonHandles));

% === Callback for first-level buttons ===
function mainButtonCallback(src, map, figHandle)
experimenter = src.String;
subOptions = map(experimenter);
clf(figHandle);  % Clear previous buttons

% Create new buttons and assign second-level callback
newButtons = createButtons(figHandle, subOptions, @(src2, ~) subButtonCallback(src2,experimenter,fig));

% Update resize function
set(figHandle, 'ResizeFcn', @(src, ~) resizeButtons(src, newButtons));
end

% === Final action when second-level button is clicked ===
function subButtonCallback(src,experimenter_name,figHandle)
rat_name = src.String;
close(figHandle);
runrats('init');
runrats('update exp_rat_userclick',experimenter_name,rat_name);
end

% === Create buttons dynamically and return handles ===
function btns = createButtons(figHandle, optionList, callbackFcn)
delete(findall(figHandle, 'Type', 'uicontrol'));  % Clear any existing buttons

n = numel(optionList);
btns = gobjects(1, n);

for i = 1:n
    btns(i) = uicontrol(figHandle, ...
        'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'String', optionList{i}, ...
        'FontSize', 14, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.7 0.8 1], ...
        'Callback', callbackFcn);
end

resizeButtons(figHandle, btns);  % Initial layout
end

% === Resize button layout responsively ===
function resizeButtons(figHandle, buttons)
n = numel(buttons);
spacing = 0.02;
totalSpacing = spacing * (n + 1);
btnHeight = (1 - totalSpacing) / n;
btnWidth = 0.8;
x = (1 - btnWidth) / 2;

for i = 1:n
    y = 1 - spacing - i * (btnHeight + spacing) + spacing;
    set(buttons(i), 'Position', [x, y, btnWidth, btnHeight]);
end
end


function comPort = getOrSetCOMPort()
configFile = fullfile(fileparts(mfilename('fullpath')), 'com_config.mat');
maxAttempts = 3;
success = false;

% Try existing config or prompt
if exist(configFile, 'file')
    data = load(configFile, 'comPort');
    comPort = data.comPort;
else
    comPort = promptForPort();
end

% Try to validate and possibly retry
for attempt = 1:maxAttempts
    try
        s = serialport(comPort, 9600);  % test connection
        clear s;  % close it immediately
        success = true;
        break;
    catch
        fprintf('[Warning] Failed to open %s. Please select a different COM port.\n', comPort);
        comPort = promptForPort();
    end
end

if ~success
    error('Failed to find a valid COM port after %d attempts.', maxAttempts);
end

% Save the working port
save(configFile, 'comPort');
end

function comPort = promptForPort()
availablePorts = serialportlist("available");

if isempty(availablePorts)
    warning('No serial ports detected. Enter manually.');
    comPort = input('Enter COM port manually (e.g., COM3): ', 's');
else
    fprintf('Available COM ports:\n');
    for i = 1:numel(availablePorts)
        fprintf('  %d: %s\n', i, availablePorts(i));
    end
    idx = input('Select COM port number: ');
    if isnumeric(idx) && idx >= 1 && idx <= numel(availablePorts)
        comPort = availablePorts(idx);
    else
        comPort = input('Enter COM port manually (e.g., COM3): ', 's');
    end
end
end

