# Setup Scripts

This directory contains scripts to set up the BControl environment.

## First-time Setup

After cloning the repository, run:

```powershell
.\scripts\setup_hooks.ps1
```

This will install the necessary Git hooks to maintain the Protocols directory structure.

## Manual Setup

If you need to manually set up the Protocols directory structure, run:

```powershell
.\scripts\setup_protocols.ps1
```

## What These Scripts Do

- `setup_hooks.ps1`: Installs Git hooks that automatically maintain the Protocols directory structure
- `setup_protocols.ps1`: Creates and maintains the Protocols directory in both the root and ExperPort locations

The scripts ensure that BControl can find the Protocols directory in its expected location while maintaining a single source of truth in the root directory. 