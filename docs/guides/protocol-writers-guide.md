---
title: Documentation
layout: default
---


This guide explains how to create and implement protocols for the ExperPort system. Protocols define the experimental procedures and control the behavior of the system during experiments.

## Protocol Structure

### Basic Components

1. **Protocol Class**

   ```matlab
   classdef MyProtocol < handle
       properties
           % Protocol parameters
           param1
           param2
       end
       
       methods
           % Protocol methods
       end
   end
   ```

2. **State Machine Definition**

   ```matlab
   function sm = make_state_matrix(obj)
       % Define states
       sm = StateMachineAssembler();
       
       % Add states
       sm = add_state(sm, 'name', 'state1', ...
           'input_to_statechange', {'Tup', 'state2'});
   end
   ```

## Protocol Development

### Parameter Management

1. **Parameter Definition**

   ```matlab
   properties
       % Protocol parameters
       param1 = 1;      % Default value
       param2 = 'text'; % String parameter
   end
   ```

2. **Parameter Validation**

   ```matlab
   function set.param1(obj, value)
       % Validate parameter
       assert(isnumeric(value), 'Parameter must be numeric');
       obj.param1 = value;
   end
   ```

### State Machine Implementation

1. **State Definition**

   ```matlab
   % Define states
   sm = add_state(sm, 'name', 'wait_for_lick', ...
       'input_to_statechange', {
           'LickIn', 'reward';
           'Tup', 'timeout'
       });
   ```

2. **Output Control**

   ```matlab
   % Control outputs
   sm = add_state(sm, 'name', 'reward', ...
       'output_actions', {
           'DOut', 1;  % Open valve
           'SoundOut', 1  % Play sound
       });
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

## Example Protocols

### Basic Protocol

```matlab
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
                
            sm = add_state(sm, 'name', 'reward', ...
                'self_timer', obj.reward_duration, ...
                'input_to_statechange', {
                    'Tup', 'wait_for_lick'
                }, ...
                'output_actions', {
                    'DOut', 1
                });
                
            sm = add_state(sm, 'name', 'timeout', ...
                'self_timer', obj.timeout_duration, ...
                'input_to_statechange', {
                    'Tup', 'wait_for_lick'
                });
        end
    end
end
```

### Advanced Protocol

```matlab
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
                
            % ... more states
        end
    end
end
```

## Testing and Debugging

### Protocol Testing

1. **State Verification**
   - State transitions
   - Output actions
   - Timing accuracy

2. **Parameter Testing**
   - Value ranges
   - Edge cases
   - Error conditions

### Debugging Tools

1. **State Machine Debugger**
   - State tracing
   - Event logging
   - Output monitoring

2. **Performance Profiler**
   - Timing analysis
   - Resource usage
   - Bottleneck identification

## Support

For additional information:

- See [FSM Documentation](../technical/fsm-documentation.md)
- Refer to [System Overview](../architecture/system-overview.md)
- Contact system administrators
