---
title: Documentation
layout: default
---


## Removed Scripts

### Process Management Scripts

1. **kill_by_name.pl**
   - **Previous Location**: `ExperPort/Modules/@bpodSound/kill_by_name.pl`
   - **Function**: Used to kill processes by name, likely used for sound server management
   - **Dependencies**: Perl

2. **kill_by_name.pl**
   - **Previous Location**: `ExperPort/Modules/@softsound/kill_by_name.pl`
   - **Function**: Used to kill processes by name, likely used for sound server management
   - **Dependencies**: Perl

### Automated Task Scripts

1. **nightly_runner.pl**
   - **Previous Location**: `ExperPort/nightly_runner.pl`
   - **Function**: Executed contents of runme_tonight.pl and then emptied its contents
   - **Dependencies**: Perl, CVS
   - **Note**: Part of an automated nightly task system

2. **runme_tonight.pl**
   - **Previous Location**: `ExperPort/runme_tonight.pl`
   - **Function**: Contained tasks to be executed nightly
   - **Dependencies**: Perl, CVS
   - **Note**: Part of an automated nightly task system

3. **nightly_followup.pl**
   - **Previous Location**: `ExperPort/nightly_followup.pl`
   - **Function**: Emptied contents of runme_tonight.pl and updated CVS
   - **Dependencies**: Perl, CVS
   - **Note**: Part of an automated nightly task system

### Version Control Scripts

1. **CVSAutoUpdater.pl**
   - **Previous Location**: `ExperPort/CVSAutoUpdater.pl`
   - **Function**: Automated CVS updates
   - **Dependencies**: Perl, CVS

### Utility Scripts

1. **remove_comments.pl**
   - **Previous Location**: `ExperPort/Utility/remove_comments.pl`
   - **Function**: Utility script for removing comments from code
   - **Dependencies**: Perl

## Impact Assessment

### Potential Impacts

1. **Process Management**
   - Sound server process management may need alternative solutions
   - Consider using MATLAB's system commands or Python scripts

2. **Automated Tasks**
   - Nightly tasks will need to be reimplemented
   - Consider using MATLAB's timer objects or system scheduler

3. **Version Control**
   - CVS automation is no longer available
   - Consider using Git commands directly or through MATLAB's interface

4. **Code Maintenance**
   - Comment removal functionality needs replacement
   - Consider using MATLAB's built-in functions or Python scripts

### Testing Required

- [ ] Verify sound server functionality
- [ ] Test automated task alternatives
- [ ] Validate version control workflows
- [ ] Check code maintenance tools

## Replacement Solutions

1. **Process Management**

   ```matlab
   % Example MATLAB alternative for process management
   system('taskkill /F /IM process_name.exe');
   ```

2. **Automated Tasks**

   ```matlab
   % Example MATLAB timer for automated tasks
   t = timer('TimerFcn', @myTask, 'Period', 86400, 'ExecutionMode', 'fixedRate');
   start(t);
   ```

3. **Version Control**

   ```matlab
   % Example MATLAB Git commands
   system('git pull');
   system('git commit -m "message"');
   ```

4. **Code Maintenance**

   ```matlab
   % Example MATLAB comment removal
   str = fileread('file.m');
   str = regexprep(str, '%[^\n]*', '');
   ```

## Archive Location

These scripts have been archived in a separate repository for historical reference. Contact the system administrator for access if needed.
