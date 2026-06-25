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
  contain no personal name/identity. Real name/email live in a gitignored local
  file (`os/windows/profile.local.ps1`).

## Files

New (committed):

- `os/windows/personal.ps1` — personal-context overlay, name-free.
- `os/windows/work.ps1` — work-context overlay, name-free.
- `os/windows/profile.local.ps1.example` — template for the local identity file
  (placeholders only).
- `config/oh-my-posh/emodipt-extend.omp.json` — oh-my-posh theme, copied in-repo
  so the prompt is managed and portable (no literal name — fully templated).
- `.gitignore` (repo root) — ignores `os/windows/profile.local.ps1`.

Modified:

- `shell/profile.ps1` — add a "PROFILE OVERLAY" section.
- `README.md` — document the overlay in the layout table and "How it works".

## Mechanism

1. `$PROFILE` (symlink) → `shell/profile.ps1` on every PowerShell start; the
   existing prompt/modules/fnm sections are untouched.
2. The new section resolves the repo path the repo's way
   (`$env:DOTFILES_PATH` else `$HOME\.dotfiles`), reads `$env:DOTFILES_PROFILE`,
   **whitelists** it to `personal`/`work`, and dot-sources
   `os/windows/<profile>.ps1` if the file exists (guarded).
3. The chosen overlay dot-sources `os/windows/profile.local.ps1` if present —
   that gitignored file sets the real git identity (via `GIT_AUTHOR_*` /
   `GIT_COMMITTER_*` env vars, so nothing is written to the global gitconfig and
   identity stays scoped to the active context).
4. `$env:DOTFILES_PROFILE` unset → no overlay loads (shared profile only).

## Hide-the-name

Committed overlays carry only structure, comments, and env-driven logic — zero
personal data. The actual name/email exist solely in the untracked
`profile.local.ps1`; the committed `.example` shows the shape with placeholders.

## Selection setup (manual, documented)

Set once per machine:

```powershell
[Environment]::SetEnvironmentVariable('DOTFILES_PROFILE','work','User')   # or 'personal'
```

## Out of scope (YAGNI)

- No installer step to auto-set the env var.
- No auto-detection (domain join, hostname, etc.).
- No changes to the unix side.
