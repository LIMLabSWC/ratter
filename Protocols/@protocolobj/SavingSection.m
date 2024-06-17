% [x, y] = SavingSection(obj, action, x, y)
%
% Section that takes care of saving/loading, etc.
%
% PARAMETERS:
% -----------
%
% obj      Default object argument.
%
% action   One of:
%            'init'      To initialise the section and set up the GUI
%                        for it
%
%            'reinit'    Delete all of this section's GUIs and data,
%                        and reinit, at the same position on the same
%                        figure as the original section GUI was placed.
%
%            'savesets'  Save GUI settings to a file
%
%            'loadsets'  Load GUI settings to a file
%
%            'savedata'  Save all SoloParamHandles to a file
%
%            'loaddata'  Load all SoloParamHandles from a file
%
%       <~>  'saveboth'  Save GUI settings to a 'settings' file and all
%                          SoloParamHandles to a 'data' file, both without
%                          an interactive prompt. (One-click save all.)
%
% x, y     Only relevant to action = 'init'; they indicate the initial
%          position to place the GUI at, in the current figure window
%
% RETURNS:
% --------
%
% [x, y]   When action == 'init', returns x and y, pixel positions on
%          the current figure, updated after placing of this section's GUI.
%

function [x, y, Notes, ratname,experimenter] = SavingSection(obj, action, x, y,mykid)

GetSoloFunctionArgs;

switch action
    case 'init',      % ------------ CASE INIT --------------------
        % Save the figure and the position in the figure where we are
        % going to start adding GUI elements:
        SoloParamHandle(obj, 'my_gui_info', 'value', [x y gcf]);

        SoloParamHandle(obj, 'asv_trials', 'value', 10);

        SoloParamHandle(obj, 'mychild', 'value', value(mykid));
        if isempty(mychild)
            error('Invalid child object; pass the object of the child class that constructed this protocolobj instance');
        end;

        mychild = value(mychild);
        c = ['@' class(mychild)];

        % <~> added for experimenter
        EditParam(obj, 'experimenter', '', x, y, ...
            'label', 'Experimenter Name', ...
            'TooltipString','This is used to specify the directory the rat data will live in,\ne.g. /ratter/SoloData/Data/experimenternamehere/ratnamehere.\nIf this is blank, dir is e.g. /ratter/SoloData/Data/ratnamehere\n<~>');
        next_row(y, 1.5);
        % <~> end added for experimenter

        try 
            tmpratname = ratname_getter(obj);
        catch
            tmpratname = 'ratname';
        end;
        
        if isempty(tmpratname), tmpratname ='ratname';end;

        
        EditParam(obj, 'ratname', tmpratname, x, y,'label','Rat'); next_row(y, 2);
        g = get_ghandle(ratname);
        possie = get(g, 'Position');
        set(g, 'FontSize',12, 'FontWeight','bold', 'Position', [possie(1) possie(2) possie(3) possie(4)*1.5]);
        TextBoxParam(obj,'Notes', '', x, y,  ...
            'nlines', 3, 'labelfraction', 0.2,'param_owner', ['@' class(value(mychild))],...
            'param_funcowner', class(value(mychild)));
        next_row(y,4);

        %         % <~> added feature to save both data & settings without dialog window
        %         PushButtonParam(obj, 'saveboth', x, y, ...
        %             'label', 'Quickly Save Data & Settings', ...
        %             'TooltipString', 'Click to SAVE and COMMIT both data and settings to the default names&places.\n<~>');
        %         set_callback(saveboth, {'SessionDefinition', 'eod_save'});
        %         next_row(y, 1.5);
        % <~> end added feature

        PushButtonParam(obj, 'loadsets', x, y, 'label', 'Load Settings');
        set_callback(loadsets, {mfilename, 'loadsets'});
        next_row(y);
        PushButtonParam(obj, 'savesets', x, y, 'label', 'Save Settings');
        set_callback(savesets, {mfilename, 'savesets'});
        next_row(y, 1.5);

        PushButtonParam(obj, 'loaddata', x, y, 'label', 'Load Data');
        set_callback(loaddata, {mfilename, 'loaddata'});
        next_row(y);
        PushButtonParam(obj, 'savedata', x, y, 'label', 'Save Data');
        set_callback(savedata, {mfilename, 'savedata'});
        next_row(y, 1.5);

        SubheaderParam(obj, 'sectiontitle', 'Saving/Loading', x, y);

        SoloParamHandle(obj, 'SaveTime');
        SoloParamHandle(obj, 'hostname', 'value', get_hostname);

        SoloParamHandle(obj, 'n_autosave_calls', 'value', 0);    % How many 'autosave_data' calls have been done since init
        SoloParamHandle(obj, 'autosave_frequency', 'value', 20); % Every autosave_frequency 'autosave_data' calls, save the data with _ASV.mat suffix, no commit, not interactive


        % <~> added experimenter below (giving LoadSettings and LoadData
        %       read-only access to it so that directories and filenames can
        %       be correctly determined for loading files using new standard.
        % <~> also changed calls from SoloFunction to SoloFunctionAddVars,
        %       which is the new name for the same function
        SoloFunctionAddVars('LoadSettings', ...
            'ro_args', {'ratname', 'mychild', 'experimenter'});
        SoloFunctionAddVars('LoadData', ...
            'ro_args', {'ratname', 'mychild', 'experimenter'});

        return;

    case 'savesets',       % ------------ CASE SAVESETS --------------------
        if nargin < 3, x = 1; end;
        SaveTime.value = datestr(now);
        comm = get_sphandle('owner', ['@' class(value(mychild))], 'name','Notes'); comm = comm{1};
        comm.value_callback = ''; % remove any comments when saving settings for the next day
        if x==1,
            save_solouiparamvalues(value(ratname), ...
                'commit', 1, ... % <~> commit by default when on experimental rigs
                'interactive', 1, ...
                'child_protocol', mychild, ...
                'experimenter', value(experimenter)); % <~> new
        else
            save_solouiparamvalues(value(ratname), 'commit', 1,'interactive', 0,'child_protocol',mychild, ...
                'experimenter', value(experimenter));
        end;
        return;

    case 'loadsets',       % ------------ CASE LOADSETS --------------------
        %rpbox('runstart_disable');
        %load_solouiparamvalues(value(ratname));
        %rpbox('runstart_enable');

        LoadSettings(obj);

        return;


    case 'savedata',       % ------------ CASE SAVEDATA --------------------
        SaveTime.value = datestr(now);

        save_soloparamvalues(value(ratname), ...
            'commit', 1, ...
            'child_protocol', mychild, ...
            'eod_eval', 1, ...
            'confirm_eod_eval',0, ...
            'experimenter', value(experimenter)); % <~> new
        return;

    case 'save_asv',     % -------------- CASE SAVE_ASV -------------------
        fprintf(1,'Saving asv...\n');
        save_soloparamvalues(value(ratname),...
            'commit', 0,...
            'child_protocol', mychild, ...
            'eod_eval', 0, ...
            'confirm_eod_eval', 0 ,...
            'asv', 1, ...
            'experimenter', value(experimenter));

        return;
    case 'loaddata',       % ------------ CASE LOADDATA --------------------
        % load_soloparamvalues(value(ratname));
        LoadData(obj);
        return;


    case 'autosave_data',  % ------------ CASE AUTOSAVE_DATA --------------------
        n_autosave_calls.value = n_autosave_calls + 1;
        if rem(n_autosave_calls(1), autosave_frequency(1)) == 0,
            SavingSection(obj, 'save_asv');
        end;

    case 'set_autosave_frequency',  % ------------ CASE SET_AUTOSAVE_FREQUENCY --------------------
        if nargin < 3,
            warning('%s : %s : need an extra argument, \na scalar positive integer\nautosave_frequency not changed.', mfilename, action);
            return;
        end;
        arg = x;
        if isscalar(arg) && isnumeric(arg) && arg>=1,
            autosave_frequency.value = ceil(arg);
            return;
        end;

        warning('%s : %s : argument must be numeric,\na scalar positive integer\nautosave_frequency not changed.', mfilename, action);


    case 'get_autosave_frequency',  % ------------ CASE GET_AUTOSAVE_FREQUENCY --------------------
        x = value(autosave_frequency);

        % <~> added this case to handle quicksave of data & settings
    case 'saveboth',       % ------------ CASE SAVEBOTH --------------------
        % <~> assume that we are not saving settings for the next day,
        %       so do not strip comments

        SaveTime.value = datestr(now);
        save_soloparamvalues(value(ratname), ...
            'commit', 1, ...
            'child_protocol', mychild, ...
            'eod_eval', 1, ...
            'confirm_eod_eval', 0, ...
            'interactive', 0, ...
            'experimenter', value(experimenter));

        save_solouiparamvalues(value(ratname), ...
            'commit', 1, ...
            'interactive', 0, ...
            'child_protocol', mychild, ...
            'experimenter', value(experimenter));
        return;
        % <~> end added this case


    case 'reinit',       % ------------ CASE REINIT --------------------
        currfig = gcf;

        % Get the original GUI position and figure:
        x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));

        % Delete all SoloParamHandles who belong to this object and whose
        % fullname starts with the name of this mfile:
        delete_sphandle('owner', ['^@' class(obj) '$'], ...
            'fullname', ['^' mfilename]);

        % Reinitialise at the original GUI position and figure:
        [x, y] = feval(mfilename, obj, 'init', x, y);

        % Restore the current figure:
        figure(currfig);

    case 'autosave'
        if nargin < 3, error('Sorry, need to know n_done_trials when checking for autosave');end;
        done_trials = value(x);  % misnomer: really mean the third argument
        if ~mod(done_trials, value(asv_trials))
            save_solouiparamvalues(value(ratname), 'child_protocol', mychild, 'asv', 1,  ...
                'experimenter', value(experimenter));
            save_soloparamvalues(value(ratname), 'asv',1, 'child_protocol', mychild, ...
                'experimenter', value(experimenter));
        end;
end;


