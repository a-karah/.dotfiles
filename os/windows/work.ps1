# Work profile overlay — loaded by shell/profile.ps1 when
# $env:DOTFILES_PROFILE = 'work'. No personal name/identity here:
# real values live in os/windows/profile.local.ps1 (gitignored).

#-----MACHINE-LOCAL-----#
# Machine-private values (proxy, tokens, PATH) come from the untracked local
# file, if present. Git name/email stay in your global gitconfig. See
# profile.local.ps1.example for the shape.
$DotfilesPath = if ($env:DOTFILES_PATH) { $env:DOTFILES_PATH } else { Join-Path $HOME '.dotfiles' }
$localProfile = Join-Path $DotfilesPath 'os\windows\profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }

#-----WORK SETTINGS-----#
# Work-only aliases / env go here. Keep secrets in the local file, not here.
