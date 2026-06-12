# Cross-platform dotfiles reorganization — design

**Date:** 2026-06-12
**Status:** Approved

## Goal

Reorganize the dotfiles repo so one repository configures four environments —
macOS (personal), macOS (42 school), Linux (incl. WSL), and Windows
(PowerShell) — with a clear split between shared and platform-specific
settings, symlink-based deployment, and full package installation on every
platform.

## Problems with the current state

1. Bootstrap and shell config are entangled: `.zshrc` runs installers on
   every shell startup.
2. Two competing sync mechanisms (`copy_dotfiles` vs
   `create_symlink_to_dotfiles`); neither is fully wired up.
3. Dead/broken wiring: `env_vars.sh` is never sourced but defines
   `DOTFILES_PATH` which `install_functions.sh` uses; `BREW` defined twice.
4. Personal/machine data hardcoded in `.zshrc` (42 `USER`/`MAIL`, goinfre
   paths).
5. Everything assumes macOS; no platform dispatch.
6. No single entry point for a fresh machine.

## Decisions (user-confirmed)

- Platforms: macOS personal, macOS 42, Linux/WSL, Windows (PowerShell
  profile; WSL treated as Linux).
- Deployment: symlinks, driven by a declarative link map.
- 42 bootstrap: auto-run (idempotent) from shell startup **on 42 machines
  only** (detected via `[ -d /goinfre ]`); manual `./install.sh` everywhere
  else.
- Package installation in scope for all platforms: brew (macOS), apt
  (Linux), winget (Windows).
- Approach B chosen over (A) in-place platform guards and (C) GNU Stow.

## Repo layout

```
.dotfiles/
├── install.sh                  # entry point: macOS / Linux / WSL
├── install.ps1                 # entry point: Windows (PowerShell)
├── links.conf                  # declarative link map — single source of truth
├── lib/
│   ├── utils.sh                # detect_os, is_42, is_installed, link_file
│   └── utils.ps1               # New-Link, settings-merge helpers
├── shell/
│   ├── shared.sh               # aliases, env, PATH, starship init — zsh AND bash
│   ├── zshrc                   # thin: omz + sources shared.sh + 42 hook
│   ├── bashrc                  # thin: sources shared.sh
│   └── profile.ps1             # PowerShell profile: starship + aliases
├── config/
│   ├── vimrc, tmux.conf, ctags, alacritty.yml
│   └── claude/                 # statusline.sh + settings.json
├── os/
│   ├── macos/
│   │   ├── packages.sh         # brew (resolves 42-goinfre vs standard path)
│   │   ├── defaults.sh         # was .macos.sh
│   │   ├── 42.sh               # 42-only env: USER/MAIL, goinfre PATH, cclean, dark-mode
│   │   ├── com.user.loginscript.plist
│   │   └── ayu.itermcolors
│   ├── linux/packages.sh       # apt: starship, jq, wget
│   └── windows/packages.ps1    # winget: starship, jq, wget
└── fonts/                      # unchanged
```

Placement rule: shared → `config/` or `shell/shared.sh`; platform-specific →
`os/<platform>/`; shell-specific → `shell/<shell>rc`.

## Link map (`links.conf`)

Plain text, `#` comments, three whitespace-separated columns:
`<platform> <repo-path> <target>`. Platforms: `all`, `unix` (macos+linux),
`macos`, `linux`, `windows`.

```
unix    shell/zshrc                   ~/.zshrc
unix    shell/bashrc                  ~/.bashrc
unix    config/vimrc                  ~/.vimrc
unix    config/tmux.conf              ~/.tmux.conf
unix    config/ctags                  ~/.ctags
unix    config/alacritty.yml          ~/.config/alacritty/alacritty.yml
all     config/claude/statusline.sh   ~/.claude/statusline.sh
macos   os/macos/defaults.sh          ~/.macos.sh
```

Both installers parse this same file. Exception: `shell/profile.ps1 →
$PROFILE` is wired directly inside `install.ps1` because `$PROFILE` must be
resolved at runtime (Documents may be OneDrive-redirected).

## Shell config layering

- `shell/shared.sh`: LANG, `~/.local/bin` PATH, aliases, starship init
  (branches on `$ZSH_VERSION` / `$BASH_VERSION`). No installs, no
  machine-specific data.
- `shell/zshrc`: compfix guard, oh-my-zsh + plugins, sources `shared.sh`;
  then `if is_42; then source os/macos/42.sh && bootstrap_42; fi`.
- `shell/bashrc`: sources `shared.sh`.
- `os/macos/42.sh`: `USER`/`MAIL` exports, goinfre brew PATH, `cclean`
  alias, dark-mode activation. Sourced only on 42 machines.
- `bootstrap_42` (defined in `os/macos/42.sh`, reusing
  `os/macos/packages.sh`): idempotent installer chain (homebrew→goinfre,
  brew packages, oh-my-zsh, omz plugins) — fast no-ops when already
  installed.
- `shell/profile.ps1`: starship init for PowerShell + equivalent aliases.
  Parallel implementation, not a translation of shared.sh.

## Installers

### install.sh (macOS / Linux / WSL)

1. `set -euo pipefail`; source `lib/utils.sh`.
2. Detect platform from `uname` (Darwin→macos, Linux→linux). `DOTFILES_OS`
   env var overrides for testing.
3. Create symlinks from `links.conf` (rows matching `all`/`unix`/platform).
4. Run `os/$OS/packages.sh`.
5. Merge claude `statusLine` block into `~/.claude/settings.json` via jq
   (logic moves from `install_functions.sh`).
6. macOS only: install launch agent (copy plist to `~/Library/LaunchAgents`,
   `launchctl load`) — replaces `init_mac.sh`.
7. Flags: `--dry-run` prints planned actions without executing;
   `--skip-packages` runs links/settings only (used by sandbox tests).

### install.ps1 (Windows)

1. Dot-source `lib/utils.ps1`.
2. Check symlink privilege (Developer Mode or admin); fail early with a
   clear message if absent.
3. Create symlinks from `links.conf` (rows matching `all`/`windows`), plus
   `shell/profile.ps1 → $PROFILE`.
4. Run `os/windows/packages.ps1` (winget).
5. Merge claude `statusLine` via native ConvertFrom-Json/ConvertTo-Json (no
   jq dependency in the installer).
6. `-DryRun` switch mirrors `--dry-run`.

### Link safety

`link_file` / `New-Link`: if target is already a symlink to the repo → skip;
if target is a real file → back up to `<name>.bak`, then link. Parent
directories created as needed.

## Packages

| Package | macOS (brew) | Linux (apt) | Windows (winget) |
|---|---|---|---|
| starship | ✓ | ✓ (official installer script; apt version too old/absent) | ✓ |
| jq | ✓ | ✓ | ✓ |
| wget | ✓ | ✓ | ✓ |
| dark-mode | ✓ | — | — |

macOS brew path resolution: 42 machine → `/goinfre/$USER/homebrew/bin/brew`
(installing it there if missing); otherwise standard brew (`command -v brew`,
or `/opt/homebrew/bin/brew` / `/usr/local/bin/brew`).

## Migration table

| Current | Becomes |
|---|---|
| `.zshrc` | split → `shell/zshrc` + `shell/shared.sh` + `os/macos/42.sh` |
| `install_functions.sh` | split → `lib/utils.sh` + `os/macos/packages.sh` + `install.sh` |
| `utils.sh` | `lib/utils.sh`; `check_shasum` deleted (obsolete with symlinks) |
| `env_vars.sh` | deleted (dead code) |
| `init_mac.sh` | folded into `install.sh` macOS branch |
| `.macos.sh` | `os/macos/defaults.sh` |
| `copy_dotfiles()` | deleted |
| `create_symlink_to_dotfiles()` | replaced by links.conf-driven linking |
| `install_cleaner()` / Cleaner_42 | deleted (dead code, never called) |
| `.vimrc` / `.tmux.conf` / `.ctags` / `alacritty.yml` | `config/` (leading dots dropped) |
| `claude/` | `config/claude/` |
| `ayu Dark.itermcolors` | `os/macos/ayu.itermcolors` |
| `com.user.loginscript.plist` | `os/macos/` |
| `fonts/` | unchanged |

Migration caveat: machines with existing symlinks to old paths (e.g.
`~/.zshrc → ~/.dotfiles/.zshrc`) must re-run `./install.sh` once after
pulling.

## Error handling

- Installers: `set -euo pipefail` (bash), `$ErrorActionPreference = 'Stop'`
  (PowerShell).
- rc files: never `set -e`; all sourcing guarded with existence checks so a
  broken/partial checkout cannot break shell startup.
- Package steps warn-and-continue if a package manager is unavailable
  (e.g. no winget) rather than aborting the link phase. Links run before
  packages for this reason.

## Testing / verification

- `bash -n` on every `.sh`; PowerShell parser check on every `.ps1`.
- Sandbox run on this (Windows) machine via git-bash:
  `HOME=$(mktemp -d) DOTFILES_OS=linux ./install.sh --skip-packages` and
  same with `DOTFILES_OS=macos` — verifies link map parsing, link creation,
  backup behavior, claude settings merge.
- Real run of `install.ps1` on this machine (it is the live Windows target).
- Statusline smoke test: pipe sample JSON through
  `config/claude/statusline.sh` after the move.
