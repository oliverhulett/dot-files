#!/usr/bin/env bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "-?" ]; then
	echo "$(basename -- $0) [-v] [host...]"
	echo "  Ping each of the hosts listed or each of the hosts in ~/.ssh/known_hosts"
	echo "  -v  Print failures at the end"
	exit 0
fi

VERBOSE="no"
if [ "$1" == "-v" ]; then
	VERBOSE="yes"
	shift
fi

if [ $# -eq 0 ]; then
	set -- $(command cat ${HOME}/.ssh/known_hosts | command grep -vE '^\[?git' | cut -d' ' -f1 | cut -d, -f1 | sort)
fi

declare -a FAILURES
for svr in "$@"; do
	( \
		command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no $svr hostname || \
		command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no -o 'ProxyCommand ssh -W %h:%p sshrelay' $svr 'echo -n sshrelay: && hostname' \
	) 2>&${log_fd} || FAILURES[${#FAILURES[@]}]="$svr"
done

function join()
{
	echo -n "$1"
	shift
	printf "%s" "${@/#/|}"
}

if [ "$VERBOSE" == "yes" ]; then
	echo
	echo "${#FAILURES[@]} Failure(s)"
	echo 'Remove failed hosts with `sed -e '"'/^($(join "${FAILURES[@]}"))/d'"' ~/.ssh/known_hosts -i`'
else
	dotlog "${#FAILURES[@]} Failure(s)"
	dotlog 'Remove failed hosts with `sed -e '"'/^($(join "${FAILURES[@]}"))/d'"' ~/.ssh/known_hosts -i`'
fi

exit ${#FAILURES[@]}
