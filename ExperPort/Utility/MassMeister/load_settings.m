function handles = load_settings(handles)

try pname = bSettings('get','GENERAL','Main_Code_Directory'); 
    pname = [pname,filesep,'Utility',filesep,'MassMeister']; 
catch %#ok<CTCH>
    pname = 'C:\ratter\ExperPort\Utility\MassMeister';
end

file = [pname,filesep,'Properties.mat'];
handles.file = file;
if exist(file,'file') == 2
    load(file);
    
    if isfield(handles,'minmass_edit')
        set(handles.minmass_edit,  'string',num2str(properties.minmass));
        set(handles.rate_edit,     'string',num2str(properties.rate));
        set(handles.numreads_edit, 'string',num2str(properties.numreads));
        set(handles.threshold_edit,'string',num2str(properties.threshold));
        set(handles.error_edit,    'string',num2str(properties.error));
    else
        handles.minmass   = properties.minmass;
        handles.rate      = properties.rate;
        handles.numreads  = properties.numreads;
        handles.threshold = properties.threshold;
        handles.error     = properties.error;
    end
else
    if ~isfield(handles,'minmass_edit')
        handles.minmass   = 100;
        handles.rate      = 10;
        handles.numreads  = 20;
        handles.threshold = 0.4;
        handles.error     = 4;
    end
end