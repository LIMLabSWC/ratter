# Protocols Overview

This document provides a detailed summary of the protocols and related files in the `Protocols` directory. It is intended to help users understand the available behavioral and experimental protocols, as well as the organization and purpose of each folder and file.


## Directory Structure

- [Top-level Protocol Folders](#top-level-protocol-folders)
- [Top-level Protocol Files](#top-level-protocol-files)
- [Special Folders](#special-folders)
- [Notes on Protocol Organization](#notes-on-protocol-organization)


## Top-level Protocol Folders

### @ArpitSoundCalibration
- **Main file:** `ArpitSoundCalibration.m`
- **Description:** Protocol for sound calibration, likely used to calibrate auditory stimulus equipment for behavioral experiments.

### @ArpitSoundCatContinuous
- **Main files:** `ArpitSoundCatContinuous.m`, `SideSection.m`, `StimulatorSection.m`
- **Description:** Implements a continuous sound categorization task, with supporting sections for stimulus delivery and side management.

### @CalibrationMeister
- **Main files:** `CalibrationMeister.m`, `TableSection.m`, `calcValvestoCalibrate.m`, `setDefaultPulseTime.m`, `updateCalibrationStatusLabel.m`
- **Description:** Protocol for managing and automating calibration routines, with helper scripts for valve calibration and pulse timing.

### @TaskSwitch4
- **Main files:** `TaskSwitch4.m`, `HistorySection.m`, `StimulusSection.m`, `TrainingSection.m`, and others
- **Description:** Implements a task-switching behavioral experiment, with sections for stimulus control, training, and history tracking.

### @ArpitCentrePokeTraining
- **Main files:** `ArpitCentrePokeTraining.m`, `ArpitCentrePokeTrainingSMA.m`, `ArpitCentrePokeTraining_SessionDefinition_AutoTrainingStages.m`, and multiple section/helper files
- **Description:** Protocol for center poke training, including session management, performance tracking, and auto-training stages.

### @SoundCalibration
- **Main file:** `SoundCalibration.m`, `private/`
- **Description:** Protocol for calibrating sound output, with private helper functions.

### @SoundCatContinuous
- **Main files:** `SoundCatContinuous.m`, `AntibiasSectionAthena.m`, `AthenaSMA_aa.m`, `DelayComp.m`, `LOGplotPairs.m`, `OverallPerformanceSection.m`, `PlayStimuli.m`, `ProduceNoiseStimuli.m`, `PunishmentSection.m`, `RewardsSection.m`, `SideSection.m`, `SoundCatSMA.m`, `SoundSection.m`, `StimulatorSection.m`, `StimulusSection.m`, and more
- **Description:** Comprehensive protocol for continuous sound categorization, including antibias, performance, and stimulus management sections.

### Other @protocol folders
- **Examples:** `@quadsampobj`, `@rigtestobj`, `@saja_detection`, `@saja_expectation`, `@saja_immersedcue`, `@saja_norush`, `@saja_reversal`, `@saja_twocontexts`, `@santiago_irrelclicksobj`, `@santiago_simple01obj`, `@santiago_twocontextobj`, `@solo_watervalve2obj`, `@synced_durationobj`, `@templateobj`, `@util_compare`, `@odorsegm3obj`
- **Description:** Each folder contains protocol object code and helper files for specific behavioral or experimental protocols, often with modular section files for different aspects of the experiment (e.g., stimulus, reward, state matrix, performance tracking).

### maria_protocol
- **Main files:** `MariaProtocol.m`, `StateMatrixSection.m`, `myprot.m`, and a subfolder `@myprot`
- **Description:** Implements a specific protocol with modular code, possibly for a particular experimenter or project.


## Top-level Protocol Files

These are standalone protocol scripts, each typically implementing a full experiment or a major component of one:

- **settings_@ArpitCentrePokeTraining_experimenter_ratname_250506a.mat**: Settings file for a specific experiment/session.
- **santiago_irrelclicks.m, santiago_simple01.m, santiago_twocontext.m**: Protocol scripts for Santiago's experiments.
- **OneBank_2AFC.m, Operant.m, PitchSamp.m, Pitch_Disc.m, Pitch_Disc2.m, QuadSamp.m, QuadSamp3.m, RigTest.m, Solo_WaterValve2.m, Synced_Duration.m, Template.m, ToneSamp.m, Tone_Odor_2AFC.m, matt_Operant.m, Adil2AFC.m, Classical2AFC_Solo.m, Clickpattern.m, Dual_Disc.m, Duration_Disc.m, Flow_controller_calib.m, GF2AFC.m, GFOperant.m, LocSamp6.m, LocSampTemplate.m, LocSamp_Child.m, Masa_Delay.m, Masa_Operant.m, Masa_Switch.m, Mix2AFC.m, Multipokes.m, Multipokes2.m, NL2AFC.m, NL2AFC_MIX.m, NL2AFC_MIX2.m, NL2AFC_airMIX.m, NL_OdorSamp.m, NL_OdorSamp2.m, Newclassical.m, OdorSegm.m, OdorSegm2.m, OdorSegm3.m, Odor_Test.m, Odor_Test2.m, Odorsamp.m**: Protocol scripts for a wide variety of behavioral tasks, including two-alternative forced choice (2AFC), operant conditioning, discrimination, sampling, and more.
- **PPfilter.mat, PPfilter_left.mat, PPfilter_right.mat**: MAT files containing filter coefficients or data, likely for signal processing in experiments.
- **RM1Box.c.txt, RM1Box.pdf, RM1Box.rco, RM1Box.rpx**: Files related to the RM1Box hardware or software, including code, documentation, and configuration.
- **XPding88200.wav**: A sound file, likely used as an auditory stimulus in experiments.
- **Old_Protocol_List.txt**: A text file listing old protocols, possibly for reference or migration purposes.
- **OdorNames.mat**: A MAT file with odor names, likely used in olfactory experiments.


## Special Folders

### OldProtocols
- **Contents:** Numerous `.m` files (e.g., `Probsamp.m`, `SeqDiscSamp10.m`, `Sigmoidsamp10.m`, `Tone2AFC_100ms_HiLo.m`, `ToneLoc2AFC.m`, `Operant.m`, etc.)
- **Description:** A collection of old or deprecated protocol scripts, not organized in the `@protocolname` folder style. These are not listed in the main protocol menu and are retained for reference or legacy use.

### protocol_backup
- **Contents:** `Sigmoidsamp6.m`, `Tone_Odor_2AFC_forMus.m`
- **Description:** Backup copies of protocol scripts, possibly for archival or recovery purposes.


## Notes on Protocol Organization

- Folders starting with `@` are MATLAB class folders, each typically representing a protocol or a major protocol component.
- Top-level `.m` files are standalone protocol scripts.
- Section files (e.g., `SideSection.m`, `StimulusSection.m`) modularize protocol logic for easier maintenance and reuse.
- The `OldProtocols` and `protocol_backup` folders are for archival and do not appear in the main protocol selection menu.
