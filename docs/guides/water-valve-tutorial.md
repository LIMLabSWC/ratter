---
title: Documentation
layout: default
---


## Hardware Setup

### Valve Components

1. **Solenoid Valves**
   - 12V DC solenoid valves
   - Normally closed configuration
   - Quick response time

2. **Control Circuit**
   - Digital output control
   - Power supply
   - Protection circuitry

3. **Water Delivery System**
   - Water reservoir
   - Tubing
   - Lick spout

## Software Configuration

### Valve Control

1. **Digital Output Setup**

   ```matlab
   % Configure DIO for valve control
   dio = DigitalIO('ni');
   addline(dio, 0, 'out');  % Valve control line
   ```

2. **Valve Timing**

   ```matlab
   % Control valve timing
   function deliver_reward(obj, duration)
       putvalue(obj.dio, 1);  % Open valve
       pause(duration);
       putvalue(obj.dio, 0);  % Close valve
   end
   ```

### Calibration

1. **Volume Calibration**

   ```matlab
   % Calibrate valve delivery
   function calibrate_valve(obj)
       % Measure delivered volume
       volume = measure_delivery();
       
       % Calculate duration for target volume
       obj.valve_duration = calculate_duration(volume);
   end
   ```

2. **Timing Verification**

   ```matlab
   % Verify valve timing
   function verify_timing(obj)
       % Measure actual duration
       actual_duration = measure_duration();
       
       % Compare with expected
       assert(abs(actual_duration - obj.valve_duration) < 0.001, ...
           'Valve timing error');
   end
   ```

## Protocol Integration

### Basic Reward Delivery

```matlab
% Example protocol with reward
classdef RewardProtocol < handle
    properties
        valve_duration = 0.1;  % seconds
    end
    
    methods
        function sm = make_state_matrix(obj)
            sm = StateMachineAssembler();
            
            % Reward state
            sm = add_state(sm, 'name', 'reward', ...
                'self_timer', obj.valve_duration, ...
                'input_to_statechange', {
                    'Tup', 'wait_for_lick'
                }, ...
                'output_actions', {
                    'DOut', 1  % Open valve
                });
        end
    end
end
```

### Advanced Reward Control

```matlab
% Example with variable reward
classdef VariableRewardProtocol < handle
    properties
        min_duration = 0.05;
        max_duration = 0.2;
    end
    
    methods
        function duration = get_reward_duration(obj)
            % Random reward duration
            duration = obj.min_duration + ...
                rand() * (obj.max_duration - obj.min_duration);
        end
        
        function sm = make_state_matrix(obj)
            sm = StateMachineAssembler();
            
            % Variable reward state
            sm = add_state(sm, 'name', 'reward', ...
                'self_timer', @() obj.get_reward_duration(), ...
                'input_to_statechange', {
                    'Tup', 'wait_for_lick'
                }, ...
                'output_actions', {
                    'DOut', 1
                });
        end
    end
end
```

## Maintenance

### Regular Tasks

1. **Valve Cleaning**
   - Flush with clean water
   - Remove mineral deposits
   - Check for leaks

2. **Calibration**
   - Verify delivery volume
   - Check timing accuracy
   - Update calibration data

### Troubleshooting

1. **Common Issues**
   - Valve not opening
   - Inconsistent delivery
   - Timing errors

2. **Solutions**
   - Check power supply
   - Verify connections
   - Clean valve
   - Recalibrate

## Best Practices

### Hardware

1. **Installation**
   - Secure mounting
   - Proper tubing
   - Clean connections

2. **Maintenance**
   - Regular cleaning
   - Periodic calibration
   - Leak checking

### Software

1. **Control**
   - Precise timing
   - Error handling
   - State verification

2. **Calibration**
   - Regular updates
   - Volume verification
   - Timing checks

## Support

For additional information:

- See [Hardware Setup](../hardware/)
- Refer to [Protocol Guide](protocol-writers-guide.md)
- Contact system administrators
