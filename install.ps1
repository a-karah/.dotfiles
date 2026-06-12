# Dotfiles installer for Windows (PowerShell 7).
# Usage: .\install.ps1 [-DryRun] [-SkipPackages]

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPackages
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/utils.ps1')

if (-not $DryRun -and -not (Test-SymlinkPrivilege)) {
    throw "Cannot create symlinks. Enable Developer Mode (Settings > Privacy & security > For developers) or run as administrator."
}

#-----SYMLINKS-----#
Get-Content (Join-Path $PSScriptRoot 'links.conf') | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $platform, $src, $target = $line -split '\s+', 3
    if ($platform -notin @('all', 'windows')) { return }
    $target = $target -replace '^~', $HOME
    New-Link -Source $src -Target $target -DryRun:$DryRun
}

# PowerShell profile — $PROFILE resolved at runtime (Documents may be
# OneDrive-redirected, so no static path is safe in links.conf).
New-Link -Source 'shell/profile.ps1' -Target $PROFILE -DryRun:$DryRun

#-----PACKAGES-----#
if (-not $SkipPackages) {
    if ($DryRun) {
        Write-Host "[dry-run] install windows packages"
    } else {
        . (Join-Path $PSScriptRoot 'os/windows/packages.ps1')
        Install-WindowsPackages
    }
}

#-----CLAUDE STATUSLINE-----#
Merge-ClaudeStatusLine -DryRun:$DryRun

Write-Host "Done."
