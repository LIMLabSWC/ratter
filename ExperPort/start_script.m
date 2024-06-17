svnusername = input('Enter SVN username : ','s');
svnpsswd = input('Enter SVN password : ','s');

cd C:\ratter\SoloData\Settings
display('Updating Solo Data ...')
cmdstr = sprintf('svn update --username="%s" --password="%s"',char(svnusername), char(svnpsswd));
stdo_data = system(cmdstr);
if ~stdo_data
    display('Solo Data Updated!');
else
    display('');
end
cd C:\ratter\Protocols
display('Updating Protocols ...')
cmdstr = sprintf('svn update --username="%s" --password="%s"',char(svnusername), char(svnpsswd));
stdo_protocols = system(cmdstr);
if ~stdo_protocols
    display('Protocols updated!')
else
    display('');
end

cd C:\ratter\ExperPort
display('Updating ExperPort ...')
cmdstr = sprintf('svn update --username="%s" --password="%s"',char(svnusername), char(svnpsswd));
stdo_protocols = system(cmdstr);
if ~stdo_protocols
    display('ExperPort updated!')
else
    display('');
end
% to be added : comport number of corresponding bpod
Bpod('COM1');
newstartup;
dispatcher('init');
dispatcher('set_protocol','AthenaDelayComp');

