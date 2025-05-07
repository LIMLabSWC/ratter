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