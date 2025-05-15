# System Architecture

This document outlines the permanent architecture of the system, including core components, their relationships, and key workflows.

## Core System Components

The following diagram shows the high-level architecture of active system components and their relationships:

```mermaid
graph LR
    %% Core System Components
    subgraph Core ["Core System"]
        direction LR
        NS["newstartup.m"]
        F["flush.m"]
        R["rows.m"]
    end

    subgraph Settings ["Settings Module"]
        direction LR
        SM["Settings.m"]
        BS["bSettings.m"]
        SC["SettingsObject"]
    end

    subgraph Protocols ["Protocol System"]
        direction LR
        subgraph Base ["Base Classes"]
            PO["@protocolobj"]
            NP["@nprotocol"]
        end
        
        subgraph Active ["Active Protocols"]
            direction LR
            CL["@Classical"]
            PS["@Psychometric"]
            AC["@ArpitCentrePokeTraining"]
        end
        
        subgraph Plugins ["Protocol Plugins"]
            direction LR
            PP["pokesplot"]
            SL["saveload"]
            SM2["sessionmodel"]
            SW["soundmanager"]
            SU["soundui"]
            WA["water"]
        end
    end

    %% Relationships
    NS --> SM
    NS --> BS
    BS --> SC
    
    %% Protocol relationships
    Active --> PO
    Active --> NP
    Active --> Plugins
    Active --> F
    Active --> R

    %% Module relationships
    NS --> |"Loads"| Protocols
    SM --> |"Configures"| Protocols

    %% Style
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef core fill:#e6ffe6,stroke:#060,stroke-width:2px;
    classDef settings fill:#e6e6ff,stroke:#006,stroke-width:2px;
    classDef protocols fill:#ffe6e6,stroke:#600,stroke-width:2px;
    
    class Core core;
    class Settings settings;
    class Protocols protocols;
```

### Component Descriptions

1. **Core System**
   - `newstartup.m`: Core system initialization script that sets up paths, loads settings, and prepares the environment
   - `flush.m`: Handles flushing operations, used extensively in protocol files
   - `rows.m`: Provides matrix operation functionality used throughout the codebase

2. **Settings Module**
   - `Settings.m`: Main settings management module
   - `bSettings.m`: Base settings configuration
   - These components work together to maintain system configuration

## System Startup Sequence

The following sequence diagram illustrates the system initialization process:

```mermaid
sequenceDiagram
    participant U as User
    participant NS as newstartup.m
    participant S as Settings.m
    participant BS as bSettings.m
    participant P as Protocols
    participant D as Dispatcher

    U->>NS: Start System
    NS->>BS: Load Settings Files
    BS->>S: Initialize Settings
    S->>BS: Load Base Settings
    NS->>P: Configure Protocol Paths
    P->>D: Register Available Protocols
    D->>NS: Ready State
    NS->>U: System Ready
```

### Startup Process Details

1. **System Initialization**
   - User triggers system start
   - `newstartup.m` begins initialization sequence

2. **Settings Configuration**
   - Settings module is initialized
   - Base settings are loaded and configured
   - System paths are established

3. **Protocol Loading**
   - Protocol paths are configured
   - Active protocols are made available

4. **System Ready State**
   - All components initialized
   - System ready for operation

## Dependencies and Requirements

1. **Core Dependencies**
   - MATLAB environment
   - Required toolboxes (list specific versions if applicable)
   - System-specific configurations

2. **Protocol Requirements**
   - Each protocol must implement specific interfaces
   - Protocols must handle flush operations appropriately
   - Matrix operations should utilize `rows.m` for consistency

## Best Practices

1. **Protocol Development**
   - Always use `flush.m` for cleanup operations
   - Implement proper error handling
   - Follow established naming conventions

2. **System Configuration**
   - Maintain settings in appropriate modules
   - Document any changes to core components
   - Follow established backup procedures

## Maintenance Guidelines

1. **Core Components**
   - Regular testing of startup sequence
   - Validation of settings management
   - Performance monitoring of critical operations

2. **Documentation**
   - Keep this architecture document updated
   - Document any new dependencies
   - Maintain clear protocol documentation

## Protocol Class Hierarchy

```mermaid
graph TD
    subgraph Base ["Base Protocol Classes"]
        PO["@protocolobj"]
        NP["@nprotocol"]
    end

    subgraph Plugins ["Protocol Plugins"]
        PP["pokesplot"]
        SL["saveload"]
        SM["sessionmodel"]
        SW["soundmanager"]
        SU["soundui"]
        WA["water"]
        DU["distribui"]
        CO["comments"]
        ST["soundtable"]
        SQ["sqlsummary"]
    end

    subgraph Active ["Active Protocol Classes"]
        CL["@Classical"]
        PS["@Psychometric"]
        AC["@ArpitCentrePokeTraining"]
    end

    %% Inheritance/Usage
    CL --> PO
    PS --> PO
    AC --> PO
    
    CL --> PP & SL & SM & SW & SU & WA & DU & CO & ST & SQ
    PS --> PP & SL & SM & SW & SU & WA
    AC --> PP & SL & SM & SW & SU & WA & DU & CO & ST & SQ

    %% Style
    classDef base fill:#e6ffe6,stroke:#060,stroke-width:2px;
    classDef plugin fill:#e6e6ff,stroke:#006,stroke-width:2px;
    classDef active fill:#ffe6e6,stroke:#600,stroke-width:2px;
    
    class Base base;
    class Plugins plugin;
    class Active active;
``` 