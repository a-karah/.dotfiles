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
