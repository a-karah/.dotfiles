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

# Remove-Link: inverse of New-Link —
# our symlink -> remove it, then restore $Target.bak if present;
# real file or foreign link -> leave it alone.
function Remove-Link {
    param([string]$Target, [switch]$DryRun)
    if ($DryRun) { Write-Host "[dry-run] unlink $Target"; return }
    $existing = Get-Item $Target -ErrorAction SilentlyContinue
    if (-not $existing) { return }
    if ($existing.LinkType -ne 'SymbolicLink') {
        Write-Host "skip $Target — real file, not a link we made"; return
    }
    if (-not "$($existing.Target)".StartsWith($script:DotfilesPath)) {
        Write-Host "skip $Target — foreign link (-> $($existing.Target))"; return
    }
    Remove-Item $Target -Force
    Write-Host "removed $Target"
    $bak = "$Target.bak"
    if (Test-Path $bak) {
        Move-Item $bak $Target -Force
        Write-Host "restored $Target from $bak"
    }
}

# Inverse of Merge-ClaudeStatusLine: drop the statusLine block if (and only if)
# it points at our statusline, leaving other settings untouched. If that empties
# the file, remove it — the file was ours to begin with.
function Remove-ClaudeStatusLine {
    param([switch]$DryRun)
    $settingsPath = Join-Path $HOME ".claude\settings.json"
    if (-not (Test-Path $settingsPath)) { return }
    $desired = 'bash "{0}/.claude/statusline.sh"' -f ($HOME -replace '\\', '/')
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if (-not ($settings.statusLine -and $settings.statusLine.command -eq $desired)) { return }
    if ($DryRun) { Write-Host "[dry-run] remove statusLine from $settingsPath"; return }
    $settings.PSObject.Properties.Remove('statusLine')
    if (@($settings.PSObject.Properties).Count -eq 0) {
        Remove-Item $settingsPath -Force
        Write-Host "removed statusLine; deleted now-empty $settingsPath"
    } else {
        $settings | ConvertTo-Json -Depth 16 | Set-Content $settingsPath
        Write-Host "removed statusLine from $settingsPath"
    }
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

# Select-DotfilesProfile: first-run prompt to pick the personal/work profile and
# persist it to the user-scope DOTFILES_PROFILE env var. Idempotent — skips when
# already set, and skips gracefully when the session can't prompt.
function Select-DotfilesProfile {
    param([switch]$DryRun)
    $current = [Environment]::GetEnvironmentVariable('DOTFILES_PROFILE', 'User')
    if ($current -in @('personal', 'work')) {
        Write-Host "profile: $current (already set — change with Set-DotfilesProfile)"
        return
    }
    $options = [System.Management.Automation.Host.ChoiceDescription[]]@(
        (New-Object System.Management.Automation.Host.ChoiceDescription '&personal'),
        (New-Object System.Management.Automation.Host.ChoiceDescription '&work'),
        (New-Object System.Management.Automation.Host.ChoiceDescription '&skip', 'decide later')
    )
    try {
        $choice = $Host.UI.PromptForChoice('Dotfiles profile', 'Which profile is this machine?', $options, 0)
    } catch {
        Write-Host "profile: not set (non-interactive — run Set-DotfilesProfile later)"
        return
    }
    if ($choice -eq 2) {
        Write-Host "profile: skipped (set later with Set-DotfilesProfile)"
        return
    }
    $name = @('personal', 'work')[$choice]
    if ($DryRun) { Write-Host "[dry-run] set DOTFILES_PROFILE=$name (User scope)"; return }
    [Environment]::SetEnvironmentVariable('DOTFILES_PROFILE', $name, 'User')
    $env:DOTFILES_PROFILE = $name
    Write-Host "profile: $name (open a new shell to apply)"
}

# Inverse of Select-DotfilesProfile: clear the user-scope DOTFILES_PROFILE var.
function Remove-DotfilesProfile {
    param([switch]$DryRun)
    $current = [Environment]::GetEnvironmentVariable('DOTFILES_PROFILE', 'User')
    if (-not $current) { return }
    if ($DryRun) { Write-Host "[dry-run] clear DOTFILES_PROFILE (was $current)"; return }
    [Environment]::SetEnvironmentVariable('DOTFILES_PROFILE', $null, 'User')
    Write-Host "cleared DOTFILES_PROFILE (was $current)"
}
