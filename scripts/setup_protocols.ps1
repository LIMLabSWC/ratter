# PowerShell script to setup Protocols directory structure
# This script ensures the Protocols directory exists in both locations

$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$experPortDir = Join-Path $rootDir "ExperPort"
$protocolsDir = Join-Path $rootDir "Protocols"
$experPortProtocolsDir = Join-Path $experPortDir "Protocols"

# Create Protocols directory in root if it doesn't exist
if (-not (Test-Path $protocolsDir)) {
    Write-Host "Creating Protocols directory in root..."
    New-Item -ItemType Directory -Path $protocolsDir | Out-Null
}

# Create ExperPort/Protocols directory if it doesn't exist
if (-not (Test-Path $experPortProtocolsDir)) {
    Write-Host "Creating ExperPort/Protocols directory..."
    New-Item -ItemType Directory -Path $experPortProtocolsDir | Out-Null
}

# Copy all files from root Protocols to ExperPort/Protocols
Write-Host "Copying protocol files..."
Get-ChildItem -Path $protocolsDir -Recurse | ForEach-Object {
    $targetPath = $_.FullName.Replace($protocolsDir, $experPortProtocolsDir)
    if (-not (Test-Path $targetPath)) {
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Path $targetPath | Out-Null
        } else {
            Copy-Item $_.FullName -Destination $targetPath
        }
    }
}

Write-Host "Protocols directory structure setup complete!" 