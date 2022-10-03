#!/bin/bash

. ./utils.sh

if check_shasum .macos.sh ~/.macos.sh; then
	cp .macos.sh ~
	chmod a+x ~/.macos.sh
fi

cp com.user.loginscript.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.loginscript.plist
#launchctl start com.user.loginscript
