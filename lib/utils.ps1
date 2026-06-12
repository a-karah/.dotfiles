# Shared helpers for install.ps1.

$script:DotfilesPath = Split-Path -Parent $PSScriptRoot   # lib/.. = repo root

function Test-SymlinkPrivilege {
    $probe = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-symlink-probe"
    try {
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        # target need not exist; this only tests the privilege
        New-Item -ItemType SymbolicLink -Path $probe -Target "$probe.target" -ErrorAction Stop | Out-Null
        Remove-Item $probe -Force
        return $true
    } catch {
        return $false
    }
}

# New-Link: same semantics as link_file in lib/utils.sh —
# our symlink -> refresh; real file or foreign link -> back up to .bak first.
function New-Link {
    param([string]$Source, [string]$Target, [switch]$DryRun)
    $src = Join-Path $script:DotfilesPath $Source
    if (-not (Test-Path $src)) { throw "New-Link: missing source $src" }
    if ($DryRun) { Write-Host "[dry-run] link $Target -> $src"; return }
    $dir = Split-Path -Parent $Target
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $existing = Get-Item $Target -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq 'SymbolicLink') {
        if ("$($existing.Target)".StartsWith($script:DotfilesPath)) {
            Remove-Item $Target -Force          # ours — refresh
        } else {
            $bak = "$Target.bak"
            if (Test-Path $bak) { $bak = "$bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" }
            Move-Item $Target $bak -Force       # foreign symlink — preserve it
        }
    } elseif ($existing) {
        $bak = "$Target.bak"
        if (Test-Path $bak) {   # never clobber an earlier backup
            $bak = "$bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
        }
        Move-Item $Target $bak -Force
    }
    New-Item -ItemType SymbolicLink -Path $Target -Target $src | Out-Null
    Write-Host "linked $Target -> $src"
}

# Merge the statusLine block into ~/.claude/settings.json without touching
# other keys. Windows quirk: the command string must contain a RESOLVED
# path ($HOME literal would only expand under a POSIX shell).
function Merge-ClaudeStatusLine {
    param([switch]$DryRun)
    $settingsPath = Join-Path $HOME ".claude\settings.json"
    $desired = 'bash "{0}/.claude/statusline.sh"' -f ($HOME -replace '\\', '/')
    $settings = if (Test-Path $settingsPath) {
        Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else { [pscustomobject]@{} }
    if ($settings.statusLine -and $settings.statusLine.command -eq $desired) { return }
    if ($DryRun) { Write-Host "[dry-run] wire statusLine into $settingsPath"; return }
    $statusLine = [pscustomobject]@{ type = 'command'; command = $desired }
    if ($settings.PSObject.Properties['statusLine']) {
        $settings.statusLine = $statusLine
    } else {
        $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine
    }
    New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
    $settings | ConvertTo-Json -Depth 16 | Set-Content $settingsPath
    Write-Host "wired statusLine into $settingsPath"
}
