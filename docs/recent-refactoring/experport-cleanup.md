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
   - Referenced in several protocol files, indicating active usage for olfactory IP configurations.
   - Used in multiple protocol objects including:
     - onebank_2afcobj
     - adil2afcobj
     - odorsegm2obj
     - mix2afcobj
     - odor_testobj
     - nl2afc_mix2obj
     - odorsampobj
     - odor_test2obj
     - odorsegm3obj
     - nl2afc_airmixobj
     - nl2afc_mixobj
     - chemotaxobj
     - flow_controller_calibobj

4. `bgnames.mat`
   - Referenced in `@odorsegm2obj/OdorSection.m`, indicating usage for background names.
   - Used in multiple protocol files including:
     - odorsegm2obj/OdorSection.m
     - odorsegm3obj/OdorSection.m
     - odorsegmobj/OdorSection.m
     - Also referenced in analysis scripts in ExperPort/Analysis/Odor_Segm/

5. `OdorNames.mat`
   - Referenced in `@adil2afcobj/OdorSection.m` and `@gf2afcobj/OdorSection.m`, indicating usage for odor names.
   - Used in odor-related protocol files.

6. `OdorSet.mat`
   - Referenced in `@odorsegm2obj/OdorSection.m` and `@odorsegm3obj/OdorSection.m`, indicating usage for odor set configurations.
   - Used in several odor-related protocol implementations.

## Implementation Plan

### Phase 1: Backup and Documentation
Changes are version controlled on `integration-junk-removal` branch

### Phase 2: Gradual Removal
- Remove files in "confirmed unused" category
- Run protocols
- If issues arise, restore the files

### Phase 3: Investigation
For files requiring further investigation:
- remove files and archive related protocols in 'Protocols/legacy'
  
### Phase 4: Cleanup
- Update documentation
- Update any related configuration files

## Success Criteria
- All removed files are properly backed up
- No functionality is broken
- All tests pass
- Documentation is updated
- Codebase is cleaner and more maintainable
