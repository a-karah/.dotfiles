# PowerShell profile — Windows counterpart of shell/shared.sh.
# Everything is guarded: machines without a tool just skip it.

# Repo root (mirrors the unix DOTFILES_PATH convention).
$DotfilesPath = if ($env:DOTFILES_PATH) { $env:DOTFILES_PATH } else { Join-Path $HOME '.dotfiles' }

#-----PROMPT-----#
# oh-my-posh is the prompt of choice on Windows; starship is the fallback
# (and the prompt used by the bash/zsh side of these dotfiles). The theme is
# managed in-repo; fall back to the bundled copy if the checkout is missing.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $poshTheme = Join-Path $DotfilesPath 'config\oh-my-posh\emodipt-extend.omp.json'
    if (-not (Test-Path $poshTheme)) { $poshTheme = Join-Path $env:POSH_THEMES_PATH 'emodipt-extend.omp.json' }
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
# $env:DOTFILES_PROFILE selects them. Set it once per machine, e.g.:
#   [Environment]::SetEnvironmentVariable('DOTFILES_PROFILE','work','User')
# Unset -> shared profile only (no overlay, no guessing).
$dotfilesProfile = $env:DOTFILES_PROFILE
if ($dotfilesProfile -in @('personal', 'work')) {
    $overlay = Join-Path $DotfilesPath "os\windows\$dotfilesProfile.ps1"
    if (Test-Path $overlay) { . $overlay }
}
