#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ "$1" == "-h" ] || [ "$1" == "-?" ] || [ "$1" == "--help" ]; then
	echo "chronic.sh <cmd...>"
	echo "Run the command and print the output only if the command fails"
	exit 0
fi
tmp="$(mktemp)" || return
trap 'rm -f "$tmp"' EXIT
"$@" >"$tmp" 2>&1
ret=$?
if [ "$ret" -ne 0 ]; then
	echo
	echo "Ran: $*"
	echo "Exit code: $ret"
	echo
	command cat "$tmp"
else
	while read -r; do
		dotlog "[$(basename -- "$1")] ${REPLY}"
	done <"$tmp"
fi
exit $ret
