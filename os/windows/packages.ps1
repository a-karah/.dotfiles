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

function Install-WindowsPackages {
    param([switch]$DryRun)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found; skipping packages"
        return
    }
    $packages = @(
        @{ Cmd = 'oh-my-posh'; Id = 'JanDeDobbeleer.OhMyPosh' },
        @{ Cmd = 'starship';   Id = 'Starship.Starship' },
        @{ Cmd = 'jq';         Id = 'jqlang.jq' },
        @{ Cmd = 'wget';       Id = 'JernejSimoncic.Wget' } # NB: under PS5.1 'wget' aliases Invoke-WebRequest; we target PS7 where the alias is gone
    )
    # Only offer packages that aren't already present.
    $missing = $packages | Where-Object { -not (Get-Command $_.Cmd -ErrorAction SilentlyContinue) }
    if (-not $missing) { Write-Host "packages: all present"; return }

    foreach ($p in $missing) {
        if ($DryRun) { Write-Host "[dry-run] would offer $($p.Id)"; continue }
        if (-not (Confirm-Install $p.Cmd)) { Write-Host "skipped $($p.Cmd)"; continue }
        Write-Host "Installing $($p.Id)"
        winget install --id $p.Id -e --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "winget install $($p.Id) exited with $LASTEXITCODE"
        }
    }
}
