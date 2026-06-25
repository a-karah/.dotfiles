# Windows (winget) package installation.

# Confirm-Install: y/n prompt before installing $Name (default yes). When the
# session can't prompt (non-interactive), default to yes so unattended runs keep
# installing everything.
function Confirm-Install {
    param([string]$Name)
    $opts = [System.Management.Automation.Host.ChoiceDescription[]]@(
        (New-Object System.Management.Automation.Host.ChoiceDescription '&yes'),
        (New-Object System.Management.Automation.Host.ChoiceDescription '&no')
    )
    try {
        return ($Host.UI.PromptForChoice('Packages', "Install $Name?", $opts, 0) -eq 0)
    } catch {
        Write-Host "  $Name (non-interactive — installing)"
        return $true
    }
}

# Update-SessionPath: pull any persisted (Machine/User) PATH entries into this
# session without clobbering session-only ones - so commands winget just added
# (its Links shims) resolve immediately, no shell restart needed.
function Update-SessionPath {
    $have = $env:Path -split ';'
    $persisted = @(
        [Environment]::GetEnvironmentVariable('Path','Machine'),
        [Environment]::GetEnvironmentVariable('Path','User')
    ) -join ';'
    foreach ($d in ($persisted -split ';')) {
        if ($d -and ($have -notcontains $d)) { $env:Path += ';' + $d; $have += $d }
    }
}

# Add-UserPathEntry: idempotently add a directory to the persisted User PATH and
# to this session - so a tool whose winget installer skipped PATH (e.g. starship,
# which needs elevation to register its Program Files bin) is usable right away.
function Add-UserPathEntry {
    param([string]$Dir)
    $user = [Environment]::GetEnvironmentVariable('Path','User')
    if (($user -split ';') -notcontains $Dir) {
        $user = if ([string]::IsNullOrWhiteSpace($user)) { $Dir } else { $user.TrimEnd(';') + ';' + $Dir }
        [Environment]::SetEnvironmentVariable('Path', $user, 'User')
    }
    if (($env:Path -split ';') -notcontains $Dir) { $env:Path = $env:Path.TrimEnd(';') + ';' + $Dir }
}

function Install-WindowsPackages {
    param([switch]$DryRun)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found; skipping packages"
        return
    }
    $packages = @(
        @{ Cmd = 'oh-my-posh'; Id = 'JanDeDobbeleer.OhMyPosh' },
        @{ Cmd = 'starship';   Id = 'Starship.Starship'; Bin = 'C:\Program Files\starship\bin' },
        @{ Cmd = 'jq';         Id = 'jqlang.jq' },
        @{ Cmd = 'wget';       Id = 'JernejSimoncic.Wget' } # NB: under PS5.1 'wget' aliases Invoke-WebRequest; we target PS7 where the alias is gone
    )
    # Only offer packages that aren't already present.
    $missing = @($packages | Where-Object { -not (Get-Command $_.Cmd -ErrorAction SilentlyContinue) })
    if (-not $missing) { Write-Host "packages: all present"; return }

    $i = 0
    foreach ($p in $missing) {
        $i++
        if ($DryRun) { Write-Host "[dry-run] would offer $($p.Cmd) ($($p.Id))"; continue }
        if (-not (Confirm-Install $p.Cmd)) { Write-Host "skipped $($p.Cmd)"; continue }
        # Prominent banner so the package is obvious amid winget's own output.
        Write-Host ""
        Write-Host "==> [$i/$($missing.Count)] installing $($p.Cmd) ($($p.Id))" -ForegroundColor Cyan
        winget install --id $p.Id -e --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "winget install $($p.Id) exited with $LASTEXITCODE"
            continue
        }
        # winget may persist PATH (its Links shims) without telling this session;
        # refresh, then make sure the command actually resolves - adding a known
        # bin to User PATH when it doesn't (e.g. starship under an unelevated run).
        Update-SessionPath
        if (Get-Command $p.Cmd -ErrorAction SilentlyContinue) {
            Write-Host "    done: $($p.Cmd)" -ForegroundColor Green
        } elseif ($p.Bin -and (Test-Path $p.Bin)) {
            Add-UserPathEntry $p.Bin
            Write-Host "    done: $($p.Cmd) (added $($p.Bin) to PATH)" -ForegroundColor Green
        } else {
            Write-Warning "$($p.Cmd) installed but not on PATH yet - open a new shell to use it"
        }
    }
}
