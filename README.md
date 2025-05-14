# BControl

BControl is a behavioral experimentation system that provides a comprehensive framework for running behavioral experiments. This system is designed to be flexible, extensible, and user-friendly, allowing researchers to implement and run various types of behavioral protocols.

## ⚠️ Recent Changes (May 2025)

We are currently undergoing a major cleanup and modernization effort. Please check the [Recent Refactoring Documentation](docs/recent-refactoring/README.md) for details about:

- Removal of legacy Perl scripts
- Protocols directory restructuring
- Documentation modernization
- ExperPort cleanup and optimization
- Testing status and next steps

These changes are being tracked in the `docs/recent-refactoring/` directory until they are fully tested and verified.

## Repository Structure

The repository is organized as follows:

```
BControl/
├── ExperPort/           # Core system files
├── Protocols/           # Main protocols directory
├── Bpod Protocols/      # Bpod-specific protocols
├── docs/               # Documentation
│   ├── guides/        # User guides and tutorials
│   ├── technical/     # Technical documentation
│   ├── hardware/      # Hardware-specific documentation
│   ├── architecture/  # System architecture documentation
│   ├── recent-refactoring/ # Recent changes documentation
│   └── old_docs/      # Legacy documentation (archived)
└── SoloData/          # Data storage (excluded from version control)
```

## Quick Start

Clone the repository and run the `svn_sparse_init.sh` sript from git bash:

```
bash svn_sparse_init.sh
```

This will initiate the SVN repository in `ratter`.

For more detailed instructions, follow our [giude](https://github.com/LIMLabSWC/limlab_documentation/blob/main/docs/how_to_set_up_a_rig_-_software.md) on setting up a rig.

## Documentation

### User Guides
- [Protocol Writer's Guide](docs/guides/protocol-writers-guide.md)
- [Solo Core Guide](docs/guides/solo-core-guide.md)
- [Water Valve Tutorial](docs/guides/water-valve-tutorial.md)

### Technical Documentation
- [System Architecture Overview](docs/architecture/system-overview.md)
- [FSM Documentation](docs/technical/fsm-documentation.md)
- [Staircase Algorithms](docs/technical/staircases.md)

### Hardware Documentation
- [LynxTrig Setup](docs/hardware/lynxtrig-setup.md)
- [Comedi Setup](docs/hardware/comedi-setup.md)

### Recent Changes
- [Refactoring Overview](docs/recent-refactoring/README.md)
- [Perl Scripts Removal](docs/recent-refactoring/perl-scripts-removal.md)
- [Protocols Restructuring](docs/recent-refactoring/protocols-restructuring.md)
- [Documentation Modernization](docs/recent-refactoring/documentation-modernization.md)
- [ExperPort Cleanup](docs/recent-refactoring/experport-cleanup.md)
