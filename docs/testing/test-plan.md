# BControl Test Plan

## Overview
This document outlines the testing strategy for the BControl system. The goal is to ensure system reliability and prevent regressions during refactoring.

## Test Categories

### 1. Unit Tests
Location: `tests/unit/`

#### Core System Tests
- `newstartup.m` functionality
  - Path configuration
  - Settings loading
  - Protocol directory validation
  - First run handling
  - Global variable initialization

#### Helper Function Tests
- `HandleNewstartupError`
- `BControl_First_Run`
- `Verify_Settings`
- `Compatibility_Globals`

#### Settings Tests
- `bSettings` functionality
- Settings file validation
- Default settings verification
- Custom settings handling

### 2. Integration Tests
Location: `tests/integration/`

#### System Initialization
- Complete startup sequence
- Path configuration
- Protocol loading
- Hardware initialization

#### Protocol Integration
- Protocol loading and initialization
- Protocol switching
- Protocol state management
- Event handling

#### Hardware Integration
- State machine communication
- Sound machine integration
- DIO line configuration
- Pump control

### 3. Protocol Tests
Location: `tests/protocols/`

#### Basic Protocol Tests
- Protocol initialization
- Trial execution
- State transitions
- Event handling
- Data collection

#### Specific Protocol Tests
- `AthenaDelayComp` protocol
- Other active protocols
- Protocol inheritance
- Protocol-specific features

## Test Implementation

### MATLAB Test Framework
We'll use MATLAB's built-in testing framework:
```matlab
% Example test structure
function tests = test_newstartup
    tests = functiontests(localfunctions);
end

function test_path_configuration(testCase)
    % Test path configuration
end

function test_settings_loading(testCase)
    % Test settings loading
end
```

### Test Data
- Create test settings files
- Mock hardware responses
- Simulate protocol states
- Generate test events

### Test Environment
- Isolated test directory
- Mock hardware interfaces
- Test-specific settings
- Clean state for each test

## Implementation Plan

### Phase 1: Core System Tests
1. Set up test framework
2. Implement unit tests for `newstartup.m`
3. Test helper functions
4. Verify settings handling

### Phase 2: Integration Tests
1. Test complete startup sequence
2. Verify protocol loading
3. Test hardware integration
4. Validate event handling

### Phase 3: Protocol Tests
1. Test basic protocol functionality
2. Implement protocol-specific tests
3. Verify protocol inheritance
4. Test protocol features

## Running Tests
```matlab
% Run all tests
results = runtests('tests')

% Run specific test category
results = runtests('tests/unit')

% Run specific test file
results = runtests('tests/unit/test_newstartup')
```

## Continuous Integration
- Run tests before merging changes
- Verify all tests pass
- Generate test reports
- Track test coverage

## Next Steps
1. Set up test framework
2. Create initial test suite
3. Implement core system tests
4. Add integration tests
5. Develop protocol tests
6. Set up CI pipeline

## Notes
- Tests should be independent
- Use mock objects where appropriate
- Clean up test data after runs
- Document test requirements
- Maintain test coverage 