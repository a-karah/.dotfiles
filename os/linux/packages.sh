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
		curl -fsSL https://starship.rs/install.sh | sh -s -- -y
	fi
}
