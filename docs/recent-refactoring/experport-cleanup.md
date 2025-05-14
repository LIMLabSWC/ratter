# ExperPort Cleanup Plan

## Overview
This document outlines the plan to remove unused .m files from the ExperPort directory. The goal is to reduce code clutter and maintenance burden by removing files that are no longer actively used in the codebase.

## Actively Used Files

The following files are actively used in the codebase and should be retained:

1. `flush.m`
   - Referenced in multiple protocol files, indicating active usage for flushing operations.

2. `olfip.mat`
   - Referenced in several protocol files, indicating active usage for olfactory IP configurations.

3. `rows.m`
   - Referenced in multiple protocol files, indicating active usage for row operations.

4. `bgnames.mat`
   - Referenced in `@odorsegm2obj/OdorSection.m`, indicating usage for background names.

5. `OdorNames.mat`
   - Referenced in `@adil2afcobj/OdorSection.m`, indicating usage for odor names.

6. `OdorSet.mat`
   - Referenced in `@odorsegm2obj/OdorSection.m`, indicating usage for odor set configurations.

## Files to Remove

### Confirmed Unused Files
The following files have no direct references in the codebase and can be safely removed:

1. `start_script.m`
2. `beginit.m`
3. `remove_protocol_preferences.m`
4. `reporter.m`
5. `RPbox_realbox.m`
6. `ExperRPBox.m`
7. `ExperStart.m`
8. `ExperValveCheck.m`

### Files Requiring Further Investigation
These files have limited or indirect usage and should be investigated before removal:

1. `end_script.m` - Referenced in configuration files but not directly called
2. `RExper.m` - Only referenced in Control.m

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