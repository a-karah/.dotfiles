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
merge_claude_settings

#-----MACOS LAUNCH AGENT-----#
# Runs ~/.macos.sh (defaults) at login; replaces the old init_mac.sh.
if [ "$OS" = macos ] && ! $DRY_RUN; then
	mkdir -p "$HOME/Library/LaunchAgents"
	cp "$DOTFILES_PATH/os/macos/com.user.loginscript.plist" "$HOME/Library/LaunchAgents/"
	launchctl load "$HOME/Library/LaunchAgents/com.user.loginscript.plist" 2>/dev/null || true
fi

echo "Done."
