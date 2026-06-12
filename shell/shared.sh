#!/bin/bash
# Shared shell config — sourced by zsh and bash on every platform.
# No installs, no machine-specific data here.

export LANG=en_US.UTF-8

PATH="$PATH:$HOME/.local/bin"

#-----ALIASES-----#
alias vimrc="vim ~/.vimrc"
alias zshrc="vim ~/.zshrc"
alias gccc="gcc -Wall -Werror -Wextra -g"

#-----PROMPT-----#
if command -v starship >/dev/null 2>&1; then
	if [ -n "${ZSH_VERSION:-}" ]; then
		eval "$(starship init zsh)"
	elif [ -n "${BASH_VERSION:-}" ]; then
		eval "$(starship init bash)"
	fi
fi
