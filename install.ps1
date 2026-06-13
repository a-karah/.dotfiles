# Dotfiles installer for Windows (PowerShell 7).
# Usage: .\install.ps1 [-DryRun] [-SkipPackages] [-Uninstall]
#   -Uninstall  remove the symlinks/settings this script created (restoring
#               any .bak backups); installed packages are left in place.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPackages,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/utils.ps1')

# Removing symlinks needs no special privilege; only creating them does.
if (-not $DryRun -and -not $Uninstall -and -not (Test-SymlinkPrivilege)) {
    throw "Cannot create symlinks. Enable Developer Mode (Settings > Privacy & security > For developers) or run as administrator."
}

#-----SYMLINKS-----#
Get-Content (Join-Path $PSScriptRoot 'links.conf') | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $platform, $src, $target = $line -split '\s+', 3
    if ($platform -notin @('all', 'windows')) { return }
    $target = $target -replace '^~', $HOME
    if ($Uninstall) {
        Remove-Link -Target $target -DryRun:$DryRun
    } else {
        New-Link -Source $src -Target $target -DryRun:$DryRun
    }
}

# PowerShell profile — $PROFILE resolved at runtime (Documents may be
# OneDrive-redirected, so no static path is safe in links.conf).
if ($Uninstall) {
    Remove-Link -Target $PROFILE -DryRun:$DryRun
} else {
    New-Link -Source 'shell/profile.ps1' -Target $PROFILE -DryRun:$DryRun
}

#-----PACKAGES-----#
if ($Uninstall) {
    Write-Host "Leaving installed packages in place (uninstall does not remove them)."
} elseif (-not $SkipPackages) {
    if ($DryRun) {
        Write-Host "[dry-run] install windows packages"
    } else {
        . (Join-Path $PSScriptRoot 'os/windows/packages.ps1')
        Install-WindowsPackages
    }
}

#-----CLAUDE STATUSLINE-----#
if ($Uninstall) {
    Remove-ClaudeStatusLine -DryRun:$DryRun
} else {
    Merge-ClaudeStatusLine -DryRun:$DryRun
}

Write-Host $(if ($Uninstall) { "Uninstalled." } else { "Done." })
