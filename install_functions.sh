#!/bin/bash

#. ./utils.sh

# returns true when two arguments are different
function check_shasum() {
	if [ $(shasum $1 | awk '{print $1}') != $(shasum $2 | awk '{print $1}') ]; then
		true
	else
		false
	fi
}

# Install homebrew into goinfre
function install_homebrew() {
	if [[ ! -d /goinfre/$USER/homebrew ]]; then
		echo "Installing homebrew"
		cd /goinfre/$USER
		mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
		cd -
		echo "Homebrew is installed"
	fi
}

# Homebrew packages
function brew_packages() {
	if ! [ -x "$(command -v wget)" ]; then
		brew install wget
	fi

	# Install fonts
	#brew tap homebrew/cask-fonts
	#brew install font-ibm-plex --cask
	#brew install font-blex-mono-nerd-font --cask

	if ! [ -x "$(command -v dark-mode)" ]; then
		brew install dark-mode
	fi

	if ! [ -x "$(command -v starship)" ]; then
		# Install prompt
		brew install starship
		echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc
	fi

	if ! [ -x "$(command -v alacritty)" ]; then
		brew install alacritty
	fi
}

function copy_dotfiles () {
	if check_shasum .vimrc ~/.vimrc; then
		cp .vimrc ~/.vimrc
	fi
	if check_shasum alacritty.yml ~/.config/alacritty/alacritty.yml; then
		cp alacritty.yml ~/.config/alacritty/alacritty.yml
	fi
	if check_shasum .zshrc ~/.zshrc; then
		cp .zshrc ~/.zshrc
	fi
}

# Various scripts
# Install cclean
function install_cleaner() {
	if [[ ! -d ~/Cleaner_42 ]]; then
		git clone https://github.com/ombhd/Cleaner_42.git
		cd ~/Cleaner_42/CleanerInstaller.sh && ./CleanerInstaller.sh && cd -
	fi
}

function install_ohmyzsh() {
	if ! [ -x "$(command -v omz)" ]; then
		# Install oh-my-zsh
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
}
install_homebrew
