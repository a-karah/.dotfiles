#!/bin/bash

# returns true when two arguments are different
function check_shasum() {
	if [ $(shasum $1 | awk '{print $1}') != $(shasum $2 | awk '{print $1}') ]; then
		true
	else
		false
	fi
}
