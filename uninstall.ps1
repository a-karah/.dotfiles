# Dotfiles uninstaller for Windows (PowerShell 7).
# Removes the symlinks/settings install.ps1 created (restoring any .bak
# backups); installed packages are left in place.
# Usage: .\uninstall.ps1 [-DryRun]
#
# Thin wrapper over `install.ps1 -Uninstall`, which holds the shared link-map
# traversal and platform logic — kept here as a discoverable entry point.

[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'install.ps1') -Uninstall -DryRun:$DryRun
