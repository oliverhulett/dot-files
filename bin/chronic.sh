#!/bin/bash

if command which --skip-aliases --skip-functions chronic >/dev/null 2>/dev/null; then
	exec chronic "$@"
	exit
fi
tmp="$(mktemp)" || return
trap 'rm -f "$tmp"' EXIT
"$@" > "$tmp" 2>&1
ret=$?
if [ "$ret" -ne 0 ]; then
	command cat "$tmp"
	echo
	echo "Exiting: $*"
	echo "Exit code: $ret"
fi
exit $ret
