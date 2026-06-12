# Windows (winget) package installation.

function Install-WindowsPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found; skipping packages"
        return
    }
    $packages = @(
        @{ Cmd = 'starship'; Id = 'Starship.Starship' },
        @{ Cmd = 'jq';       Id = 'jqlang.jq' },
        @{ Cmd = 'wget';     Id = 'JernejSimoncic.Wget' }
    )
    foreach ($p in $packages) {
        if (-not (Get-Command $p.Cmd -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $($p.Id)"
            winget install --id $p.Id -e --silent --accept-source-agreements --accept-package-agreements
        }
    }
}
