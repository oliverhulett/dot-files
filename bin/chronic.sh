#!/bin/bash

if command which --skip-aliases --skip-functions chronic >/dev/null 2>/dev/null; then
	exec chronic "$@"
	exit
fi
tmp="$(mktemp)" || return
trap 'rm -f "$tmp"' EXIT
"$@" > "$tmp" 2>&1
ret=$?
[ "$ret" -eq 0 ] || command cat "$tmp"
exit $ret
