# System Architecture

This document outlines the permanent architecture of the system, including core components, their relationships, and key workflows.

## Core System Components

```mermaid
graph TB
    %% Core Components
    subgraph Core ["Core System"]
        NS["newstartup.m"]
        Settings["Settings Module"]
    end

    subgraph Protocols ["Protocol System"]
        Base["@protocolobj"]
        
        subgraph Active ["Active Protocols"]
            AD["@AthenaDelayComp"]
            SC["@SoundCatContinuous"]
            AC["@ArpitCentrePokeTraining"]
        end
    end

    %% Essential Plugin Groups
    subgraph Essential ["Essential Plugins"]
        UI["UI Plugins"]
        Data["Data Handling"]
        Sound["Sound Management"]
        Control["Control Plugins"]
    end

    %% Key Relationships
    NS --> Settings
    NS --> Protocols
    Active --> Base
    Active --> Essential
    
    %% Style
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px
    classDef core fill:#e6ffe6,stroke:#060,stroke-width:2px
    classDef active fill:#ffe6e6,stroke:#600,stroke-width:1px
    
    class Core,Settings core
    class Active active
```

## Protocol Plugin Details

```mermaid
graph LR
    %% Plugin Categories
    subgraph UI ["UI Plugins"]
        direction TB
        pokesplot2
        soundui
        distribui
        punishui
    end

    subgraph Data ["Data Handling"]
        direction TB
        saveload
        sessionmodel
        sqlsummary
        comments
    end

    subgraph Sound ["Sound Management"]
        direction TB
        soundmanager
        soundtable
    end

    subgraph Control ["Control Plugins"]
        direction TB
        water
        antibias
        reinforcement
    end

    %% Protocol Usage
    AD["@AthenaDelayComp"] --> UI & Data & Sound & Control
    SC["@SoundCatContinuous"] --> UI & Data & Sound & Control
    AC["@ArpitCentrePokeTraining"] --> UI & Data & Sound
    
    %% Style
    classDef group fill:#f9f9f9,stroke:#333,stroke-width:1px
    classDef proto fill:#ffe6e6,stroke:#600,stroke-width:1px
    
    class UI,Data,Sound,Control group
    class AD,SC,AC proto
```

## System Startup Flow

```mermaid
sequenceDiagram
    participant User
    participant System as newstartup.m
    participant Settings
    participant Protocols

    User->>System: Start
    System->>Settings: Load Configuration
    System->>Protocols: Initialize
    Protocols-->>System: Ready
    System-->>User: System Ready
```

## Key Components

1. **Core System**
   - `newstartup.m`: System initialization
   - Settings Module: Configuration management

2. **Active Protocols**
   - `@AthenaDelayComp`: Full plugin suite
   - `@SoundCatContinuous`: Full plugin suite
   - `@ArpitCentrePokeTraining`: Basic plugin set

3. **Plugin Categories**
   - UI: Visual interfaces and plotting
   - Data: Storage and session management
   - Sound: Audio control and management
   - Control: Hardware and behavior control

## Plugin Usage

| Protocol | UI | Data | Sound | Control |
|----------|-------|--------|--------|----------|
| AthenaDelayComp | ✓ | ✓ | ✓ | ✓ |
| SoundCatContinuous | ✓ | ✓ | ✓ | ✓ |
| ArpitCentrePokeTraining | ✓ | ✓ | ✓ | - |

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
graph LR
    %% Base Protocol
    Base["@protocolobj"]
    
    %% Active Protocols
    AD["@AthenaDelayComp"]
    SC["@SoundCatContinuous"]
    AC["@ArpitCentrePokeTraining"]

    %% Plugin Groups
    subgraph Core ["Core Plugins"]
        direction TB
        PP["pokesplot2"]
        SL["saveload"]
        SM["sessionmodel"]
        SW["soundmanager"]
        SU["soundui"]
        WA["water"]
    end

    subgraph Extended ["Extended Plugins"]
        direction TB
        DU["distribui"]
        PU["punishui"]
        CO["comments"]
        ST["soundtable"]
        SQ["sqlsummary"]
        RF["reinforcement"]
        AB["antibias"]
    end

    %% Inheritance
    AD --> Base
    SC --> Base
    AC --> Base

    %% Plugin Usage
    AD --> Core & Extended
    SC --> Core & Extended
    AC --> Core
    AC --> CO & ST & SQ & AB

    %% Style
    classDef base fill:#e6ffe6,stroke:#060,stroke-width:2px
    classDef active fill:#ffe6e6,stroke:#600,stroke-width:1px
    classDef plugin fill:#e6e6ff,stroke:#006,stroke-width:1px
    
    class Base base
    class AD,SC,AC active
    class Core,Extended plugin
``` 