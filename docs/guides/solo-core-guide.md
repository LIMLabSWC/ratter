# Solo Core Guide

## Introduction

Solo Core is the foundation of the ExperPort system, providing essential functionality for protocol development, state machine control, and data management.

## Core Components

### State Machine

1. **State Matrix**
   ```matlab
   % Basic state matrix structure
   sm = StateMachineAssembler();
   sm = add_state(sm, 'name', 'state1', ...
       'input_to_statechange', {'Tup', 'state2'});
   ```

2. **Event Handling**
   ```matlab
   % Event processing
   function process_event(obj, event)
       % Handle event
       switch event.type
           case 'Tup'
               % Timer event
           case 'LickIn'
               % Lick event
       end
   end
   ```

### Protocol System

1. **Protocol Definition**
   ```matlab
   % Protocol structure
   classdef MyProtocol < handle
       properties
           % Protocol parameters
       end
       
       methods
           % Protocol methods
       end
   end
   ```

2. **Parameter Management**
   ```matlab
   % Parameter handling
   function set_parameter(obj, name, value)
       % Validate and set parameter
       assert(isprop(obj, name), 'Invalid parameter');
       obj.(name) = value;
   end
   ```

## Data Management

### Data Acquisition

1. **Event Logging**
   ```matlab
   % Log events
   function log_event(obj, event)
       % Record event
       obj.event_log = [obj.event_log; event];
   end
   ```

2. **Performance Tracking**
   ```matlab
   % Track performance
   function update_performance(obj, trial)
       % Update statistics
       obj.performance = calculate_performance(trial);
   end
   ```

### Data Storage

1. **File Management**
   ```matlab
   % Save data
   function save_data(obj, filename)
       % Save protocol data
       save(filename, 'obj');
   end
   ```

2. **Data Analysis**
   ```matlab
   % Analyze data
   function analyze_data(obj)
       % Process data
       results = process_data(obj.data);
   end
   ```

## User Interface

### GUI Components

1. **Parameter Display**
   ```matlab
   % Display parameters
   function update_display(obj)
       % Update GUI
       set(obj.param_display, 'String', obj.param_value);
   end
   ```

2. **Control Panel**
   ```matlab
   % Control interface
   function create_controls(obj)
       % Create control panel
       obj.control_panel = uipanel('Title', 'Controls');
   end
   ```

## Protocol Development

### Basic Protocol

```matlab
% Example basic protocol
classdef BasicProtocol < handle
    properties
        % Parameters
        reward_duration = 0.1;
        timeout_duration = 2;
    end
    
    methods
        function sm = make_state_matrix(obj)
            sm = StateMachineAssembler();
            
            % States
            sm = add_state(sm, 'name', 'wait_for_lick', ...
                'input_to_statechange', {
                    'LickIn', 'reward';
                    'Tup', 'timeout'
                });
        end
    end
end
```

### Advanced Protocol

```matlab
% Example advanced protocol
classdef AdvancedProtocol < handle
    properties
        % Parameters
        reward_duration = 0.1;
        timeout_duration = 2;
        sound_duration = 0.5;
    end
    
    methods
        function sm = make_state_matrix(obj)
            sm = StateMachineAssembler();
            
            % States with sound
            sm = add_state(sm, 'name', 'play_sound', ...
                'self_timer', obj.sound_duration, ...
                'input_to_statechange', {
                    'Tup', 'wait_for_lick'
                }, ...
                'output_actions', {
                    'SoundOut', 1
                });
        end
    end
end
```

## Best Practices

### Protocol Design

1. **State Organization**
   - Group related states
   - Clear state names
   - Logical flow

2. **Parameter Management**
   - Meaningful defaults
   - Proper validation
   - Clear documentation

3. **Error Handling**
   - Input validation
   - State verification
   - Error recovery

### Performance Optimization

1. **State Machine**
   - Minimize states
   - Efficient transitions
   - Clear logic

2. **Resource Management**
   - Memory usage
   - CPU utilization
   - Hardware timing

## Troubleshooting

### Common Issues

1. **State Machine**
   - State transition errors
   - Timing issues
   - Event handling problems

2. **Data Management**
   - File access errors
   - Data corruption
   - Performance issues

### Solutions

1. **Debugging**
   - State tracing
   - Event logging
   - Performance profiling

2. **Error Recovery**
   - State reset
   - Data backup
   - System restart

## Support

For additional information:
- See [Protocol Guide](protocol-writers-guide.md)
- Refer to [System Overview](../architecture/system-overview.md)
- Contact system administrators 