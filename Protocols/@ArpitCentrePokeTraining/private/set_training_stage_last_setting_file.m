function set_training_stage_last_setting_file(owner,experimenter,ratname)

try

global     Solo_datadir;

rat_dir = sprintf('%s\\Settings\\%s\\%s\\',Solo_datadir,experimenter,ratname);
% Get the latest setting file

u = dir([rat_dir 'settings_@' owner '_' experimenter '_' ratname '*.mat']);
if ~isempty(u)
    [filenames{1:length(u)}] = deal(u.name);
    filenames = sort(filenames'); %#ok<UDIM> (can't use dimension argument with cell sort)
    today_date_str = regexprep(char(datetime('today','Format','yy-MM-dd')), '[^0-9]', '');
    for i=length(u):-1:1 %     search from the end back
        file_date_num = textscan(filenames{i},['settings_@' owner '_' experimenter '_' ratname '_%n%*c.mat']);

        if ~isempty(file_date_num{1}) &&  file_date_num{1} <= str2double(today_date_str)
            fullname = [rat_dir filenames{i}]; %     We've found it.
            break
        end
    end
end

try
    loaded_data = load(fullname);
catch
    return;
end

% Lets find the Handle for Training Stage
handles = get_sphandle('owner', owner);
stage_handle_name = 'ParamsSection_training_stage';
for hi= 1:length(handles)
    sph_fullname=get_fullname(handles{hi});
    if strcmpi(sph_fullname,stage_handle_name)
        handles{hi}.value = loaded_data.saved.(sph_fullname); 
        callback(handles{i});
        break
    end
end

return

catch

    return

end

end