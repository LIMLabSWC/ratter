# BControl

**BControl** is a behavioral experimentation system that provides a flexible and extensible framework for running behavioral protocols. It is designed to support a variety of experiments with user-friendly configuration and robust MATLAB-based components.

## ⚠️ Recent Changes (May 2025)

We are undergoing a major modernization effort. Please see the [Recent Refactoring Overview](docs/recent-refactoring/README.md) for details, including:

- Removal of legacy Perl scripts
- Protocol directory restructuring
- Documentation modernization
- ExperPort cleanup and optimization
- Current testing status and next steps

## Repository Structure

```text
BControl/
├── ExperPort/             # Core system files
├── Protocols/             # Main protocols directory
├── BpodProtocols/         # Bpod-specific protocols
├── docs/                  # Documentation
│   ├── guides/            # User guides and tutorials
│   ├── technical/         # Technical documentation
│   ├── hardware/          # Hardware-related setup
│   ├── architecture/      # System design and history
│   ├── recent-refactoring/# Refactoring logs and plans
│   ├── future_development/# Ideas and roadmap
│   └── old_docs/          # Archived legacy documentation
└── SoloData/              # Local data storage (excluded from version control)

```

## Repository Usage Notes

This repository hosts the **BControl** codebase for our high-throughput behavior training facility. Some components are excluded from Git version control by design:

- `/SoloData/`
  Contains raw data and rig-specific configuration files.
  ➤ Version-controlled with **SVN** and stored on our internal server.

- `/ExperPort/Settings/Settings_Custom.conf`
  Contains per-rig configuration settings.
  ➤ Instead, we provide a template:
  `/ExperPort/Settings/_Settings_Custom.conf`
  ➤ After cloning, users should rename this file and customize it for their rig.

- `/PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat`
  Stores hostnames, users, and passwords.
  ➤ This file is **version-controlled with SVN** and stored internally.

## Quick Start

### 1. Clone the Repository

```bash
git clone git@github.com:LIMLabSWC/ratter.git
```

### 2. Initialize the SVN Repository

```bash
bash svn_sparse_init.sh
```

This sets up the sparse SVN checkout within the `ratter` directory.

### 3. Configure Your Rig

Copy and rename the default config file:

```bash
cp ExperPort/Settings/_Settings_Custom.conf ExperPort/Settings/Settings_Custom.conf
```

Then edit it with your rig-specific settings.

> ℹ️ **Info:**  
See our [rig setup guide](https://github.com/LIMLabSWC/limlab_documentation/blob/main/docs/how_to_set_up_a_rig_-_software.md) for detailed instructions.

## Development and Contribution

**BControl** is built on legacy MATLAB code and maintained through incremental
patches and continuous development. Some updates are cosmetic, while others
introduce core functionality.

We welcome contributions to help modernize and improve the system. You can:

- Fix small issues
- Implement proposed improvements
- Join ongoing discussions

See [future development plans](docs/future_development/README.md) for active proposals.

### Contribution Guidelines

- The `main` branch is protected—create a feature branch for your work.
- Coordinate major changes with the team.
- Document any changes and update relevant planning documents.
- Submit a pull request when ready for review.

## Documentation

### Guides

- [Protocol Writer's Guide](docs/guides/protocol-writers-guide.md)
- [Solo Core Guide](docs/guides/solo-core-guide.md)
- [Water Valve Tutorial](docs/guides/water-valve-tutorial.md)

### Technical References

- [Finite State Machine (FSM) Documentation](docs/technical/fsm-documentation.md)
- [Staircase Algorithms](docs/technical/staircases.md)
- [SVN Update Process](docs/technical/svn_update_process.md)

### Hardware Setup

- [LynxTrig Setup](docs/hardware/lynxtrig-setup.md)
- [Comedi Setup](docs/hardware/comedi-setup.md)

### System Architecture

- [System Overview](docs/architecture/system-overview.md)
- [System Architecture](docs/architecture/system-architecture.md)
- [Legacy Architecture Notes](docs/architecture/legacy-architecture.md)

### Refactoring

- [Overview](docs/recent-refactoring/README.md)
- [ExperPort Cleanup](docs/recent-refactoring/experport-cleanup.md)
- [Perl Scripts Removal](docs/recent-refactoring/perl-scripts-removal.md)
- [Protocols Restructuring](docs/recent-refactoring/protocols-restructuring.md)
- [Documentation Modernization](docs/recent-refactoring/documentation-modernization.md)
