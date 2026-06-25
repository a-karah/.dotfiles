# Windows personal/work PowerShell profiles

**Date:** 2026-06-25

## Goal

Split the Windows PowerShell config into a shared base plus two interchangeable
context overlays — **personal** and **work** — so identity and settings are kept
separate per machine. Mirrors the existing macOS pattern (`shell/shared.sh` +
`os/macos/42.sh`).

## Decisions

- **Selection:** `$env:DOTFILES_PROFILE` (`personal` | `work`), set once per
  machine. No auto-detection — explicit only. Unset → shared profile only.
- **Tracking / hide-the-name:** `personal.ps1` and `work.ps1` are committed but
  contain no personal name/identity. Machine-private settings live in a
  gitignored local file (`os/windows/profile.local.ps1`); git name/email stay in
  the global gitconfig (the current environment already has them there).

## Files

New (committed):

- `os/windows/personal.ps1` — personal-context overlay, name-free.
- `os/windows/work.ps1` — work-context overlay, name-free.
- `os/windows/profile.local.ps1.example` — template for the local machine-private
  settings file (proxy/tokens/PATH); git name/email stay in the global gitconfig.
- `config/oh-my-posh/emodipt-extend.omp.json` — oh-my-posh theme, copied in-repo
  so the prompt is managed and portable (no literal name — fully templated).
- `.gitignore` (repo root) — ignores `os/windows/profile.local.ps1`.

Modified:

- `shell/profile.ps1` — load the overlay and define the `Set-DotfilesProfile`
  switcher.
- `lib/utils.ps1` — `Select-DotfilesProfile` (install-time prompt) and
  `Remove-DotfilesProfile` (clears the var on uninstall).
- `install.ps1` — prompt for the profile during setup; clear it on `-Uninstall`.
- `README.md` — document the overlay in the layout table and "How it works".

## Mechanism

1. `$PROFILE` (symlink) → `shell/profile.ps1` on every PowerShell start; the
   existing prompt/modules/fnm sections are untouched.
2. The new section resolves the repo path the repo's way
   (`$env:DOTFILES_PATH` else `$HOME\.dotfiles`), reads `$env:DOTFILES_PROFILE`,
   **whitelists** it to `personal`/`work`, and dot-sources
   `os/windows/<profile>.ps1` if the file exists (guarded).
3. The chosen overlay dot-sources `os/windows/profile.local.ps1` if present —
   that gitignored file holds machine-private settings (proxy, tokens, PATH).
   Git name/email are not managed here; they come from the global gitconfig.
4. `$env:DOTFILES_PROFILE` unset → no overlay loads (shared profile only).

## Hide-the-name

Committed overlays carry only structure, comments, and env-driven logic — zero
personal data. Anything machine-private (secrets, proxy) lives solely in the
untracked `profile.local.ps1`. Git name/email come from the global gitconfig,
not from committed files.

## Selection

On first run, `install.ps1` prompts for the profile (`Select-DotfilesProfile` in
`lib/utils.ps1`) and persists it to the user-scope env var — idempotent (skips
when already set or when the session can't prompt; `-DryRun` previews). To switch
later, `Set-DotfilesProfile [personal|work]` (defined in `shell/profile.ps1`, so
available in every shell) persists `$env:DOTFILES_PROFILE` and reloads the
current shell; with no argument it prompts. `install.ps1 -Uninstall` clears the
var. Unset → shared profile only.

## Out of scope (YAGNI)

- No auto-detection (domain join, hostname, etc.).
- No changes to the unix side.
