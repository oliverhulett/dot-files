#!/bin/bash

if [ "$!" == "-h" ]; then
	echo "$(basename $0) [-v]"
	echo "  Ping each of the hosts in ~/.ssh/known_hosts"
	echo "  -v  Print failures at the end"
fi

declare -a FAILURES
for svr in $(command cat ${HOME}/.ssh/known_hosts | command grep -vE '^\[?git' | cut -d' ' -f1 | cut -d, -f1); do
	command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no $svr hostname 2>/dev/null || FAILURES[${#FAILURES[@]}]="$svr"
done

function join()
{
	echo -n "$1"
	shift
	printf "%s" "${@/#/|}"
}

if [ "$1" == "-v" ]; then
	echo
	echo "${#FAILURES[@]} Failure(s)"
	echo 'Remove failed hosts with `sed -e '"'/^($(join "${FAILURES[@]}"))/d'"' ~/.ssh/known_hosts -i`'
fi

exit ${#FAILURES[@]}
