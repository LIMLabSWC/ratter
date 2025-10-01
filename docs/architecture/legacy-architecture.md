---
title: Legacy Architecture and Cleanup Tracking
layout: default
---

# Legacy Architecture and Cleanup Tracking

This document tracks legacy components, their current status, and relationships. It serves as a temporary reference during the cleanup process and will be updated as components are fully deprecated or removed.

## Legacy Component Organization

The following diagram shows the current organization of legacy components and their relationships:

```mermaid
graph LR
    %% Define main containers
    subgraph Legacy_Protocols ["Protocols/legacy/"]
        direction LR
        subgraph Olfactory ["Olfactory Protocols"]
            OB["@onebank_2afcobj"]
            AD["@adil2afcobj"]
            OS2["@odorsegm2obj"]
            MIX["@mix2afcobj"]
            OT["@odor_testobj"]
            NL["@nl2afc_mix2obj"]
        end
    end

    subgraph Legacy_Analysis ["Analysis/legacy/"]
        direction LR
        subgraph OdorAnalysis ["Odor Analysis"]
            ODR["Odor_Segm/"]
            O2A["Odor2AFC/"]
            NL2["NL2AFC_MIX/"]
        end
        SC["state_colors_olf.m"]
    end

    subgraph Legacy_ExperPort ["ExperPort/legacy/"]
        direction LR
        subgraph Confirmed ["Confirmed Unused"]
            SS["start_script.m"]
            BI["beginit.m"]
        end
        subgraph Investigation ["Under Investigation"]
            ES["end_script.m"]
            RE["RExper.m"]
        end
    end

    %% Data file relationships
    subgraph Data_Files ["Critical Data Files"]
        direction LR
        OF["olfip.mat"]
        BG["bgnames.mat"]
        ON["OdorNames.mat"]
        OS["OdorSet.mat"]
    end

    %% Define relationships
    OF --> Olfactory
    BG --> OdorAnalysis
    ON --> AD
    OS --> OS2

    %% Define investigation relationships
    ES --> |"Referenced in"| Config["Config Files"]
    RE --> |"Referenced in"| Control["Control.m"]

    %% Style
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef investigation fill:#fff0f0,stroke:#c00,stroke-width:2px;
    classDef confirmed fill:#f0f0f0,stroke:#666,stroke-width:1px;
    classDef data fill:#e6ffe6,stroke:#060,stroke-width:2px;
    
    class Investigation investigation;
    class Confirmed confirmed;
    class Data_Files data;
```

## Investigation Status

The following diagram shows the current status of components under investigation:

```mermaid
graph LR
    subgraph Current_Status ["Component Status"]
        direction LR
        subgraph Ready_Remove ["Ready for Removal"]
            SS[start_script.m]
            BI[beginit.m]
            RP[remove_protocol_preferences.m]
            RE1[reporter.m]
            RB[RPbox_realbox.m]
            ER[ExperRPBox.m]
            ES1[ExperStart.m]
            EV[ExperValveCheck.m]
        end

        subgraph Need_Review ["Needs Investigation"]
            ES2[end_script.m]
            RX[RExper.m]
        end

        subgraph Keep_Active ["Preserved Data Files"]
            OF[olfip.mat]
            BG[bgnames.mat]
            ON[OdorNames.mat]
            OS[OdorSet.mat]
        end
    end

    %% Dependencies
    ES2 --> |"Config Dependencies"| CF[Configuration Files]
    RX --> |"Active Reference"| CT[Control.m]
    
    %% Data File Dependencies
    OF --> |"Used by Legacy"| LP[Legacy Protocols]
    BG --> |"Used by Legacy"| LA[Legacy Analysis]
    ON --> |"Used by Legacy"| LP
    OS --> |"Used by Legacy"| LP

    %% Style
    classDef ready fill:#e6ffe6,stroke:#060,stroke-width:1px;
    classDef review fill:#ffe6e6,stroke:#600,stroke-width:1px;
    classDef keep fill:#e6e6ff,stroke:#006,stroke-width:1px;
    
    class Ready_Remove ready;
    class Need_Review review;
    class Keep_Active keep;
```

## Component Status Details

### Confirmed Unused Components

These components have been confirmed as unused and moved to legacy folders:

1. **ExperPort Legacy** (Commit: 67d64ada04815d3e676f8d651ee90ac35883c4f9)
   - `start_script.m`
   - `beginit.m`
   - `remove_protocol_preferences.m`
   - `reporter.m`
   - `RPbox_realbox.m`
   - `ExperRPBox.m`
   - `ExperStart.m`
   - `ExperValveCheck.m`

### Under Investigation

Components requiring further analysis before final disposition:

1. **ExperPort Components**
   - `end_script.m`: Referenced in configuration files
   - `RExper.m`: Referenced in Control.m

### Preserved Data Files

Critical data files maintained despite legacy status of dependent components:

1. **olfip.mat Related** (Commit: 1c8b5d799155912251a1b6ac44881e3b8e00983d)
   - File preserved while 15 dependent protocol folders moved to legacy
   - May be needed by other components

2. **Other .mat Files** (Commit: b714b1848ac6d1bf70e666daa3f85338b403169f)
   - `bgnames.mat`
   - `OdorNames.mat`
   - `OdorSet.mat`
   - All preserved while dependent protocols moved to legacy

## Monitoring Plan

### Components Under Investigation

1. **end_script.m**
   - Monitor configuration file dependencies
   - Track any runtime references
   - Document any discovered usage patterns

2. **RExper.m**
   - Monitor Control.m interactions
   - Track any indirect dependencies
   - Document any system impacts

### Investigation Timeline

- Investigation Period: [Define specific timeframe]
- Review Points: [Define review schedule]
- Final Disposition Date: [Define target date]

## Rollback Procedures

For any needed rollbacks, follow this sequence (from newest to oldest):

1. ExperPort Files (67d64ada04815d3e676f8d651ee90ac35883c4f9)
2. Analysis/Protocol Files (b714b1848ac6d1bf70e666daa3f85338b403169f)
3. Olfip.mat Protocols (1c8b5d799155912251a1b6ac44881e3b8e00983d)
4. Newstartup Refactoring (60932b71d39853a25725e5c52ff2788942cbf243)
5. Unused Code Removal (5da710d356f8385dcfebd856b9ad3c57f2fc50b1)
6. Documentation/Paths (ce835f7a3a290c03fdd847480887898ce7cac6b6)

## Next Steps

1. **Investigation Tasks**
   - Complete analysis of `end_script.m` dependencies
   - Verify `RExper.m` usage patterns
   - Document any discovered integrations

2. **Documentation Updates**
   - Maintain investigation findings
   - Update status as components are cleared
   - Document any new dependencies discovered

3. **Final Disposition**
   - Plan for permanent removal of confirmed unused components
   - Document any components that need to be retained
   - Update system documentation accordingly
