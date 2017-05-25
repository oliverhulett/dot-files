#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-?" ] || [ $# -lt 1 ]; then
	echo "$(basename -- $0) host..."
	echo "  Ping each of the listed hosts.  Stop when connection succeeds.  Will only work when connection succeeds without a password."
	echo "  -v  Print failures at the end"
	exit 0
fi

for svr in "$@"; do
	echo -n "Pinging $svr  "
	while ! command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no $svr 'echo; hostname' 2>&${log_fd}; do
		echo -n "."
	done
	echo
done
