#!/bin/bash

source $HOME/.dotfiles/utils.sh

export BREW=/goinfre/$USER/homebrew/bin/brew

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
		$BREW install wget
		echo "wget is installed"
	fi

	# Install fonts
	#brew tap homebrew/cask-fonts
	#brew install font-ibm-plex --cask
	#brew install font-blex-mono-nerd-font --cask

	if  ! [ -x "$(command -v dark-mode)" ]; then
		echo "Installing dark-mode"
		$BREW install dark-mode
		echo "dark-mode is installed"
	fi

	# jq is required by the claude statusline script
	if  ! [ -x "$(command -v jq)" ]; then
		echo "Installing jq"
		$BREW install jq
		echo "jq is installed"
	fi

	if  ! [ -x "$(command -v starship)" ]; then
		echo "Installing starship"
		$BREW install starship
		#echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc
		echo "starship is installed"
	fi

	# if  ! [ -x "$(command -v alacritty)" ]; then
	# 	echo "Installing alacritty"
	# 	$BREW install alacritty
	# 	echo "alacritty is installed"
	# fi
}

function copy_dotfiles() {
	if check_shasum $HOME/.dotfiles/.vimrc $HOME/.vimrc; then
		echo "Copying vimrc to home directory"
		cp $DOTFILES_PATH/.vimrc $HOME/.vimrc
		echo "Done copying"
	fi
	if check_shasum $DOTFILES_PATH/alacritty.yml $HOME/.config/alacritty/alacritty.yml; then
		echo "Copying alacritty to config directory"
		cp $DOTFILES_PATH/alacritty.yml $HOME/.config/alacritty/alacritty.yml
		echo "Done copying"
	fi
	if check_shasum $DOTFILES_PATH/.zshrc $HOME/.zshrc; then
		echo "Copying zshrc to home directory"
		cp $DOTFILES_PATH/.zshrc $HOME/.zshrc
		echo "Done copying"
	fi
}

function create_symlink_to_dotfiles() {
	if [[ ! -f $HOME/.zshrc ]]; then
		ln -sfn $HOME/.dotfiles/.zshrc $HOME/.zshrc
	fi
	if [[ ! -f $HOME/.vimrc ]]; then
		ln -sfn $HOME/.dotfiles/.vimrc $HOME/.vimrc
	fi
	if [[ ! -f $HOME/.config/alacritty/alacritty.yml ]]; then
		ln -sfn $HOME/.dotfiles/alacritty.yml $HOME/.config/alacritty/alacritty.yml
	fi
}

# Symlink the claude statusline script and wire it into settings.json.
# settings.json is merged (not symlinked) so claude-managed keys (plugins,
# theme, ...) are preserved; the statusLine block comes from the dotfiles
# template as the single source of truth.
function setup_claude_statusline() {
	local claude_dir="$HOME/.claude"
	local settings="$claude_dir/settings.json"
	local template="$HOME/.dotfiles/config/claude/settings.json"
	local desired='bash "$HOME/.claude/statusline.sh"'

	mkdir -p "$claude_dir"
	ln -sfn "$HOME/.dotfiles/config/claude/statusline.sh" "$claude_dir/statusline.sh"

	# Skip if statusLine already points at our script (avoid churn on a
	# file that claude rewrites itself).
	if [ -f "$settings" ] && [ "$(jq -r '.statusLine.command // ""' "$settings" 2>/dev/null)" = "$desired" ]; then
		return
	fi

	if [ -x "$(command -v jq)" ]; then
		if [ -f "$settings" ]; then
			local tmp=$(mktemp)
			jq -s '.[0] * .[1]' "$settings" "$template" > "$tmp" && mv "$tmp" "$settings"
		else
			cp "$template" "$settings"
		fi
	else
		# No jq: only create from template when there is nothing to preserve.
		[ -f "$settings" ] || cp "$template" "$settings"
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
