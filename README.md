## BControl - Behavioral Experimentation System

BControl is a sophisticated system designed for conducting behavioural experiments with high precision and flexibility. It aims to facilitate rapid interaction with experimental subjects, provide high-time-resolution measurements, and offer ease of programming and modification. For more information, check out the [Brody lab wiki](https://brodylabwiki.princeton.edu/bcontrol/index.php?title=General_overview).

## `ratter` Repository

This repository stores the BControl code for our high-throughput behavior training facility. Certain directories and files within the `ratter` repository are intentionally excluded from version control:

- The `/SoloData/` directory contains raw data and configuration files essential for running experiments. It is version-controlled with SVN and stored on our internal server.

- The `/ExperPort/Settings/Settings_Custom.conf` file contains rig-specific configurations. Instead, we provide `/ExperPort/Settings/_Settings_Custom.conf`, which is a template. After downloading, users should rename it to `Settings_Custom.conf` and add their rig-specific settings.

- The `/PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat` file stores hostnames, users, and passwords. It is version-controlled with SVN and stored on our internal server.

## Quick Start

Clone the repository and run the `svn_sparse_init.sh` sript from git bash:

```
bash svn_sparse_init.sh
```

This will initiate the SVN repository in `ratter`.

For more detailed instructions, follow our [giude](https://github.com/LIMLabSWC/limlab_documentation/blob/main/docs/how_to_set_up_a_rig_-_software.md) on setting up a rig.