# PowerShell profile — Windows counterpart of shell/shared.sh.

#-----PROMPT-----#
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
