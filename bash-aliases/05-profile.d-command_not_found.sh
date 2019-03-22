# shellcheck shell=bash

if command which brew >/dev/null 2>/dev/null; then
	if brew command command-not-found-init > /dev/null 2>&1; then
		eval "$(brew command-not-found-init)";
	fi
fi
