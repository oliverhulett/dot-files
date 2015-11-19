#!/bin/bash

if [ "$1" == "-c" -o "$1" == "--clean" ]; then
	rm -rf .git/externals x_* 2>/dev/null
	if [ -f ./pins.json ]; then
		sed -nre 's/^[ \t]+"(.+)": \{/\1/p' ./pins.json | xargs rm -rf
	fi
else
	if [ -x ./git_setup.py ]; then
		./git_setup.py -kq
	fi
	if [ -f ./deps.json ]; then
		courier
	fi
fi

