# PowerShell profile — Windows counterpart of shell/shared.sh.
# Everything is guarded: machines without a tool just skip it.

# Repo root (mirrors the unix DOTFILES_PATH convention).
$DotfilesPath = if ($env:DOTFILES_PATH) { $env:DOTFILES_PATH } else { Join-Path $HOME '.dotfiles' }

#-----PROMPT-----#
# oh-my-posh is the prompt of choice on Windows; starship is the fallback
# (and the prompt used by the bash/zsh side of these dotfiles). Themes are
# managed in-repo, one folder per profile (config/oh-my-posh/<profile>); the
# active profile's *.omp.json is used, falling back to the bundled theme.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $poshProfile = if ($env:DOTFILES_PROFILE -in @('personal', 'work')) { $env:DOTFILES_PROFILE } else { 'personal' }
    $poshTheme = Get-ChildItem (Join-Path $DotfilesPath "config\oh-my-posh\$poshProfile") -Filter *.omp.json -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $poshTheme) { $poshTheme = Join-Path $env:POSH_THEMES_PATH 'emodipt-extend.omp.json' }
    oh-my-posh init pwsh --config $poshTheme | Invoke-Expression
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

#-----MODULES-----#
if (Get-Module -ListAvailable git-aliases) {
    Import-Module git-aliases -DisableNameChecking
}

#-----NODE (fnm)-----#
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

#-----PROFILE OVERLAY (personal | work)-----#
# Context-specific settings live in os/windows/<profile>.ps1 and load only when
# $env:DOTFILES_PROFILE selects them. Pick with Set-DotfilesProfile (below);
# unset -> shared profile only (no overlay, no guessing).
$dotfilesProfile = $env:DOTFILES_PROFILE
if ($dotfilesProfile -in @('personal', 'work')) {
    $overlay = Join-Path $DotfilesPath "os\windows\$dotfilesProfile.ps1"
    if (Test-Path $overlay) { . $overlay }
}

# Set-DotfilesProfile [personal|work] — persist the choice for this user and
# reload the current shell. No argument => pick interactively.
function Set-DotfilesProfile {
    [CmdletBinding()]
    param([ValidateSet('personal', 'work')][string]$Name)

    if (-not $Name) {
        $options = [System.Management.Automation.Host.ChoiceDescription[]]@(
            (New-Object System.Management.Automation.Host.ChoiceDescription '&personal'),
            (New-Object System.Management.Automation.Host.ChoiceDescription '&work')
        )
        $current = if ($env:DOTFILES_PROFILE -eq 'work') { 1 } else { 0 }
        $Name = @('personal', 'work')[
            $Host.UI.PromptForChoice('Dotfiles profile', 'Which profile should this machine use?', $options, $current)
        ]
    }

    [Environment]::SetEnvironmentVariable('DOTFILES_PROFILE', $Name, 'User')
    $env:DOTFILES_PROFILE = $Name
    Write-Host "dotfiles profile -> $Name (reloading shell)"
    if (Test-Path $PROFILE) { . $PROFILE }
}
