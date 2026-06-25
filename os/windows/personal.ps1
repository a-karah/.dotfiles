# Personal profile overlay — loaded by shell/profile.ps1 when
# $env:DOTFILES_PROFILE = 'personal'. No personal name/identity here:
# real values live in os/windows/profile.local.ps1 (gitignored).

#-----IDENTITY / MACHINE-LOCAL-----#
# Git name/email and any machine-private values come from the untracked
# local file. See profile.local.ps1.example for the shape.
$DotfilesPath = if ($env:DOTFILES_PATH) { $env:DOTFILES_PATH } else { Join-Path $HOME '.dotfiles' }
$localProfile = Join-Path $DotfilesPath 'os\windows\profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }

#-----PERSONAL SETTINGS-----#
# Aliases / env that should apply only on personal machines go here.
