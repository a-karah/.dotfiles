#!/bin/bash

source $HOME/.dotfiles/utils.sh

if check_shasum $HOME/.dotfiles/.macos.sh $HOME/.macos.sh; then
	cp $HOME/.dotfiles/.macos.sh $HOME/.macos.sh
	chmod a+x $HOME/.macos.sh
fi

cp com.user.loginscript.plist $HOME/Library/LaunchAgents/
launchctl load $HOME/Library/LaunchAgents/com.user.loginscript.plist
#launchctl start com.user.loginscript
