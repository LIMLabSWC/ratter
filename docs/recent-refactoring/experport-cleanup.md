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
The following files have no direct references in the codebase and can be safely removed:

1. `start_script.m`
   - No references found in the codebase outside of this cleanup document.

2. `beginit.m`
   - No references found in the codebase outside of this cleanup document.

3. `remove_protocol_preferences.m`
   - No references found in the codebase outside of this cleanup document.

4. `reporter.m`
   - No references found in the codebase outside of this cleanup document.

5. `RPbox_realbox.m`
   - No references found in the codebase outside of this cleanup document.

6. `ExperRPBox.m`
   - No references found in the codebase outside of this cleanup document.

7. `ExperStart.m`
   - No references found in the codebase outside of this cleanup document.

8. `ExperValveCheck.m`
   - No references found in the codebase outside of this cleanup document.

### Files Requiring Further Investigation
These files have limited or indirect usage and should be investigated before removal:

1. `end_script.m` - Referenced in configuration files but not directly called
   - No active references found in the codebase outside of this cleanup document.

2. `RExper.m` - Only referenced in Control.m
   - No active references found in the codebase outside of this cleanup document.

3. `olfip.mat`
   - All related protocols have been moved to Protocols/legacy folder (commit: 1c8b5d799155912251a1b6ac44881e3b8e00983d)
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
   - The olfip.mat file itself remains in place as it may be needed by other components

4. `bgnames.mat`
   - All related protocols and analysis code moved to legacy folders (commit: b714b1848ac6d1bf70e666daa3f85338b403169f)
   - Analysis code moved to Analysis/legacy/Odor_Segm/
   - Protocol folders already in Protocols/legacy from previous olfip.mat move:
     - @odorsegm2obj
     - @odorsegm3obj
     - @odorsegmobj
   - The bgnames.mat file itself remains in place as it may be needed by other components

5. `OdorNames.mat`
   - All related protocols moved to legacy folder (commit: b714b1848ac6d1bf70e666daa3f85338b403169f)
   - Protocols in legacy:
     - @adil2afcobj (moved with olfip.mat)
     - @gf2afcobj
   - The OdorNames.mat file itself remains in place as it may be needed by other components

6. `OdorSet.mat`
   - All related protocols already in legacy folder (commit: b714b1848ac6d1bf70e666daa3f85338b403169f)
   - Used by protocols that were moved with olfip.mat:
     - @odorsegm2obj
     - @odorsegm3obj
   - The OdorSet.mat file itself remains in place as it may be needed by other components

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
If issues arise:
1. Restore files from backup
2. Document the discovered dependencies
3. Update this plan with new findings

## Notes
- Some files might be used indirectly through MATLAB's path system
- Consider adding a deprecation notice before removal
- Keep track of any files that are restored due to discovered dependencies
