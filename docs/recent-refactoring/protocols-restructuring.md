## Overview

As part of the May 2025 cleanup effort, we have improved the Protocols directory handling to be more robust and configuration-driven. This change affects how protocols are loaded and managed in the BControl system.

## Changes Made

### Directory Structure

1. **Protocols Directory Configuration**
   - Protocols directory location is now managed through settings
   - Location is stored in `GENERAL.Protocols_Directory` setting
   - System verifies directory exists during startup
   - No symbolic links or hard-coded paths
   - Single Protocols directory at root level

2. **BpodProtocols**
   - Dedicated `BpodProtocols/` directory for Bpod-specific protocols
   - Separates Bpodprotocols from standard BControl protocols
   - Improves clarity and maintainability

### Protocol Structure Requirements

1. **Directory Organization**
   - Each protocol must be in a directory named `@protocolname`
   - Protocol constructor file must have same name as directory
   - Old-style RPBox protocols (with `_obj.m` files) are excluded

2. **Required Protocol Actions**
   - 'init': Initialize protocol (create windows, variables)
   - 'update': Called periodically during trials
   - 'prepare_next_trial': Prepare state machine for next trial
   - 'trial_completed': Called when trial is complete
   - 'close': Clean up when protocol is closed

3. **Automatic Variables**
   - n_done_trials: Count of completed trials
   - n_started_trials: Count of started trials
   - parsed_events: Parsed events from current trial
   - latest_events: New events since last update
   - raw_events: All events from current trial

### Initialization Changes

1. **Path Setup**
   - Moved Protocols directory check after adding Modules to path
   - Ensures `bSettings` is available before use
   - Fixes "bSettings is not found" error

2. **Configuration-Based Approach**
   - Removed hard-coded path checks
   - Added proper check for Protocols directory from settings
   - Uses configuration as source of truth for Protocols location
   - Provides clear error messages if directory is not found

## Impact Assessment

### Potential Impacts

1. **Protocol Loading**
   - [ ] Verify all protocols load correctly
   - [ ] Test protocol switching
   - [ ] Check protocol inheritance
   - [ ] Verify protocol directory structure

2. **Initialization**
   - [ ] Test system startup
   - [ ] Verify path setup
   - [ ] Check settings loading
   - [ ] Test protocol scanning

3. **Bpod Integration**
   - [ ] Test Bpod protocol loading
   - [ ] Verify Bpod-specific features
   - [ ] Check protocol switching between Bpod and standard

## Testing Required

- [ ] Verify protocol loading in all experimental setups
- [ ] Test protocol inheritance and dependencies
- [ ] Validate Bpod protocol functionality
- [ ] Check initialization sequence
- [ ] Verify settings-based configuration
- [ ] Test protocol directory structure
- [ ] Verify automatic variable initialization

## Next Steps

1. Monitor protocol loading performance
2. Gather feedback from protocol developers
3. Update protocol development guidelines
4. Consider additional organization improvements
5. Document protocol development best practices

## Contact

For questions about these changes, contact the system administrator.
