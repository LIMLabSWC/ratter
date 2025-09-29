# SVN Update Process in BControl System

This document explains when and how the automatic SVN updates happen in the BControl system, specifically during startup and protocol loading processes.

## Overview

The BControl system includes automatic SVN update functionality that ensures the code is always up-to-date when running experiments. These updates are not performed during the initial `newstartup.m` execution, but rather during the RunRats protocol loading phase.

## When SVN Updates Happen

SVN updates occur at the following points in the workflow:

1. **Protocol Loading Stage**: When a protocol is being loaded for a rat session in RunRats
2. **Session End**: When committing data and settings files after a successful session
3. **Weekly Log Archiving**: During weekly log file archiving (Mondays only)

## Directories Updated

The following directories receive SVN updates during BControl operation:

### During Protocol Loading

1. **Main Code Directory**
   - Updated during protocol loading in RunRats
   - Source: `runrats.m` in the `load_protocol` function
   - Path retrieved with: `pname = bSettings('get','GENERAL','Main_Code_Directory')`
   - Update command: `update_folder(pname,'svn')`
   - Typically points to the ExperPort directory

2. **Protocols Directory**
   - Updated during protocol loading in RunRats
   - Source: `runrats.m` in the `load_protocol` function
   - Path retrieved with: `pname = bSettings('get','GENERAL','Protocols_Directory')`
   - Update command: `update_folder(pname,'svn')`

### During Session End

3. **Data Files Directory**
   - When a protocol ends, RunRats performs SVN operations on data files
   - Source: `runrats.m` in the `end_continued` function
   - Path determined by the protocol's save location
   - Commands:

     ```matlab
     cd(pname);
     cmdstr = char(strcat('svn add', {' '}, fname, '.mat',{'@'}));
     system(cmdstr);
     cmdstr2 = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
     system(cmdstr2);
     ```

4. **Settings Files Directory**
   - When a protocol ends, RunRats performs SVN operations on settings files
   - Source: `runrats.m` in the `end_continued` function
   - Path determined by the protocol's settings file location
   - Similar commands to data files directory

### During Weekly Archiving

5. **Log Files**
   - During weekly archiving (Mondays), RunRats copies and commits log files
   - Source: `runrats.m` in the `reboot` function
   - Path constructed as: `[Main_Data_Directory]/Data/RunRats/Rig[RigID]/`
   - This only occurs during the reboot process on Mondays

## How Updates Work

### The `update_folder` Function

The core functionality for SVN updates is in the `update_folder` function in `runrats.m`:

```matlab
function update_folder(pname,vn)
  try
    currdir = pwd;
    cd(pname);
    if strcmp(vn,'cvs')
      failed1 = 0;
      [failed2 message2] = system('cvs up -d -P -A');
    elseif strcmp(vn,'svn')
      [failed1 message1] = system('svn cleanup');
      [failed2 message2] = system('svn update');
    end
    cd(currdir);
    
    // Error handling and email notification code follows...
  catch
    senderror_report;
  end
end
```

This function:

1. Saves the current directory
2. Changes to the target directory
3. Executes SVN cleanup to remove any locks
4. Runs SVN update to get the latest code
5. Returns to the original directory
6. Sends email notifications if either command fails

### Key Code Locations

The most important SVN update code can be found in the following locations:

1. **Protocol Loading Updates** - In `runrats.m` around line 1310-1340:

   ```matlab
   CurrDir = pwd;
   pname = bSettings('get','GENERAL','Main_Code_Directory');
   if ~isempty(pname) && ischar(pname)
     update_folder(pname,'svn');
   end

   %And finally we make sure the protocols are up-to-date
   pname = bSettings('get','GENERAL','Protocols_Directory');
   if ~isempty(pname) && ischar(pname)
     update_folder(pname,'svn');
   end
   cd(CurrDir);
   ```

2. **Data and Settings File Commits** - In `runrats.m` around line 1530-1590:

   ```matlab
   // Code for committing data files
   [pname,fname] = fileparts(sfile);
   cd(pname);
   cmdstr = char(strcat('svn add', {' '}, fname, '.mat',{'@'}));
   system(cmdstr);
   cmdstr2 = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
   system(cmdstr2);
   
   // Code for committing settings files
   [setpname, setfname] = fileparts(value(settings_file_sph));
   cd(setpname);
   cmdstr3 = char(strcat('svn add', {' '}, setfname, '.mat',{'@'}));
   system(cmdstr3);
   cmdstr4 = sprintf('svn ci --username="%s" --password="%s" -m "%s"',char(svnusername), char(svnpsswd), char(logmsg));
   system(cmdstr4);
   ```

## Startup Flow

To understand when these updates happen in the context of the overall system startup:

1. User runs `newstartup.m` - No SVN updates occur
2. User calls either `dispatcher('init')` or `runrats('init')`
3. If using RunRats:
   - System initializes the RunRats GUI
   - When a protocol is loaded:
     - System updates Main Code Directory (ExperPort) via SVN
     - System updates Protocols Directory via SVN
   - After a session ends:
     - System commits data and settings files

## Additional Notes

- The dispatcher.m module does not perform any SVN updates directly
- The SVN update functionality is only present in the RunRats workflow
- All SVN operations contain error handling and will send emails to relevant contacts if they fail
- Comments in the code suggest that the system can handle both SVN and CVS repositories, but SVN is primarily used

## Conclusion

The automatic SVN update feature in BControl ensures that the code is always up-to-date when running experiments. This approach minimizes the risk of version discrepancies and ensures that all experiments are run with the latest code.
