# Protocols Directory Restructuring

## Overview

As part of the May 2025 cleanup effort, we have restructured the Protocols directory to improve maintainability and fix initialization issues. This change affects how protocols are loaded and managed in the BControl system.

## Changes Made

### Directory Structure

1. **Main Protocols Directory**
   - Moved from `ExperPort/Protocols/` to root `/Protocols/`
   - Created symbolic link from `ExperPort/Protocols` to `/Protocols`
   - Maintains backward compatibility while improving organization

2. **Bpod Protocols**
   - Dedicated `Bpod Protocols/` directory for Bpod-specific protocols
   - Separates Bpod protocols from standard BControl protocols
   - Improves clarity and maintainability

### Initialization Changes

1. **Path Setup**
   - Moved Protocols directory check after adding Modules to path
   - Ensures `bSettings` is available before use
   - Fixes "bSettings is not found" error

2. **Configuration-Based Approach**
   - Removed redundant check for `ExperPort/Protocols` directory
   - Added proper check for Protocols directory from settings
   - Uses configuration as source of truth for Protocols location

## Impact Assessment

### Potential Impacts

1. **Protocol Loading**
   - [ ] Verify all protocols load correctly
   - [ ] Test protocol switching
   - [ ] Check protocol inheritance

2. **Initialization**
   - [ ] Test system startup
   - [ ] Verify path setup
   - [ ] Check settings loading

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

## Next Steps

1. Monitor protocol loading performance
2. Gather feedback from protocol developers
3. Update protocol development guidelines
4. Consider additional organization improvements

## Contact

For questions about these changes, contact the system administrator. 