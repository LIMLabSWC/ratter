## BControl - Behavioral Experimentation System

BControl is a sophisticated system designed for conducting behavioural experiments with high precision and flexibility. It aims to facilitate rapid interaction with experimental subjects, provide high-time-resolution measurements, and offer ease of programming and modification. For more information, check out the [Brody lab wiki](https://brodylabwiki.princeton.edu/bcontrol/index.php?title=General_overview).

## `ratter` Repository

This repository stores the BControl code for our high-throughput behavior training facility. Certain directories and files within the `ratter` repository are intentionally excluded from version control:

- The `/SoloData/` directory contains raw data and configuration files essential for running experiments. It is version-controlled with SVN and stored on our internal server.

- The `/ExperPort/Settings/Settings_Custom.conf` file contains rig-specific configurations. Instead, we provide `/ExperPort/Settings/_Settings_Custom.conf`, which is a template. After downloading, users should rename it to `Settings_Custom.conf` and add their rig-specific settings.

- The `/PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat` file stores hostnames, users, and passwords. It is version-controlled with SVN and stored on our internal server.


## Setting Up Connection with GitHub on Windows 7 Machines

If you're encountering an issue where TLS 1.2 is not available on your Windows 7 machine, follow these steps to manually enable TLS 1.2 via the registry:

1. Press `Win + R`, type `regedit`, and press Enter to open the Registry Editor.
2. Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols`.
3. Create the following keys if they do not exist: `TLS 1.2\Client` and `TLS 1.2\Server`.
4. Under `TLS 1.2\Client`, create a DWORD value named `DisabledByDefault` and set its value to `0`.
5. Also under `TLS 1.2\Client`, create another DWORD value named `Enabled` and set its value to `1`.
6. Repeat the process for `TLS 1.2\Server` if needed.
