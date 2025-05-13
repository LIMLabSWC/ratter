% BControl Startup Script
% ======================
% This script initializes the BControl system, setting up paths, loading settings,
% and preparing the environment for behavioral experiments.
%
% Usage:
%   >> newstartup; dispatcher('init');    % Start Dispatcher-BControl
%   >> newstartup; runrats('init');       % Start RunRats GUI for techs
%
% Requirements:
% - Must be run from root BControl code directory
% - Requires critical files and directories to be present
% - First run creates Settings_Custom.conf from template
%
% Documentation: http://brodylab.princeton.edu/bcontrol
%
% Author: Carlos Brody
% Last modified: 2007.12.20

function [] = newstartup()
global BpodSystem
if isempty(BpodSystem)
    clear global BpodSystem
    error('Error: You must run Bpod() at the command line, before you can open B-control');
end

% ============================================================================
% Debug Configuration
% ============================================================================
% Set initial debug state - will be overridden by settings later
dbstop if error;
dbstop if caught error 'TIMERERROR:catcherror';  % For debugging dispatcher timer loop

% Ensure we're in the correct directory
try cd(bSettings('get','GENERAL','Main_Code_Directory'));
catch %#ok<CTCH>
end

% ============================================================================
% Core Settings File Definitions
% ============================================================================
% Note: These filenames must match those in Modules/Settings.m
% TODO: Consolidate these definitions to avoid duplication
FILENAME__SETTINGS_DIR              = 'Settings';
FILENAME__DEFAULT_SETTINGS          = [ FILENAME__SETTINGS_DIR filesep 'Settings_Default.conf' ];
FILENAME__CUSTOM_SETTINGS           = [ FILENAME__SETTINGS_DIR filesep 'Settings_Custom.conf'  ];
FILENAME__SETTINGS_TEMPLATE         = [ FILENAME__SETTINGS_DIR filesep 'Settings_Template.conf'];

% ============================================================================
% Directory Structure Validation
% ============================================================================
% Verify all required directories and files exist
% These are essential for BControl operation
cd(fullfile(BpodSystem.Path.BcontrolRootFolder, 'ExperPort'));
if ~exist([pwd filesep 'bin'],          'dir') || ...
   ~exist([pwd filesep 'HandleParam'],  'dir') || ...
   ~exist([pwd filesep 'Modules'],      'dir') || ...
   ~exist([pwd filesep 'Utility'],      'dir') || ...
   ~exist([pwd filesep 'Plugins'],      'dir') || ...
   ~exist([pwd filesep 'Settings'],     'dir') || ...
   ~exist([pwd filesep 'SoloUtility'],  'dir') || ...
   ~exist([pwd filesep FILENAME__DEFAULT_SETTINGS], 'file'),
    errID = 1;
    errmsg = ['BControl must be started from its root directory,' ...
        ' and the following directories and files must exist there:' ...
        sprintf('\n') 'bin, HandleParam, Modules, Utility,'...
        ' Plugins, Settings, SoloUtility, and ' FILENAME__DEFAULT_SETTINGS...
        '.' sprintf('\n') ...
        'If you are missing files, please use cvs to update your code' ...
        ' from our repository.'];
    HandleNewstartupError(errID, errmsg);
    return;
end;

% ============================================================================
% Path Configuration
% ============================================================================
% Add all necessary directories to MATLAB's path
% Organized by functionality:
% - Core system components
% - Analysis tools
% - Protocol support (now handled via settings)
% - Hardware interfaces
% - Utilities and plugins
addpath([pwd filesep 'bin']   ...
    ,   [pwd filesep 'HandleParam'] ...
    ,   [pwd filesep 'Analysis' filesep 'dual_disc'] ...
    ,   [pwd filesep 'Analysis' filesep 'duration_disc'] ...
    ,   [pwd filesep 'Analysis' filesep 'ProAnti'] ...
    ,   [pwd filesep 'Analysis' filesep 'NeuraLynx'] ...
    ,   [pwd filesep 'Analysis' filesep 'Video_Tracker'] ...
    ,   [pwd filesep 'Analysis' filesep 'SameDifferent'] ...
    ,   [pwd filesep 'Analysis'] ...
    ,   [pwd filesep 'soundtools'] ...
    ,   [pwd filesep 'Modules' filesep 'TCPClient'] ...
    ,   [pwd filesep 'Modules' filesep 'SoundTrigClient'] ...
    ,   [pwd filesep 'Modules'] ...
    ,   [pwd filesep 'Utility'] ...
    ,   [pwd filesep 'Utility' filesep 'Zut' ] ...
    ,   [pwd filesep 'Utility' filesep 'AutomatedEmails' ] ...
    ,   [pwd filesep 'Plugins'] ...
    ,   [pwd filesep 'SoloUtility'] ...
    ,   [pwd filesep 'MySQLUtility' filesep 'win64'] ...
    ,   [pwd filesep 'MySQLUtility'] ...
    ,   pwd ...
    );

% ============================================================================
% Settings Loading
% ============================================================================
% Load system settings in sequence:
% 1. Default settings (required)
% 2. Custom settings (created from template if needed)
% 3. Verify critical settings
[errID errmsg] = bSettings('load');
HandleNewstartupError(errID, errmsg);

% Add Protocols directory to path
[Protocols_Directory errID errmsg] = bSettings('get','GENERAL','Protocols_Directory');
fprintf('Protocols_Directory from settings: %s\n', Protocols_Directory);
fprintf('Current directory: %s\n', pwd);
% Only construct full path if Protocols_Directory is relative
if ~isempty(Protocols_Directory) && ~strcmp(Protocols_Directory(1), filesep) && ~strcmp(Protocols_Directory(2), ':')
    full_protocols_path = fullfile(pwd, Protocols_Directory);
    fprintf('Full path to Protocols (relative): %s\n', full_protocols_path);
else
    fprintf('Using absolute path: %s\n', Protocols_Directory);
end

if ~errID && ~isempty(Protocols_Directory) && exist(Protocols_Directory, 'dir')
    addpath(Protocols_Directory);
    fprintf('Added to path: %s\n', Protocols_Directory);
else
    fprintf('Could not add to path. Error: %s\n', errmsg);
end

% ============================================================================
% Protocol Directory Validation
% ============================================================================
% Verify the Protocols directory specified in settings exists
[Protocols_Directory errID errmsg] = bSettings('get','GENERAL','Protocols_Directory');
if errID || isempty(Protocols_Directory) || ~exist(Protocols_Directory, 'dir'),
    errID = 1;
    errmsg = ['Protocols directory not found at: ' Protocols_Directory];
    HandleNewstartupError(errID, errmsg);
    return;
end;

% ============================================================================
% First Run Handling
% ============================================================================
% If custom settings don't exist, this is first run:
% 1. Create Settings_Custom.conf from template
% 2. Display welcome message with documentation link
% 3. Guide user through initial setup
if ~exist(FILENAME__CUSTOM_SETTINGS,'file'),
    [errID errmsg] = BControl_First_Run(FILENAME__CUSTOM_SETTINGS, FILENAME__SETTINGS_TEMPLATE);
    HandleNewstartupError(errID, errmsg);
end;

% ============================================================================
% Settings Verification
% ============================================================================
% Validate critical system settings:
% - Directory paths
% - Rig configuration
% - Server addresses
% - Hardware settings
[errID errmsg] = Verify_Settings();
HandleNewstartupError(errID, errmsg);

% ============================================================================
% Backward Compatibility
% ============================================================================
% Load settings into global variables for legacy code
% Note: This is a compatibility layer that should eventually be phased out
skip_globals = bSettings('compare','COMPATIBILITY', ...
    'Skip_Loading_Old_Settings_Into_Globals', true);
if ~skip_globals,
    [errID errmsg] = Compatibility_Globals();
    HandleNewstartupError(errID, errmsg);
end;

% ============================================================================
% RTLSM Version Handling
% ============================================================================
% Configure path based on RTLSM version:
% - Old RTLSM: Modules/NetClient
% - New RTLSM2: Modules/newrt_mods/NetClient
% Version determined by fake_rp_box setting (20 = RTLSM2)
if bSettings('compare','RIGS','fake_rp_box',20),
    addpath([pwd filesep 'Modules' filesep 'newrt_mods' filesep 'NetClient']);
else
    addpath([pwd filesep 'Modules' filesep 'NetClient']);
end;

% ============================================================================
% Debug Configuration
% ============================================================================
% Configure MATLAB's debugger based on settings:
% - Clear temporary error breakpoint
% - Set new breakpoint based on settings
% - Options: 'never', 'error', or custom condition
dbclear if error;
[dbstop_setting errID] = bSettings('get','GENERAL','dbstop_if');
if errID,
    dbstop if error;  % Default to breaking on errors
elseif strcmpi(dbstop_setting,'never') || strcmpi(dbstop_setting,'NULL') || isempty(dbstop_setting),
    % No breakpoints if explicitly disabled
else
    eval(['dbstop if ' dbstop_setting]);  % Set custom breakpoint
end;

% ============================================================================
% Graphics Configuration
% ============================================================================
% Set default figure renderer for compatibility
% OpenGL can be buggy, so we use painters
set(0, 'DefaultFigureRenderer', 'painters');

end  % end function newstartup

% ============================================================================
% Helper Functions
% ============================================================================

% HandleNewstartupError (helper function for newstartup)
% -------------------------------------------------------------
function [] = HandleNewstartupError(errID, errmsg)
if errID,
    errordlg(errmsg);
    error(errmsg);
end;
return;
end

% BControl_First_Run (helper function for newstartup)
% -------------------------------------------------------------
% Handles first-time system initialization
%     
% Responsibilities:
% 1. Creates custom settings file from template
% 2. Displays welcome message with documentation link
% 3. Guides user through initial setup
%
% Future Improvements:
% - Add settings selection dialogs for:
%   * Rig type configuration
%   * CVS settings
%   * Protocol defaults
%
% Inputs:
%   FILENAME__CUSTOM_SETTINGS - Target path for custom settings
%   FILENAME__SETTINGS_TEMPLATE - Source template file
%
% Returns:
%   errID - 0 if successful, 1 for file errors, -1 for logical errors
%   errmsg - Empty if successful, error description otherwise
function [errID, errmsg] = BControl_First_Run(FILENAME__CUSTOM_SETTINGS, FILENAME__SETTINGS_TEMPLATE)
errID = -1; errmsg = ''; %#ok<NASGU> (errID=-1 OK despite unused)
errorlocation = 'ERROR in BControl_First_Run.m';

% Generate an error iff* we have n args where n~=2.
error(nargchk(2, 2, nargin, 'struct'));

% Newline character for convenience.
nl = sprintf('\n');

Welcome_String = ['Welcome to BControl!' nl ...
    'Help can be found at "http://brodylab.princeton.edu/bcontrol"'];

if ~exist(FILENAME__CUSTOM_SETTINGS,'file'),
    if ~exist(FILENAME__SETTINGS_TEMPLATE,'file'),
        errID = 1;
        errmsg = [errorlocation ': Could not find settings template file at "' FILENAME__SETTINGS_TEMPLATE '".'];
        return;
    else
        [copysuccess,copymessage] = copyfile(FILENAME__SETTINGS_TEMPLATE,FILENAME__CUSTOM_SETTINGS,'f');
        if ~copysuccess,
            errID = 1;
            errmsg = [errorlocation ': Copying template settings file to custom settings file failed. Copy error message:  ' copymessage];
            return;
        else
            Welcome_String = [Welcome_String nl ...
                'A custom settings file has been created for you at "' ...
                FILENAME__CUSTOM_SETTINGS '".' nl ...
                'See instructions there and edit as desired.'];
        end;
    end;
end;

errID = 0;
msgbox(Welcome_String, 'First Run? - WELCOME TO BCONTROL!', 'help');
return;
end

% Verify_Settings (helper function for newstartup)
% -------------------------------------------------------------
% Validates critical system settings and directories
% Checks:
% 1. Main code directory matches current directory
% 2. Main data directory exists (creates if missing)
% 3. Valid fake_rp_box setting (0-4, 20, or 30)
% 4. Valid state/sound machine server addresses
% 5. Required DIO line configurations
%
% Future Improvements Needed:
% - Validate all DIOLines are properly specified
% - Ensure fake_rp_box values are reasonable for the setup
% - Verify DIOLINES are numeric and unique powers of two (except 0/NaN)
%
% Returns error if any critical setting is invalid
function [errID errmsg] = Verify_Settings()
errID = -1; errmsg = ''; %#ok<NASGU> (errID=-1 OK despite unused)
errorlocation = 'ERROR in Verify_Settings';

% Newline character for convenience.
nl = sprintf('\n');

% Be sure that we're running from the indicated code directory.
[Main_Code_Directory errID errmsg] = bSettings('get','GENERAL','Main_Code_Directory');
if errID, return; end;
if isempty(Main_Code_Directory) || strcmpi(Main_Code_Directory,'NULL'),
    warning(['\nWARNING in Verify_Settings: Main_Code_Directory' ...
        ' setting was left blank.\n' ...
        'Though BControl may not break, it is best to set this value\n' ...
        'to avoid unusual behavior.\n'...
        'Old code will see Solo_rootdir = %s'],pwd);
elseif ispc &&  ~strcmpi(Main_Code_Directory, pwd) ...
      || isunix && ~strcmp(Main_Code_Directory, pwd),
    warning(['\n\nWARNING in Verify_Settings: Main_Code_Directory specified\n'...
        'in settings files is not the current directory.\n' ...
        'Please set Main_Code_Directory in the custom settings file\n'...
        'file to match the directory you will run BControl from.\n'...
        'Strange behavior in old code MAY result.\n'...
        '(This warning may also occur due to OS case insensitivity\n'...
        'or softlinks.)\n' ...
        'This run:\nMain_Code_Directory:  %s\nCurrent Directory:  %s\n\n'],...
        Main_Code_Directory, pwd);
end

% See if the main data directory is specified.
[Main_Data_Directory errID errmsg] = bSettings('get','GENERAL','Main_Data_Directory');
if errID, return; end;
if isempty(Main_Data_Directory) || strcmpi(Main_Data_Directory, 'NULL'),
    warning(['\n\nWARNING in Verify_Settings: Main_Data_Directory not \n'...
        'specified in the custom settings file\n'...
        '(Settings/Settings_Custom.conf)\n' ...
        'This value is heavily used and the behavior of code that\n'...
        'uses it is not well defined when it is empty or "NULL".\n'...
        'Old code will see Solo_datadir = %s\n\n'], ...
        [pwd filesep '..' filesep 'SoloData']);
end;

% Create data directory at specified location if necessary.
if ~isempty(Main_Data_Directory) && ~strcmp(Main_Data_Directory,'NULL'),
    if ~exist(Main_Data_Directory, 'dir'),
        [success message] = mkdir(Main_Data_Directory);
        if ~success,
            errID = 1000;
            errmsg = [errorlocation ': Directory specified in' ...
                ' Main_Data_Directory setting did not exist in' ...
                ' filesystem and an attempt to create it failed.' ...
                ' Check permissions?' ...
                nl 'Directory: "' Main_Data_Directory '".' ...
                nl 'mkdir error message: ' nl '"' message '"'];
            return;
        end;
    end;
end;

% Check for meaningful fake_rp_box (0-4 or 20, 30).
[fake_rp_box errID errmsg] = bSettings('get','RIGS','fake_rp_box');
if errID, return; end;
if ~ismember(fake_rp_box, [0 1 2 3 4 20 30]),
    warn = [nl nl 'WARNING in Verify_Settings:' nl 'The setting' ...
        ' RIGS;fake_rp_box is not an integer in the set [0 1 2 3 4].' nl...
        'It is expected to be. See documentation in settings files.' nl];
    warning(warn);
end;

% Check selected addresses of state and sound machine servers.
[steMS errID errmsg] = bSettings('get','RIGS','state_machine_server');
if errID, return; end;
[sndMS errID errmsg] = bSettings('get','RIGS','sound_machine_server');
if errID, return; end;
if ~ischar(steMS) || ~ischar(sndMS) ...
        || (ismember(fake_rp_box,[0 1 2 20]) && (isempty(steMS) || isempty(sndMS))),
    warn = [nl nl 'WARNING in Verify_Settings:' nl ...
        'The settings RIGS;state_machine_server and' nl...
        'RIGS;sound_machine_server specify the address(es) of the' nl...
        'controlling (e.g. RTLSM) machine that sound and state' nl...
        'matrix information should be sent to. If a software' nl...
        'virtual behavior box is in use, they may be blank;' nl...
        'otherwise, they should be IP or DNS addresses - e.g.' nl...
        'rtlsm43.princeton.edu and 192.1.1.1 are fine.' nl nl];
    warning(warn);
    return;
end;

% If we've reached this point, everything should be okay.
errID = 0;
return;
end

% Compatibility_Globals (helper function for newstartup)
% -------------------------------------------------------------
% Maintains backward compatibility with older code
% Loads settings into global variables for legacy code that expects them
%
% Global Variables Created:
% - Rig Configuration:
%   * fake_rp_box - Rig type identifier
%   * state_machine_server - RTLSM server address
%   * sound_machine_server - Sound server address
%
% - Hardware Settings:
%   * DIO line configurations
%   * Sound settings (sample rate, etc.)
%   * Pump timing (on/off times)
%
% - System Paths:
%   * Solo_rootdir - Main code directory
%   * Solo_datadir - Data storage directory
%
% - Protocol Settings:
%   * Super_Protocols - List of protocol objects
%
% Note: This is a compatibility layer and should be phased out
% in favor of using the settings system directly. However, many
% existing protocols still depend on these globals.
%
% Returns: [errID errmsg]
%   errID: 0 if OK, else see errmsg
%   errmsg: '' if OK, else an informative error message
function [errID errmsg] = Compatibility_Globals()
errID = -1; errmsg = ''; %#ok<NASGU> (errID=-1 OK despite unused)
errorlocation = 'ERROR in Compatibility_Globals (newstartup helper function)';

global fake_rp_box;
[fake_rp_box errID errmsg] = bSettings('get','RIGS','fake_rp_box');
if errID, return; end;

global state_machine_server;
[state_machine_server errID errmsg] = bSettings('get','RIGS','state_machine_server');
if errID, return; end;

global sound_machine_server;
[sound_machine_server errID errmsg] = bSettings('get','RIGS','sound_machine_server');
if errID, return; end;

global cvsroot_string;
[cvsroot_string errID errmsg] = bSettings('get','CVS','CVSROOT_STRING');
if errID, return; end;

% Grab the DIO line names and values from Settings and create globals
[outputs errID_i errmsg_i] = bSettings('get','DIOLINES','all');
if errID_i,
    errID = 1;
    errmsg = [errorlocation ': Attempt to retrieve DIOLINES settings group failed. bSettings(''get'',''DIOLINES'',''all'') returned the following error (ID: ' int2str(errID_i) '): ' errmsg_i ];
    return;
end;

% Iterate over the DIOLINES settings and create globals
for i = 1:size(outputs,1),
    chan_name = outputs{i,1};
    chan_val  = outputs{i,2};
    eval(['global ' chan_name ';']);
    eval([chan_name ' = ' num2str(chan_val) ';']);
end;

global softsound_play_sounds;
softsound_play_sounds = bSettings('get','EMULATOR','softsound_play_sounds');

global pump_ontime;
[pump_ontime errID errmsg] = bSettings('get','PUMPS','pump_ontime');
if errID, return; end;

global pump_offtime;
[pump_offtime errID errmsg] = bSettings('get','PUMPS','pump_offtime');
if errID, return; end;

global sound_sample_rate;
[sound_sample_rate errID errmsg] = bSettings('get','SOUND','sound_sample_rate');
if errID, return; end;

global Solo_Try_Catch_Flag;
[Solo_Try_Catch_Flag errID] = bSettings('get','GENERAL','Solo_Try_Catch_Flag');
if errID || ~isnumeric(Solo_Try_Catch_Flag) || ...
        (Solo_Try_Catch_Flag ~= 0 && Solo_Try_Catch_Flag ~= 1),
    Solo_Try_Catch_Flag = 1;
end;

global Solo_rootdir;
Solo_rootdir = pwd;

global Solo_datadir;
[Solo_datadir errID errmsg] = bSettings('get','GENERAL','Main_Data_Directory');
if errID, return; end;
if isempty(Solo_datadir) || strcmpi(Solo_datadir, 'NULL'),
    Solo_datadir = [Solo_rootdir filesep '..' filesep 'SoloData'];
end;

% Names of protocols built using protocolobj
global Super_Protocols;
Super_Protocols = {'duration_discobj','dual_discobj'};

% If we've reached this point, everything should be okay.
errID = 0;
return;
end
