# PowerShell profile — Windows counterpart of shell/shared.sh.
# Everything is guarded: machines without a tool just skip it.

#-----PROMPT-----#
# oh-my-posh is the prompt of choice on Windows; starship is the fallback
# (and the prompt used by the bash/zsh side of these dotfiles).
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\emodipt-extend.omp.json" | Invoke-Expression
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
