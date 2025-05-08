# BControl - Behavioral Experimentation System

BControl is a sophisticated system designed for conducting behavioural experiments with high precision and flexibility. It aims to facilitate rapid interaction with experimental subjects, provide high-time-resolution measurements, and offer ease of programming and modification. For more information, check out the [Brody lab wiki](https://brodylabwiki.princeton.edu/bcontrol/index.php?title=General_overview).

## Repository Structure

This repository stores the BControl code for our high-throughput behavior training facility. Certain directories and files are intentionally excluded from version control:

- The `/SoloData/` directory contains raw data and configuration files essential for running experiments. It is version-controlled with SVN and stored on our internal server.

- The `/ExperPort/Settings/Settings_Custom.conf` file contains rig-specific configurations. Instead, we provide `/ExperPort/Settings/_Settings_Custom.conf`, which is a template. After downloading, users should rename it to `Settings_Custom.conf` and add their rig-specific settings.

- The `/PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat` file stores hostnames, users, and passwords. It is version-controlled with SVN and stored on our internal server.

## Documentation

### Table of Contents

1. [Architecture Overview](docs/architecture/system-overview.md)
   - System Components
   - Data Flow
   - Hardware Integration

2. [User Guides](docs/guides/)
   - [Protocol Writer's Guide](docs/guides/protocol-writers-guide.md)
   - [Solo Core Guide](docs/guides/solo-core-guide.md)
   - [Water Valve Tutorial](docs/guides/water-valve-tutorial.md)

3. [Hardware Setup](docs/hardware/)
   - [LynxTrig Setup](docs/hardware/lynxtrig-setup.md)
   - [Comedi Setup](docs/hardware/comedi-setup.md)

4. [Technical Documentation](docs/technical/)
   - [Staircase Algorithms](docs/technical/staircases.md)
   - [FSM Documentation](docs/technical/fsm-documentation.md)

### Quick Start

1. Install the required hardware components
2. Set up the LynxTrig system
3. Configure Comedi for hardware triggering
4. Start the ExperPort system

For detailed instructions, please refer to the specific sections in the documentation.

## Support

For technical support or questions, please contact the system administrators.
