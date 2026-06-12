#!/bin/bash
# Shared helpers for the dotfiles installers and rc files.
# Safe to source from rc files: defines functions and sets DOTFILES_PATH if unset.

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
	local src="$DOTFILES_PATH/$1" dst="$2" bak="$2.bak"
	if [ ! -e "$src" ]; then
		echo "link_file: missing source $src" >&2
		return 1
	fi
	[ -e "$bak" ] && bak="$bak.$(date +%s)"   # never clobber an earlier backup
	mkdir -p "$(dirname "$dst")"
	if [ -L "$dst" ]; then
		case "$(readlink "$dst")" in
			"$DOTFILES_PATH"/*) ;;            # ours — refresh below
			*) mv "$dst" "$bak" ;;            # foreign symlink — preserve it
		esac
	elif [ -e "$dst" ]; then
		mv "$dst" "$bak"                      # real file — preserve it
	fi
	ln -sfn "$src" "$dst"
	echo "linked $dst -> $src"
}
