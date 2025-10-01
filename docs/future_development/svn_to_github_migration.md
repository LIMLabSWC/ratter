---
title: SVN to GitHub Migration Plan
layout: default
---

# SVN to GitHub Migration Plan

## Overview

This document outlines the plan to refactor the bcontrol system's SVN update process to incorporate GitHub for protocols and potentially other components.

## Current System

As documented in `/docs/technical/svn_update_process.md`, bcontrol currently uses SVN for updating multiple components:

- Main Code Directory
- Protocols Directory
- Data Files Directory
- Settings Files Directory
- Log Files (weekly archiving)

The SVN update occurs primarily through the `update_folder` function in `runrats.m` during protocol loading.

## Migration Goals

1. **Replace SVN with Git/GitHub for Protocol Management**
   - Move protocol repositories from SVN to GitHub
   - Enable versioning and tracking of protocols in a modern VCS
   - Facilitate collaboration on protocol development
   - Improve protocol review processes

2. **Update Codebase to Support Multiple VCS**
   - Refactor the `update_folder` function to support both SVN and Git
   - Eventually migrate all components to Git

## Implementation Plan

### Phase 1: Research and Analysis

- [ ] Analyze all SVN dependencies in the codebase
- [ ] Determine which GitHub APIs and libraries will be needed
- [ ] Evaluate impact on existing workflows
- [ ] Identify necessary MATLAB interfaces for Git operations

### Phase 2: Protocol Migration

- [ ] Create GitHub repositories for all existing protocols
- [ ] Migrate protocol history from SVN to Git
- [ ] Define branching strategy for protocol development
- [ ] Update documentation on protocol management

### Phase 3: Code Implementation

- [ ] Create a Git interface class/module similar to existing SVN functions
- [ ] Refactor `update_folder` to detect repository type (SVN or Git)
- [ ] Implement Git update functionality
- [ ] Add proper error handling for Git operations
- [ ] Update configuration to support Git repository URLs

```matlab
% Pseudo-code for refactored update_folder function
function update_folder(folder_path)
    % Detect repository type
    if is_git_repository(folder_path)
        update_git_repository(folder_path);
    elseif is_svn_repository(folder_path)
        update_svn_repository(folder_path);
    else
        % Handle case where folder is not under version control
        warning('Folder is not under version control');
    end
end
```

### Phase 4: Testing and Deployment

- [ ] Conduct thorough testing of Git update functionality
- [ ] Test with real protocols in a staging environment
- [ ] Develop migration guide for lab members
- [ ] Plan gradual rollout strategy
- [ ] Monitor for issues during transition period

## Additional Considerations

### Authentication

- Determine secure methods for GitHub authentication
- Consider using Personal Access Tokens or deploy keys
- Ensure credentials are stored securely

### Offline Operation

- Ensure system can still function without internet access
- Implement graceful failure if updates cannot be performed

### Training

- Provide Git/GitHub training for lab members
- Document new workflow for protocol development and updates

### Long-term Vision

- Complete migration from SVN to Git for all system components
- Implement CI/CD pipelines for testing protocols
- Add automated validation of protocol changes
- Consider containerization of the environment for consistency

## Timeline

- Phase 1: 1-2 weeks
- Phase 2: 2-3 weeks
- Phase 3: 3-4 weeks
- Phase 4: 2-3 weeks
- Total estimated time: 2-3 months

## Resources

- GitHub API Documentation: <https://docs.github.com/en/rest>
- MATLAB Git Integration examples
- Team members with Git expertise
