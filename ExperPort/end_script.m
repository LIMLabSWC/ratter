svnusername = input('Enter SVN username : ','s');
svnpsswd = input('Enter SVN password : ','s');
logmsg = input('Enter log message :','s');

cd C:\ratter\SoloData
display('Committing changed to versioned files in SoloData ...')
cmdstr = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
if ~(system(cmdstr))
    display('SoloData changed committed!')
end

[cmd, output] = system('svn status | find "?"'); %nonversioned files follow "?" symbol
output = strsplit(output);

for i = 2:2:length(output)
	cmdstr = char(strcat('svn add', {' '}, output{i},{'@'})); %the @ kills me, ref to 
    % https://stackoverflow.com/questions/27312188/how-to-move-rename-a-file-in-subversion-with-characters-in-it
	system(cmdstr);
end

cmdstr = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
if ~(system(cmdstr))
    display('SoloData files added!')
end