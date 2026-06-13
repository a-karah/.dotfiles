#!/bin/bash
# Dotfiles installer for macOS / Linux / WSL.
# Usage: ./install.sh [--dry-run] [--skip-packages] [--uninstall]
#   --uninstall  remove the symlinks/settings this script created (restoring
#                any .bak backups); installed packages are left in place.

set -euo pipefail

DOTFILES_PATH="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_PATH
source "$DOTFILES_PATH/lib/utils.sh"

DRY_RUN=false
SKIP_PACKAGES=false
UNINSTALL=false
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=true ;;
		--skip-packages) SKIP_PACKAGES=true ;;
		--uninstall) UNINSTALL=true ;;
		*) echo "unknown option: $arg" >&2; exit 2 ;;
	esac
done

if [ -z "${DOTFILES_OS:-}" ]; then
	case "$(uname -s)" in
		MINGW*|MSYS*|CYGWIN*)
			echo "This is a POSIX installer; on Windows use install.ps1 instead." >&2
			exit 2
			;;
	esac
fi

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
	if $UNINSTALL; then
		if $DRY_RUN; then
			echo "[dry-run] unlink $dst"
		else
			unlink_file "$src" "$dst"
		fi
	elif $DRY_RUN; then
		echo "[dry-run] link $dst -> $DOTFILES_PATH/$src"
	else
		link_file "$src" "$dst"
	fi
done < "$DOTFILES_PATH/links.conf"

#-----PACKAGES-----#
if $UNINSTALL; then
	echo "Leaving installed packages in place (uninstall does not remove them)."
elif ! $SKIP_PACKAGES; then
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
		if jq -s '.[0] * .[1]' "$settings" "$template" > "$tmp"; then
			mv "$tmp" "$settings"
			echo "wired statusLine into $settings"
		else
			rm -f "$tmp"
			echo "error: failed to merge statusLine into $settings (invalid JSON?)" >&2
			exit 1
		fi
	else
		echo "warning: jq unavailable; statusLine not merged into existing $settings" >&2
	fi
}

# Inverse of merge_claude_settings: drop the statusLine block if (and only if)
# it points at our statusline, leaving any other settings untouched. If that
# empties the file, remove it — the file was ours to begin with.
function unmerge_claude_settings() {
	local settings="$HOME/.claude/settings.json"
	local desired='bash "$HOME/.claude/statusline.sh"'
	[ -f "$settings" ] || return 0
	if ! is_installed jq; then
		echo "warning: jq unavailable; leaving $settings untouched" >&2
		return 0
	fi
	[ "$(jq -r '.statusLine.command // ""' "$settings" 2>/dev/null)" = "$desired" ] || return 0
	if $DRY_RUN; then
		echo "[dry-run] remove statusLine from $settings"
		return 0
	fi
	local tmp
	tmp=$(mktemp)
	if jq 'del(.statusLine)' "$settings" > "$tmp"; then
		if jq -e 'length == 0' "$tmp" >/dev/null 2>&1; then
			rm -f "$tmp" "$settings"
			echo "removed statusLine; deleted now-empty $settings"
		else
			mv "$tmp" "$settings"
			echo "removed statusLine from $settings"
		fi
	else
		rm -f "$tmp"
		echo "error: failed to edit $settings (invalid JSON?)" >&2
		exit 1
	fi
}

if $UNINSTALL; then
	unmerge_claude_settings
else
	merge_claude_settings
fi

#-----MACOS LAUNCH AGENT-----#
# Runs ~/.macos.sh (defaults) at login; replaces the old init_mac.sh.
if [ "$OS" = macos ]; then
	plist="$HOME/Library/LaunchAgents/com.user.loginscript.plist"
	if $UNINSTALL; then
		if $DRY_RUN; then
			echo "[dry-run] unload + remove $plist"
		elif [ -f "$plist" ]; then
			launchctl unload "$plist" 2>/dev/null || true
			rm -f "$plist"
			echo "removed launch agent $plist"
		fi
	elif ! $DRY_RUN; then
		mkdir -p "$HOME/Library/LaunchAgents"
		cp "$DOTFILES_PATH/os/macos/com.user.loginscript.plist" "$plist"
		launchctl load "$plist" 2>/dev/null || true
	fi
fi

if $UNINSTALL; then
	echo "Uninstalled."
else
	echo "Done."
fi
