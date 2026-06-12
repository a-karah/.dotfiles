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
