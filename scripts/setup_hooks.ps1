# PowerShell script to install Git hooks
$rootDir = Split-Path -Parent $PSScriptRoot
$hooksDir = Join-Path $rootDir ".git" "hooks"
$scriptsDir = Join-Path $rootDir "scripts"

# Create hooks directory if it doesn't exist
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir | Out-Null
}

# Copy post-checkout hook
$hookContent = @"
#!/bin/sh
# Git post-checkout hook to setup Protocols directory structure

# Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "$(git rev-parse --show-toplevel)/scripts/setup_protocols.ps1"
"@

$hookContent | Out-File -FilePath (Join-Path $hooksDir "post-checkout") -Encoding ASCII 