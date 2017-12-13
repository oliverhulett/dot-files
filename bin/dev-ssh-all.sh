#!/bin/bash
#
#	Run an SSH command on the development servers.
#
HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ $# == 0 ]; then
	echo "$0 COMMAND..."
	echo "Run COMMAND on all servers in ~/.ssh/known_hosts"
	exit 1
fi

declare -a DEV_SRVS=( $(ssh-list.sh 2>/dev/null | sort -u) )

trap wait EXIT

for srv in "${DEV_SRVS[@]}"; do
	relay_cmd=()
	relay="${srv%%:*}"
	if [ "${relay}" == "${srv}" ]; then
		relay=
	else
		srv="${srv#*:}"
		if [ -n "${relay}" ]; then
			relay_cmd=( "-o" "ProxyCommand ssh -W %h:%p ${relay}" )
		fi
	fi
	srv="$(ssh-name.sh "$relay:$srv")"

	if [ -z "$srv" ]; then
		continue
	fi
	if [ "$srv" = "localhost" ]; then
		continue
	fi
	if [ "$srv" = "$(hostname)" ]; then
		continue
	fi
	echo "Server: $srv  ============================================================================"
	ssh "${relay_cmd[@]}" ${USER}@${srv} "$@" 2>&${log_fd} &
	echo
done
