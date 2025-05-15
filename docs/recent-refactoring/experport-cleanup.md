# ExperPort Cleanup Plan

## Overview
This document outlines the plan to remove unused .m files from the ExperPort directory. The goal is to reduce code clutter and maintenance burden by removing files that are no longer actively used in the codebase.

## Actively Used Files

The following files are actively used in the codebase and should be retained:

1. `flush.m`
   - Referenced in multiple protocol files, indicating active usage for flushing operations.
   - Used extensively in protocol files for flushing operations and cleaning up variables.
   - Called by many protocol objects in their initialization and close methods.

2. `rows.m`
   - Referenced in multiple protocol files, indicating active usage for row operations.
   - Used in matrix operations throughout the codebase.

3. `newstartup.m`
   - Core system initialization script that sets up paths, loads settings, and prepares the environment.
   - Referenced in Modules/Settings.m and Modules/bSettings.m.
   - Essential for starting the BControl system.

## Files to Remove

### Confirmed Unused Files
The following files have been moved to ExperPort/legacy (commit: 67d64ad):

1. `start_script.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

2. `beginit.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

3. `remove_protocol_preferences.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

4. `reporter.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

5. `RPbox_realbox.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

6. `ExperRPBox.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

7. `ExperStart.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

8. `ExperValveCheck.m`
   - No references found in the codebase outside of this cleanup document.
   - Moved to ExperPort/legacy

### Files Requiring Further Investigation
These files have been moved to ExperPort/legacy (commit: 67d64ad) but require further investigation before potential removal:

1. `end_script.m`
   - Referenced in configuration files but not directly called
   - No active references found in the codebase outside of this cleanup document
   - Moved to ExperPort/legacy for further investigation

2. `RExper.m`
   - Only referenced in Control.m
   - No active references found in the codebase outside of this cleanup document
   - Moved to ExperPort/legacy for further investigation

3. `olfip.mat`
   - All related protocols have been moved to Protocols/legacy folder (commit: 1c8b5d7)
   - This includes 15 protocol folders and their associated .m files:
     - @onebank_2afcobj
     - @adil2afcobj
     - @odorsegm2obj
     - @mix2afcobj
     - @odor_testobj
     - @nl2afc_mix2obj
     - @odorsampobj
     - @odor_test2obj
     - @odorsegm3obj
     - @nl2afc_airmixobj
     - @nl2afc_mixobj
     - @chemotaxobj
     - @flow_controller_calibobj
     - @odorsegmobj
     - @nl_odorsamp2obj
   - These protocols are no longer actively used and depend on legacy olfactometer configurations
   - Initially remained in place, now moved to ExperPort/legacy

4. `bgnames.mat`
   - All related protocols and analysis code moved to legacy folders (commit: b714b18)
   - Analysis code moved to Analysis/legacy/Odor_Segm/
   - Protocol folders already in Protocols/legacy from previous olfip.mat move:
     - @odorsegm2obj
     - @odorsegm3obj
     - @odorsegmobj
   - Initially remained in place, now moved to ExperPort/legacy

5. `OdorNames.mat`
   - All related protocols moved to legacy folder (commit: b714b18)
   - Protocols in legacy:
     - @adil2afcobj (moved with olfip.mat)
     - @gf2afcobj
   - Initially remained in place, now moved to ExperPort/legacy

6. `OdorSet.mat`
   - All related protocols already in legacy folder (commit: b714b18)
   - Used by protocols that were moved with olfip.mat:
     - @odorsegm2obj
     - @odorsegm3obj
   - Initially remained in place, now moved to ExperPort/legacy

## Implementation Plan

### Phase 1: Backup and Documentation
1. Create a backup branch before making any changes
2. Document the current state of each file to be removed
3. Create a backup copy of each file in a separate directory

### Phase 2: Gradual Removal
1. Remove one file at a time, starting with the confirmed unused files
2. After each removal:
   - Run the test suite
   - Verify that all protocols still work
   - Check for any runtime errors
3. If issues arise, restore the file and document the dependency

### Phase 3: Investigation
1. For files requiring further investigation:
   - Add logging to track usage
   - Monitor for a period of time
   - Document any discovered dependencies
2. Make a decision based on findings

**Update (May 15, 2025, commit: fe550df):** Investigation completed for olfactory-related .mat files. After verification that no active code depends on these files, all four files (olfip.mat, bgnames.mat, OdorNames.mat, and OdorSet.mat) have been moved to ExperPort/legacy for consistency with the previous protocol and analysis code moves.

### Phase 4: Cleanup
1. Remove backup copies
2. Update documentation
3. Update any related configuration files

## Success Criteria
- All removed files are properly backed up
- No functionality is broken
- All tests pass
- Documentation is updated
- Codebase is cleaner and more maintainable

## Rollback Plan
The following changes are listed from newest to oldest. When rolling back, start from the bottom (7) and work your way up to (1):

Most Recent:
1. Olfactory .mat files to legacy (commit: fe550df, May 15, 2025):
   - Restore olfip.mat, bgnames.mat, OdorNames.mat, and OdorSet.mat from ExperPort/legacy to ExperPort root
   - This completes the previous refactoring effort by moving all olfactory-related components to legacy folders

2. ExperPort unused and investigation files (67d64ad):
   - Restore from ExperPort/legacy to ExperPort root
   - Includes start_script.m, beginit.m, etc.
   - Also includes end_script.m and RExper.m for investigation

3. Analysis and Protocol files for .mat files (b714b18):
   - Restore Analysis/legacy/Odor_* folders to original locations
   - Restore @gf2afcobj from Protocols/legacy
   - Related to bgnames.mat, OdorNames.mat, and OdorSet.mat

4. Olfip.mat related protocols (1c8b5d7):
   - Restore all protocol folders from Protocols/legacy
   - Includes 15 protocol folders like @onebank_2afcobj, @adil2afcobj, etc.

5. Newstartup refactoring (60932b7):
   - Restore original structure of newstartup.m if needed
   - Check path handling and startup sequence

6. Unused code removal (5da710d):
   - Restore removed code sections if dependencies are discovered
   - Check impact on startup sequence

7. Documentation and path changes (ce835f7):
   - Restore ExperPort/Protocols path if needed
   - Review documentation for any missing critical information

Rollback Order: Start with #7 and work backwards to #1. This ensures proper restoration of dependencies.

For each rollback:
1. Use git checkout to the specific commit
2. Document any discovered dependencies
3. Update this plan with new findings

## Notes
- Some files might be used indirectly through MATLAB's path system
- Consider adding a deprecation notice before removal
- Keep track of any files that are restored due to discovered dependencies
