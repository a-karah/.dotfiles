#!/bin/bash

# returns true when two arguments are different
function check_shasum() {
	if [ $(shasum $1 | awk '{print $1}') != $(shasum $2 | awk '{print $1}') ]; then
		true
	else
		false
	fi
}

function is_installed() {
	if ! [ -x "$(command -v $1)" ]; then
		echo "$1 is not installed"
		false
		return
	else
		echo "$1 is installed"
		true
		return
	fi
}
