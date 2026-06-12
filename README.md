# dotfiles

Cross-platform dotfiles for macOS (personal + 42 school), Linux/WSL, and Windows.
One repo, two installers, a single declarative link map.

## Quick start

**macOS / Linux / WSL**

```sh
git clone git@github.com:a-karah/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

**Windows (PowerShell 7, needs Developer Mode for symlinks)**

```powershell
git clone git@github.com:a-karah/.dotfiles.git $HOME\.dotfiles
cd $HOME\.dotfiles; .\install.ps1
```

Both installers are idempotent — re-run them any time. Flags: `--dry-run` /
`-DryRun` (print actions only), `--skip-packages` / `-SkipPackages` (links and
settings only).

## Layout

| Path | What lives there |
|---|---|
| `install.sh` / `install.ps1` | entry points (unix / Windows) |
| `links.conf` | declarative link map — `<platform> <repo-path> <target>` — read by both installers |
| `lib/` | helpers: platform detection, safe symlinking (`utils.sh`), PowerShell twins (`utils.ps1`) |
| `shell/` | `shared.sh` (aliases, env, starship — sourced by zsh *and* bash), thin `zshrc`/`bashrc`, `profile.ps1` |
| `config/` | shared configs: vim, tmux, ctags, alacritty, claude statusline |
| `os/macos/` | brew packages, `defaults.sh` (system prefs), launch agent, 42-school env (`42.sh`) |
| `os/linux/` | apt packages |
| `os/windows/` | winget packages |
| `fonts/` | Blex Mono Nerd Font |

Placement rule: shared → `config/` or `shell/shared.sh` · platform-specific →
`os/<platform>/` · shell-specific → `shell/<shell>rc`.

## How it works

- **Symlinks, not copies.** The installer links each `links.conf` row matching
  the current platform (`all`, `unix`, `macos`, `linux`, `windows`). Existing
  real files are preserved as `<name>.bak` (never clobbered — repeat backups
  get a timestamp suffix).
- **Shell layering.** `~/.zshrc` and `~/.bashrc` are thin: they source
  `shell/shared.sh` for everything common. Campus-specific config
  (`USER`/`MAIL`, goinfre brew PATH) lives in `os/macos/42.sh` and is only
  sourced on 42 machines (detected via `/goinfre`).
- **42 auto-bootstrap.** `/goinfre` gets wiped regularly, so on 42 machines the
  zshrc re-runs the (idempotent) installers on shell startup — homebrew into
  goinfre, packages, oh-my-zsh. Everywhere else, setup only happens when you
  run `./install.sh`.
- **Claude Code statusline.** `config/claude/statusline.sh` (model · effort ·
  context bar · rate-limit windows) is linked to `~/.claude/statusline.sh` and
  wired into `~/.claude/settings.json` by merging just the `statusLine` block —
  the rest of your settings is left alone.
- **Packages.** starship, jq, wget everywhere (brew / apt / winget);
  `dark-mode` on macOS. Missing package managers warn and continue — links
  always come first.

## Notes

- On Windows, run `install.ps1` — `install.sh` refuses to run under git-bash
  on purpose.
- Fresh personal Macs: install [Homebrew](https://brew.sh) first if you want
  the package step to do anything; oh-my-zsh is only auto-installed on 42
  machines.
- The macOS launch agent runs `~/.macos.sh` (system defaults) at login.
