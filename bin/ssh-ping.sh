#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-?" ] || [ $# -lt 1 ]; then
	echo "$(basename -- $0) host..."
	echo "  Ping each of the listed hosts.  Stop when connection succeeds.  Will only work when connection succeeds without a password."
	exit 0
fi

for svr in "$@"; do
	relay_cmd=()
	relay="${svr%%:*}"
	if [ "${relay}" == "${svr}" ]; then
		relay=
	else
		svr="${svr#*:}"
		if [ -n "${relay}" ]; then
			relay_cmd=( "-o" "ProxyCommand ssh -W %h:%p ${relay}" )
		fi
	fi
	svr="$(ssh-name.sh "$relay:$svr" || echo "$svr")"

	echo -n "Pinging $svr  "
	while ! command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no "${relay_cmd[@]}" $svr 'echo; hostname' 2>&${log_fd}; do
		echo -n "."
	done
	echo
done
