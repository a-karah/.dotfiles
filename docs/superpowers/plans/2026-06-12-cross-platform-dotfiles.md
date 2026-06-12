# Cross-Platform Dotfiles Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the dotfiles repo into a platform-layered structure (shared `config//shell/`, per-platform `os/`) with two installers (`install.sh`, `install.ps1`) driven by one declarative link map.

**Architecture:** Shared configs live in `config/` and `shell/shared.sh`; platform-specific code in `os/{macos,linux,windows}/`; helpers in `lib/`. Both installers parse `links.conf` to create symlinks, then install packages (brew/apt/winget), then wire the Claude statusline. 42-school machines additionally auto-bootstrap from `shell/zshrc` (idempotent) because `/goinfre` gets wiped.

**Tech Stack:** bash, PowerShell 7, jq, brew/apt/winget, symlinks.

**Spec:** `docs/superpowers/specs/2026-06-12-cross-platform-dotfiles-design.md`

**Repo root:** `~/.dotfiles` (Windows: `C:\Users\abdulsalam.karahan\.dotfiles`). All commands below run from the repo root in **git-bash** unless marked PowerShell.

**Testing note:** This is a shell-script repo with no test framework. Each task verifies with `bash -n` (syntax) plus functional sandbox assertions (`HOME=$(mktemp -d)`), which take the place of unit tests. On git-bash, `ln -s` may silently copy instead of link, so sandbox assertions check *content*, not `[ -L ]`.

---

### Task 1: `lib/utils.sh` — shared helpers

**Files:**
- Create: `lib/utils.sh`

- [ ] **Step 1: Write `lib/utils.sh`**

```bash
#!/bin/bash
# Shared helpers for the dotfiles installers and rc files.
# Safe to source from rc files: defines functions/vars only, no side effects.

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"

# Echoes "macos" or "linux". DOTFILES_OS overrides (for testing).
function detect_os() {
	if [ -n "${DOTFILES_OS:-}" ]; then
		echo "$DOTFILES_OS"
		return
	fi
	case "$(uname -s)" in
		Darwin) echo macos ;;
		*)      echo linux ;;
	esac
}

# True on a 42 school machine.
function is_42() {
	[ -d /goinfre ]
}

function is_installed() {
	command -v "$1" >/dev/null 2>&1
}

# link_file <repo-relative-source> <absolute-target>
# - target already links into the repo -> relink (heals links to old repo paths)
# - target is a real file, or a foreign symlink -> back up to <target>.bak first
function link_file() {
	local src="$DOTFILES_PATH/$1" dst="$2"
	if [ ! -e "$src" ]; then
		echo "link_file: missing source $src" >&2
		return 1
	fi
	mkdir -p "$(dirname "$dst")"
	if [ -L "$dst" ]; then
		case "$(readlink "$dst")" in
			"$DOTFILES_PATH"/*) ;;            # ours — refresh below
			*) mv "$dst" "$dst.bak" ;;        # foreign symlink — preserve it
		esac
	elif [ -e "$dst" ]; then
		mv "$dst" "$dst.bak"                  # real file — preserve it
	fi
	ln -sfn "$src" "$dst"
	echo "linked $dst -> $src"
}
```

- [ ] **Step 2: Syntax check**

Run: `bash -n lib/utils.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Functional sandbox test**

```bash
SB=$(mktemp -d) && (
  set -e
  export DOTFILES_PATH="$HOME/.dotfiles"
  source "$DOTFILES_PATH/lib/utils.sh"
  # detect_os override
  [ "$(DOTFILES_OS=macos detect_os)" = macos ] && echo "PASS detect_os override"
  # is_installed
  is_installed bash && echo "PASS is_installed bash"
  ! is_installed not-a-real-cmd-xyz && echo "PASS is_installed negative"
  # link_file: backs up an existing real file (source: lib/utils.sh — always exists)
  echo "old content" > "$SB/target"
  link_file "lib/utils.sh" "$SB/target"
  [ -f "$SB/target.bak" ] && grep -q "old content" "$SB/target.bak" && echo "PASS backup created"
  cmp -s "$DOTFILES_PATH/lib/utils.sh" "$SB/target" && echo "PASS link content"
  # link_file: missing source errors
  ! link_file "does/not/exist" "$SB/x" 2>/dev/null && echo "PASS missing source rejected"
) && rm -rf "$SB"
```

Expected output contains all five `PASS` lines.

- [ ] **Step 4: Commit**

```bash
git add lib/utils.sh
git commit -m "add lib/utils.sh with platform detection and safe linking"
```

---

### Task 2: `links.conf` + move config files into the new layout

**Files:**
- Create: `links.conf`
- Move (git mv): `.vimrc → config/vimrc`, `.tmux.conf → config/tmux.conf`, `.ctags → config/ctags`, `alacritty.yml → config/alacritty.yml`, `claude/statusline.sh → config/claude/statusline.sh`, `claude/settings.json → config/claude/settings.json`, `.macos.sh → os/macos/defaults.sh`, `com.user.loginscript.plist → os/macos/com.user.loginscript.plist`, `ayu Dark.itermcolors → os/macos/ayu.itermcolors`
- Modify: `install_functions.sh` (keep old wiring working until cut-over)

- [ ] **Step 1: Move files**

```bash
mkdir -p config os/macos
git mv .vimrc config/vimrc
git mv .tmux.conf config/tmux.conf
git mv .ctags config/ctags
git mv alacritty.yml config/alacritty.yml
git mv claude config/claude
git mv .macos.sh os/macos/defaults.sh
git mv com.user.loginscript.plist os/macos/com.user.loginscript.plist
git mv "ayu Dark.itermcolors" os/macos/ayu.itermcolors
```

- [ ] **Step 2: Write `links.conf`**

```
# Declarative link map — read by install.sh and install.ps1.
# Format: <platform> <repo-path> <target>
# Platforms: all | unix (macos+linux) | macos | linux | windows
unix    shell/zshrc                   ~/.zshrc
unix    shell/bashrc                  ~/.bashrc
unix    config/vimrc                  ~/.vimrc
unix    config/tmux.conf              ~/.tmux.conf
unix    config/ctags                  ~/.ctags
unix    config/alacritty.yml          ~/.config/alacritty/alacritty.yml
all     config/claude/statusline.sh   ~/.claude/statusline.sh
macos   os/macos/defaults.sh          ~/.macos.sh
```

(`shell/zshrc` and `shell/bashrc` don't exist yet — created in Tasks 3 and 8. `install.sh` errors on missing sources, which is correct; nothing consumes `links.conf` until Task 10.)

- [ ] **Step 3: Fix the claude path in `install_functions.sh`** (keeps the not-yet-deleted legacy wiring consistent)

In `install_functions.sh`, function `setup_claude_statusline`, replace both occurrences of `$HOME/.dotfiles/claude/` with `$HOME/.dotfiles/config/claude/`:

```bash
	local template="$HOME/.dotfiles/config/claude/settings.json"
	...
	ln -sfn "$HOME/.dotfiles/config/claude/statusline.sh" "$claude_dir/statusline.sh"
```

- [ ] **Step 4: Verify**

Run: `bash -n install_functions.sh && git status --short`
Expected: exit 0; status shows only renames (`R`), `links.conf` (`A`/`??`), and `M install_functions.sh`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "move configs into config/ and os/macos/, add links.conf"
```

---

### Task 3: `shell/shared.sh` + `shell/bashrc`

**Files:**
- Create: `shell/shared.sh`
- Create: `shell/bashrc`

- [ ] **Step 1: Write `shell/shared.sh`**

```bash
#!/bin/bash
# Shared shell config — sourced by zsh and bash on every platform.
# No installs, no machine-specific data here.

export LANG=en_US.UTF-8

PATH="$PATH:$HOME/.local/bin"

#-----ALIASES-----#
alias vimrc="vim ~/.vimrc"
alias zshrc="vim ~/.zshrc"
alias gccc="gcc -Wall -Werror -Wextra -g"

#-----PROMPT-----#
if command -v starship >/dev/null 2>&1; then
	if [ -n "${ZSH_VERSION:-}" ]; then
		eval "$(starship init zsh)"
	elif [ -n "${BASH_VERSION:-}" ]; then
		eval "$(starship init bash)"
	fi
fi
```

(The old `code` alias is dropped: modern VS Code installs its own `code` CLI. `cclean` moves to `os/macos/42.sh` in Task 7.)

- [ ] **Step 2: Write `shell/bashrc`**

```bash
#!/bin/bash
# Thin bash config — shared settings live in shell/shared.sh.

if [ -f "$HOME/.dotfiles/shell/shared.sh" ]; then
	source "$HOME/.dotfiles/shell/shared.sh"
fi
```

- [ ] **Step 3: Verify**

```bash
bash -n shell/shared.sh && bash -n shell/bashrc && bash -c 'source shell/shared.sh && alias gccc && echo PASS'
```

Expected: prints the `gccc` alias definition and `PASS`.

- [ ] **Step 4: Commit**

```bash
git add shell/
git commit -m "add shared shell config and thin bashrc"
```

---

### Task 4: `os/macos/packages.sh`

**Files:**
- Create: `os/macos/packages.sh`

- [ ] **Step 1: Write `os/macos/packages.sh`**

```bash
#!/bin/bash
# macOS package installation (brew). Used by install.sh and bootstrap_42.

source "$HOME/.dotfiles/lib/utils.sh"

# Resolve the brew binary: 42 machines use the /goinfre workaround
# (quota in $HOME), everything else a standard install.
function resolve_brew() {
	if is_42; then
		echo "/goinfre/$USER/homebrew/bin/brew"
	elif is_installed brew; then
		command -v brew
	elif [ -x /opt/homebrew/bin/brew ]; then
		echo /opt/homebrew/bin/brew
	elif [ -x /usr/local/bin/brew ]; then
		echo /usr/local/bin/brew
	else
		echo ""
	fi
}

function install_homebrew_42() {
	if [ ! -d "/goinfre/$USER/homebrew" ]; then
		echo "Installing homebrew into /goinfre/$USER"
		mkdir -p "/goinfre/$USER/homebrew"
		curl -L https://github.com/Homebrew/brew/tarball/master |
			tar xz --strip 1 -C "/goinfre/$USER/homebrew"
	fi
}

function install_macos_packages() {
	local brew pkg
	is_42 && install_homebrew_42
	brew=$(resolve_brew)
	if [ -z "$brew" ]; then
		echo "warning: brew not found; skipping packages" >&2
		return 0
	fi
	for pkg in starship jq wget dark-mode; do
		if ! is_installed "$pkg"; then
			echo "Installing $pkg"
			"$brew" install "$pkg"
		fi
	done
}
```

- [ ] **Step 2: Verify**

```bash
bash -n os/macos/packages.sh && bash -c 'source os/macos/packages.sh && [ -n "$(type -t install_macos_packages)" ] && echo PASS'
```

Expected: `PASS`.

- [ ] **Step 3: Commit**

```bash
git add os/macos/packages.sh
git commit -m "add macos package script with 42/standard brew resolution"
```

---

### Task 5: `os/linux/packages.sh`

**Files:**
- Create: `os/linux/packages.sh`

- [ ] **Step 1: Write `os/linux/packages.sh`**

```bash
#!/bin/bash
# Linux (apt) package installation.

source "$HOME/.dotfiles/lib/utils.sh"

function install_linux_packages() {
	local pkg missing=()
	if ! is_installed apt-get; then
		echo "warning: apt-get not found; skipping packages" >&2
		return 0
	fi
	for pkg in jq wget; do
		is_installed "$pkg" || missing+=("$pkg")
	done
	if [ ${#missing[@]} -gt 0 ]; then
		echo "Installing ${missing[*]}"
		sudo apt-get update -qq
		sudo apt-get install -y "${missing[@]}"
	fi
	# starship is not in (older) apt repos; use the official installer
	if ! is_installed starship; then
		echo "Installing starship"
		curl -sS https://starship.rs/install.sh | sh -s -- -y
	fi
}
```

- [ ] **Step 2: Verify**

```bash
bash -n os/linux/packages.sh && bash -c 'source os/linux/packages.sh && [ -n "$(type -t install_linux_packages)" ] && echo PASS'
```

Expected: `PASS`.

- [ ] **Step 3: Commit**

```bash
git add os/linux/packages.sh
git commit -m "add linux apt package script"
```

---

### Task 6: `os/windows/packages.ps1`

**Files:**
- Create: `os/windows/packages.ps1`

- [ ] **Step 1: Write `os/windows/packages.ps1`**

```powershell
# Windows (winget) package installation.

function Install-WindowsPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found; skipping packages"
        return
    }
    $packages = @(
        @{ Cmd = 'starship'; Id = 'Starship.Starship' },
        @{ Cmd = 'jq';       Id = 'jqlang.jq' },
        @{ Cmd = 'wget';     Id = 'JernejSimoncic.Wget' }
    )
    foreach ($p in $packages) {
        if (-not (Get-Command $p.Cmd -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $($p.Id)"
            winget install --id $p.Id -e --silent --accept-source-agreements --accept-package-agreements
        }
    }
}
```

- [ ] **Step 2: Verify (PowerShell parser check + function loads)**

Run (PowerShell): `pwsh -NoProfile -Command ". ./os/windows/packages.ps1; if (Get-Command Install-WindowsPackages) { 'PASS' }"`
Expected: `PASS`.

- [ ] **Step 3: Commit**

```bash
git add os/windows/packages.ps1
git commit -m "add windows winget package script"
```

---

### Task 7: `os/macos/42.sh` — 42-school environment + bootstrap

**Files:**
- Create: `os/macos/42.sh`

- [ ] **Step 1: Write `os/macos/42.sh`**

```bash
#!/bin/bash
# 42 school environment — sourced from shell/zshrc on 42 machines only
# (detected via is_42). Holds everything campus-specific.

export USER="akarahan"
export MAIL="akarahan@student.42istanbul.com.tr"

PATH="$PATH:/goinfre/$USER/homebrew/bin"

alias cclean="bash ~/Cleaner_42.sh"

# /goinfre is wiped regularly, so re-run the (idempotent) installers on
# shell startup — fast no-ops when everything is already in place.
function bootstrap_42() {
	source "$HOME/.dotfiles/os/macos/packages.sh"
	install_macos_packages

	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		echo "Installing oh-my-zsh"
		# RUNZSH/KEEP_ZSHRC: don't drop into a new shell, don't replace our symlinked ~/.zshrc
		RUNZSH=no KEEP_ZSHRC=yes sh -c \
			"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi
	local hl_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
	if [ ! -d "$hl_dir" ]; then
		echo "Installing zsh-syntax-highlighting"
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$hl_dir"
	fi
}

# Keep the campus iMac in dark mode
if command -v dark-mode >/dev/null 2>&1 && [ "$(dark-mode status)" = "off" ]; then
	dark-mode
fi
```

(Improvement over the old installer call: `RUNZSH=no KEEP_ZSHRC=yes --unattended` stops the oh-my-zsh installer from overwriting the symlinked `~/.zshrc` and exec-ing a new shell mid-bootstrap.)

- [ ] **Step 2: Verify**

```bash
bash -n os/macos/42.sh && bash -c 'source os/macos/42.sh 2>/dev/null; [ -n "$(type -t bootstrap_42)" ] && [ "$MAIL" = "akarahan@student.42istanbul.com.tr" ] && echo PASS'
```

Expected: `PASS`.

- [ ] **Step 3: Commit**

```bash
git add os/macos/42.sh
git commit -m "add 42-school env and idempotent bootstrap"
```

---

### Task 8: `shell/zshrc`

**Files:**
- Create: `shell/zshrc`

- [ ] **Step 1: Write `shell/zshrc`**

```bash
#!/bin/zsh
# Thin zsh config — shared settings live in shell/shared.sh,
# platform/campus specifics in os/.

DOTFILES="$HOME/.dotfiles"

# Temporary fix to "Insecure completion-dependent directories detected"
if [[ "$(uname -s)" == Darwin ]]; then
	ZSH_DISABLE_COMPFIX=true
fi

source "$DOTFILES/lib/utils.sh"

# 42 school: campus env + auto-bootstrap (idempotent; /goinfre gets wiped)
if is_42; then
	source "$DOTFILES/os/macos/42.sh"
	bootstrap_42
fi

#-----OH-MY-ZSH-----#
export ZSH="$HOME/.oh-my-zsh"
CASE_SENSITIVE="true"
ENABLE_CORRECTION="true"
plugins=(git macos zsh-syntax-highlighting)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
	source "$ZSH/oh-my-zsh.sh"
fi

source "$DOTFILES/shell/shared.sh"
```

Ordering rationale: 42 bootstrap runs *before* oh-my-zsh sourcing so omz exists on the first shell after a wipe; `shared.sh` runs last so starship overrides the omz theme.

- [ ] **Step 2: Verify**

`zsh` isn't available on this Windows machine, so check with bash syntax mode (the file is bash-compatible except `[[ ]]`, which bash also supports):

```bash
bash -n shell/zshrc && echo PASS
```

Expected: `PASS`.

- [ ] **Step 3: Commit**

```bash
git add shell/zshrc
git commit -m "add thin zshrc with 42 hook"
```

---

### Task 9: `shell/profile.ps1` + `lib/utils.ps1`

**Files:**
- Create: `shell/profile.ps1`
- Create: `lib/utils.ps1`

- [ ] **Step 1: Write `shell/profile.ps1`**

```powershell
# PowerShell profile — Windows counterpart of shell/shared.sh.

#-----PROMPT-----#
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
```

- [ ] **Step 2: Write `lib/utils.ps1`**

```powershell
# Shared helpers for install.ps1.

$script:DotfilesPath = Split-Path -Parent $PSScriptRoot   # lib/.. = repo root

function Test-SymlinkPrivilege {
    $probe = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-symlink-probe"
    try {
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        New-Item -ItemType SymbolicLink -Path $probe -Target $PSCommandPath -ErrorAction Stop | Out-Null
        Remove-Item $probe -Force
        return $true
    } catch {
        return $false
    }
}

# New-Link: same semantics as link_file in lib/utils.sh —
# our symlink -> refresh; real file or foreign link -> back up to .bak first.
function New-Link {
    param([string]$Source, [string]$Target, [switch]$DryRun)
    $src = Join-Path $script:DotfilesPath $Source
    if (-not (Test-Path $src)) { throw "New-Link: missing source $src" }
    if ($DryRun) { Write-Host "[dry-run] link $Target -> $src"; return }
    $dir = Split-Path -Parent $Target
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $existing = Get-Item $Target -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq 'SymbolicLink') {
        Remove-Item $Target -Force
    } elseif ($existing) {
        Move-Item $Target "$Target.bak" -Force
    }
    New-Item -ItemType SymbolicLink -Path $Target -Target $src | Out-Null
    Write-Host "linked $Target -> $src"
}

# Merge the statusLine block into ~/.claude/settings.json without touching
# other keys. Windows quirk: the command string must contain a RESOLVED
# path ($HOME literal would only expand under a POSIX shell).
function Merge-ClaudeStatusLine {
    param([switch]$DryRun)
    $settingsPath = Join-Path $HOME ".claude\settings.json"
    $desired = 'bash "{0}/.claude/statusline.sh"' -f ($HOME -replace '\\', '/')
    $settings = if (Test-Path $settingsPath) {
        Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else { [pscustomobject]@{} }
    if ($settings.statusLine -and $settings.statusLine.command -eq $desired) { return }
    if ($DryRun) { Write-Host "[dry-run] wire statusLine into $settingsPath"; return }
    $statusLine = [pscustomobject]@{ type = 'command'; command = $desired }
    if ($settings.PSObject.Properties['statusLine']) {
        $settings.statusLine = $statusLine
    } else {
        $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine
    }
    New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
    $settings | ConvertTo-Json -Depth 16 | Set-Content $settingsPath
    Write-Host "wired statusLine into $settingsPath"
}
```

- [ ] **Step 3: Verify**

Run (PowerShell):

```powershell
pwsh -NoProfile -Command @'
. ./lib/utils.ps1
if ((Get-Command New-Link) -and (Get-Command Merge-ClaudeStatusLine) -and (Get-Command Test-SymlinkPrivilege)) { 'PASS functions' }
"symlink privilege: $(Test-SymlinkPrivilege)"
'@
```

Expected: `PASS functions` and a true/false line (false just means Developer Mode is off — Task 11 handles that).

- [ ] **Step 4: Commit**

```bash
git add shell/profile.ps1 lib/utils.ps1
git commit -m "add powershell profile and installer helpers"
```

---

### Task 10: `install.sh`

**Files:**
- Create: `install.sh` (executable)

- [ ] **Step 1: Write `install.sh`**

```bash
#!/bin/bash
# Dotfiles installer for macOS / Linux / WSL.
# Usage: ./install.sh [--dry-run] [--skip-packages]

set -euo pipefail

DOTFILES_PATH="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_PATH
source "$DOTFILES_PATH/lib/utils.sh"

DRY_RUN=false
SKIP_PACKAGES=false
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=true ;;
		--skip-packages) SKIP_PACKAGES=true ;;
		*) echo "unknown option: $arg" >&2; exit 2 ;;
	esac
done

OS=$(detect_os)
echo "Platform: $OS"

#-----SYMLINKS-----#
while read -r platform src dst; do
	case "$platform" in
		'' | '#'*) continue ;;
		all | unix | "$OS") ;;
		*) continue ;;
	esac
	dst="${dst/#\~/$HOME}"
	if $DRY_RUN; then
		echo "[dry-run] link $dst -> $DOTFILES_PATH/$src"
	else
		link_file "$src" "$dst"
	fi
done < "$DOTFILES_PATH/links.conf"

#-----PACKAGES-----#
if ! $SKIP_PACKAGES; then
	if $DRY_RUN; then
		echo "[dry-run] install $OS packages"
	else
		source "$DOTFILES_PATH/os/$OS/packages.sh"
		"install_${OS}_packages"
	fi
fi

#-----CLAUDE STATUSLINE-----#
# Runs after packages so jq is available on a fresh machine.
function merge_claude_settings() {
	local settings="$HOME/.claude/settings.json"
	local template="$DOTFILES_PATH/config/claude/settings.json"
	local desired='bash "$HOME/.claude/statusline.sh"'
	if [ -f "$settings" ] && [ "$(jq -r '.statusLine.command // ""' "$settings" 2>/dev/null)" = "$desired" ]; then
		return 0
	fi
	if $DRY_RUN; then
		echo "[dry-run] wire statusLine into $settings"
		return 0
	fi
	mkdir -p "$HOME/.claude"
	if [ ! -f "$settings" ]; then
		cp "$template" "$settings"
		echo "created $settings"
	elif is_installed jq; then
		local tmp
		tmp=$(mktemp)
		jq -s '.[0] * .[1]' "$settings" "$template" > "$tmp" && mv "$tmp" "$settings"
		echo "wired statusLine into $settings"
	else
		echo "warning: jq unavailable; statusLine not merged into existing $settings" >&2
	fi
}
merge_claude_settings

#-----MACOS LAUNCH AGENT-----#
# Runs ~/.macos.sh (defaults) at login; replaces the old init_mac.sh.
if [ "$OS" = macos ] && ! $DRY_RUN; then
	mkdir -p "$HOME/Library/LaunchAgents"
	cp "$DOTFILES_PATH/os/macos/com.user.loginscript.plist" "$HOME/Library/LaunchAgents/"
	launchctl load "$HOME/Library/LaunchAgents/com.user.loginscript.plist" 2>/dev/null || true
fi

echo "Done."
```

Then: `chmod +x install.sh`

- [ ] **Step 2: Syntax check + dry-run**

```bash
bash -n install.sh && DOTFILES_OS=linux ./install.sh --dry-run --skip-packages
```

Expected: `Platform: linux`, one `[dry-run] link ...` line per `unix`/`all` row of links.conf (7 lines), `[dry-run] wire statusLine ...`, `Done.` — and **no** `~/.macos.sh` line (macos-only row filtered out).

- [ ] **Step 3: Sandbox run — linux profile**

```bash
REPO=$(pwd) && SB=$(mktemp -d) && (
  set -e
  export HOME="$SB"   # NOTE: ~ now expands to the sandbox — use $REPO for repo paths
  # pre-existing settings.json with foreign keys must survive the merge
  mkdir -p "$SB/.claude"
  echo '{"theme":"dark","effortLevel":"xhigh"}' > "$SB/.claude/settings.json"
  DOTFILES_OS=linux "$REPO/install.sh" --skip-packages
  echo "--- assertions ---"
  cmp -s "$REPO/config/vimrc" "$SB/.vimrc" && echo "PASS vimrc linked"
  cmp -s "$REPO/shell/zshrc" "$SB/.zshrc" && echo "PASS zshrc linked"
  cmp -s "$REPO/config/claude/statusline.sh" "$SB/.claude/statusline.sh" && echo "PASS statusline linked"
  [ ! -e "$SB/.macos.sh" ] && echo "PASS macos-only row skipped"
  jq -e '.theme=="dark" and .statusLine.type=="command"' "$SB/.claude/settings.json" >/dev/null && echo "PASS settings merged, theme preserved"
) ; rm -rf "$SB"
```

Expected: all five `PASS` lines.

- [ ] **Step 4: Sandbox run — macos profile**

```bash
REPO=$(pwd) && SB=$(mktemp -d) && (
  set -e
  export HOME="$SB"
  DOTFILES_OS=macos "$REPO/install.sh" --skip-packages
  cmp -s "$REPO/os/macos/defaults.sh" "$SB/.macos.sh" && echo "PASS defaults.sh linked"
  [ -f "$SB/Library/LaunchAgents/com.user.loginscript.plist" ] && echo "PASS launch agent plist copied"
) ; rm -rf "$SB"
```

Expected: both `PASS` lines (the `launchctl` call is absent on this machine and silently skipped via `|| true`).

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "add unix installer driven by links.conf"
```

---

### Task 11: `install.ps1` + real run on this machine

**Files:**
- Create: `install.ps1`

- [ ] **Step 1: Write `install.ps1`**

```powershell
# Dotfiles installer for Windows (PowerShell 7).
# Usage: .\install.ps1 [-DryRun] [-SkipPackages]

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPackages
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/utils.ps1')

if (-not $DryRun -and -not (Test-SymlinkPrivilege)) {
    throw "Cannot create symlinks. Enable Developer Mode (Settings > Privacy & security > For developers) or run as administrator."
}

#-----SYMLINKS-----#
Get-Content (Join-Path $PSScriptRoot 'links.conf') | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $platform, $src, $target = $line -split '\s+', 3
    if ($platform -notin @('all', 'windows')) { return }
    $target = $target -replace '^~', $HOME
    New-Link -Source $src -Target $target -DryRun:$DryRun
}

# PowerShell profile — $PROFILE resolved at runtime (Documents may be
# OneDrive-redirected, so no static path is safe in links.conf).
New-Link -Source 'shell/profile.ps1' -Target $PROFILE -DryRun:$DryRun

#-----PACKAGES-----#
if (-not $SkipPackages) {
    if ($DryRun) {
        Write-Host "[dry-run] install windows packages"
    } else {
        . (Join-Path $PSScriptRoot 'os/windows/packages.ps1')
        Install-WindowsPackages
    }
}

#-----CLAUDE STATUSLINE-----#
Merge-ClaudeStatusLine -DryRun:$DryRun

Write-Host "Done."
```

- [ ] **Step 2: Dry-run**

Run (PowerShell): `pwsh -NoProfile -File ./install.ps1 -DryRun -SkipPackages`
Expected: `[dry-run] link ...statusline.sh` (the one `all` row), `[dry-run] link ...$PROFILE...`, `[dry-run] wire statusLine ...`, `Done.` — and no `unix` rows.

- [ ] **Step 3: Real run on this machine**

First check privilege: `pwsh -NoProfile -Command ". ./lib/utils.ps1; Test-SymlinkPrivilege"`.

- If `True`: run `pwsh -NoProfile -File ./install.ps1 -SkipPackages` (skip packages — starship/jq already present or not wanted via winget prompts during work hours; can rerun later without the switch).
- If `False`: **stop and ask the user** to enable Developer Mode, or accept dry-run-only verification for now. Do not run elevated without asking.

Expected (privileged run): `~/.claude/statusline.sh` becomes a symlink to `config/claude/statusline.sh` (old real file backed up to `statusline.sh.bak`), `$PROFILE` linked (old profile, if any, backed up to `.bak`), settings.json `statusLine.command` updated to the resolved-path form.

- [ ] **Step 4: Verify the statusline still renders after the real run**

```bash
echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":42}}' | bash ~/.claude/statusline.sh
```

Expected: renders `Test  ·  ctx ███▍░░░░ 42%` (with colors).

- [ ] **Step 5: Commit**

```bash
git add install.ps1
git commit -m "add windows installer"
```

---

### Task 12: Cut over — delete legacy files, final verification, push

**Files:**
- Delete: `.zshrc`, `install_functions.sh`, `utils.sh`, `env_vars.sh`, `init_mac.sh`

- [ ] **Step 1: Delete legacy scripts**

```bash
git rm .zshrc install_functions.sh utils.sh env_vars.sh init_mac.sh
```

(Everything they did now lives in: `shell/zshrc` + `shell/shared.sh` + `os/macos/42.sh` (zshrc), `lib/utils.sh` + `os/macos/packages.sh` + `install.sh` (install_functions/utils), `install.sh` macOS branch (init_mac). `env_vars.sh` was dead code. `copy_dotfiles`, `check_shasum`, `install_cleaner` are intentionally not ported — see spec migration table.)

- [ ] **Step 2: Full verification sweep**

```bash
set -e
for f in lib/utils.sh shell/shared.sh shell/bashrc shell/zshrc \
         os/macos/packages.sh os/macos/42.sh os/macos/defaults.sh \
         os/linux/packages.sh install.sh config/claude/statusline.sh; do
  bash -n "$f" && echo "OK $f"
done
pwsh -NoProfile -Command "
  . ./lib/utils.ps1; . ./os/windows/packages.ps1
  \$null = Get-Command New-Link, Merge-ClaudeStatusLine, Install-WindowsPackages
  'OK ps1 files'
"
# end-to-end sandbox once more, both unix profiles
for os in linux macos; do
  SB=$(mktemp -d)
  HOME="$SB" DOTFILES_OS=$os ./install.sh --skip-packages >/dev/null && echo "OK install.sh ($os)"
  rm -rf "$SB"
done
```

Expected: `OK` for every file and both sandbox profiles.

- [ ] **Step 3: Confirm repo tree matches the spec layout**

Run: `git ls-files | sort`
Expected top-level entries: `.ctags` is gone (now `config/ctags`), no root `.zshrc`/`install_functions.sh`/`utils.sh`/`env_vars.sh`/`init_mac.sh`/`.macos.sh`/`alacritty.yml`/`claude/`; present: `install.sh`, `install.ps1`, `links.conf`, `lib/`, `shell/`, `config/`, `os/`, `fonts/`, `docs/`, `.gitattributes`.

- [ ] **Step 4: Commit and push**

```bash
git add -A
git commit -m "remove legacy scripts replaced by new layout"
git push
```

---

## Post-implementation notes (for the human)

- On 42/mac machines: after `git pull`, run `./install.sh` once — old symlinks point at deleted paths until then.
- On this Windows machine: if Task 11 ran for real, the statusline now flows repo → `~/.claude/statusline.sh` (symlink); edit it in the repo.
- `install.ps1` without `-SkipPackages` will winget-install starship for the PowerShell prompt when wanted.
