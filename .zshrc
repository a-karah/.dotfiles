#!/bin/bash

. .dotfiles/install_functions.sh

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export LANG=en_US.UTF-8
export USER="akarahan"
export MAIL="akarahan@student.42istanbul.com.tr"
export ZSH="/home/$USER/.oh-my-zsh"

# Setting pwn path
PATH=$PATH:~/.local/bin
PATH=$PATH:"/Users/$USER/goinfre/homebrew/bin"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-syntax-highlighting)

#source $ZSH/oh-my-zsh.sh

# User configuration

#-----ALIASES-----#
alias vimrc="vim ~/.vimrc"
alias zshrc="vim ~/.zshrc"
alias gccc="gcc -Wall -Werror -Wextra -g"
alias code="open -a 'Visual Studio Code'"
alias cclean="bash ~/Cleaner_42.sh"

#-----INITIALIZATION-----#
install_homebrew()
brew_packages()

if [[ -x $(command -v starship) ]]; then
	eval "$(starship init zsh)"
fi

# Activate dark mode if it is not activated
if [[ -x $(command -v dark-mode) && $(dark-mode status) == "off" ]]; then
	dark-mode
fi
