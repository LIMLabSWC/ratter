---
title: Documentation
layout: default
---


## System Architecture

### Core Components

1. **State Machine**
   - Finite State Machine (FSM) implementation
   - Real-time control of experiment flow
   - Event-driven architecture

2. **Hardware Interface**
   - LynxTrig for sound control
   - Comedi for digital I/O
   - Real-time Linux server

3. **Data Management**
   - Real-time data acquisition
   - Protocol-based experiment control
   - Data storage and analysis

### Data Flow

The diagram below illustrates how data flows through the system during experiment execution. This sequence shows the interactions between system components during a typical behavioral experiment:

<div class="mermaid">
sequenceDiagram
    participant P as Protocol
    participant SM as State Machine
    participant HW as Hardware Interface
    participant DA as Data Acquisition
    participant DS as Data Storage
    participant A as Analysis

    P->>SM: Define State Matrix
    SM->>HW: Control Hardware
    HW->>DA: Generate Events
    DA->>P: Real-time Events
    P->>DA: Process Events
    DA->>DS: Store Data
    DS->>A: Analyze Results
    A-->>P: Inform Protocol Design
    
    loop Trial Execution
        P->>SM: Update State Matrix
        SM->>HW: Execute State Changes
        HW->>DA: Generate New Events
        DA->>P: Update Trial Data
    end
</div>

**Key Data Flow Processes:**

- Protocols define state matrices that control experiment logic
- State matrices execute on hardware to produce stimulus and record responses
- Events are processed in real-time and fed back to the protocol
- The trial execution loop repeats for each trial in an experiment
- Data is stored for later analysis, which informs protocol refinement

### System Initialization Flow

The following diagram shows how the system initializes and the two possible user interface paths - either through Dispatcher (for researchers) or RunRats (for technicians):

<div class="mermaid">
sequenceDiagram
    participant User
    participant NS as newstartup.m
    participant Settings
    participant Dispatcher
    participant RunRats
    participant Protocol

    User->>NS: Start System
    NS->>Settings: Load Configuration
    Settings-->>NS: Configuration Loaded
    NS->>NS: Configure Paths & Environment
    NS-->>User: System Ready
    
    alt Dispatcher Interface
        User->>Dispatcher: Initialize (init)
        Dispatcher->>Dispatcher: Create UI
        Dispatcher->>Protocol: Load Selected Protocol
        Protocol-->>Dispatcher: Protocol Ready
        Dispatcher-->>User: Ready for Experiments
    else RunRats Interface
        User->>RunRats: Initialize (init)
        RunRats->>Dispatcher: Initialize (hidden)
        RunRats->>RunRats: Create Technician UI
        RunRats->>Protocol: Load Selected Protocol
        Protocol-->>RunRats: Protocol Ready
        RunRats-->>User: Ready for Experiments
    end
</div>

**System Initialization Highlights:**

- The system begins with `newstartup.m`, which configures paths and loads settings
- Users can choose between two interfaces:
  - **Dispatcher**: Direct interface for researchers with full control
  - **RunRats**: Simplified interface for technicians that uses Dispatcher behind the scenes
- Both interfaces ultimately load and control protocols, but with different user experiences
- The initialization process ensures proper environment setup before any experiments can run

## Hardware Integration

### Sound System

- LynxTWO sound card
- Real-time sound triggering
- Sample rates up to 210KHz

### Digital I/O

- Comedi interface
- Parallel port support
- National Instruments cards

### Real-time Control

- RTLinux server
- Hardware interrupts
- Microsecond timing

## Software Components

### Core Modules

1. **State Machine Assembler**
   - Protocol compilation
   - State matrix generation
   - Event handling

2. **Dispatcher**
   - Real-time event processing
   - Hardware control
   - Data logging

3. **Protocol System**
   - Protocol definition
   - Parameter management
   - Experiment control

### Utility Modules

1. **Water Control**
   - Valve control
   - Calibration
   - Monitoring

2. **Sound Management**
   - Sound file handling
   - Playback control
   - Trigger management

3. **Data Analysis**
   - Real-time processing
   - Performance tracking
   - Data visualization

## System Requirements

### Hardware

- LynxTWO sound card
- Compatible I/O hardware
- Sufficient processing power

### Software

- RTLinux 3.1/3.2
- MATLAB
- Required kernel modules

### Network

- Local network connection
- Client-server architecture
- Real-time communication

## Configuration

### Basic Setup

1. Install hardware components
2. Configure kernel modules
3. Set up network connections

### Advanced Configuration

1. Optimize interrupt handling
2. Configure real-time parameters
3. Set up data storage

## Maintenance

### Regular Tasks

1. Hardware calibration
2. Software updates
3. Data backup

### Troubleshooting

1. Hardware diagnostics
2. Software debugging
3. Performance monitoring

## Support

For additional information:

- See [Hardware Setup](../hardware/)
- Refer to [Technical Documentation](../technical/)
- Contact system administrators
