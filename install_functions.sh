#!/bin/bash

. $HOME/.dotfiles/utils.sh

export brew_bin=/goinfre/$USER/homebrew/bin/brew

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
function install_brew_packages() {
	if ! [ -x "$(command -v wget)" ]; then
		echo "Installing wget"
		$brew_bin install wget
		echo "wget is installed"
	fi

	# Install fonts
	#brew tap homebrew/cask-fonts
	#brew install font-ibm-plex --cask
	#brew install font-blex-mono-nerd-font --cask

	if  ! [ -x "$(command -v dark-mode)" ]; then
		echo "Installing dark-mode"
		$brew_bin install dark-mode
		echo "dark-mode is installed"
	fi

	if  ! [ -x "$(command -v starship)" ]; then
		echo "Installing starship"
		$brew_bin install starship
		#echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc
		echo "starship is installed"
	fi

	# if  ! [ -x "$(command -v alacritty)" ]; then
	# 	echo "Installing alacritty"
	# 	$brew_bin install alacritty
	# 	echo "alacritty is installed"
	# fi
}

function copy_dotfiles () {
	if check_shasum $HOME/.dotfiles/.vimrc $HOME/.vimrc; then
		echo "Copying vimrc to home directory"
		cp $HOME/.dotfiles/.vimrc $HOME/.vimrc
		echo "Done copying"
	fi
	if check_shasum $HOME/.dotfiles/alacritty.yml $HOME/.config/alacritty/alacritty.yml; then
		echo "Copying alacritty to config directory"
		cp $HOME/.dotfiles/alacritty.yml $HOME/.config/alacritty/alacritty.yml
		echo "Done copying"
	fi
	if check_shasum $HOME/.dotfiles/.zshrc $HOME/.zshrc; then
		echo "Copying zshrc to home directory"
		cp $HOME/.dotfiles/.zshrc $HOME/.zshrc
		echo "Done copying"
	fi
}

# Various scripts
# Install cclean
function install_cleaner() {
	if [[ ! -d $HOME/Cleaner_42 ]]; then
		echo "Installing cleaner-42"
		git clone https://github.com/ombhd/Cleaner_42.git
		cd $HOME/Cleaner_42/CleanerInstaller.sh && ./CleanerInstaller.sh && cd -
		echo "cleaner-42 is installed"
	fi
}

function install_ohmyzsh() {
	# if  ! [ -x "$(command -v omz)" ]; then
	if  [[ ! -d  $HOME/.oh-my-zsh ]]; then
		echo "Installing oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		echo "oh-my-zsh is installed"
	fi
}

function install_omz_plugins() {
	if [[ ! -d $HOME/zsh-syntax-highlighting ]]; then
		echo "Installing zsh-syntax-highlighting"
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
		echo "Installed zsh-syntax-highlighting"
	fi
}
