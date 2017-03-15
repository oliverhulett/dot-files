#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "-?" ]; then
	echo "$(basename $0) [-v] [host...]"
	echo "  Ping each of the hosts in ~/.ssh/known_hosts"
	echo "  -v  Print failures at the end"
	exit 0
fi

VERBOSE="no"
if [ "$1" == "-v" ]; then
	VERBOSE="yes"
	shift
fi

if [ $# -eq 0 ]; then
	set -- $(command cat ${HOME}/.ssh/known_hosts | command grep -vE '^\[?git' | cut -d' ' -f1 | cut -d, -f1)
fi

declare -a FAILURES
for svr in "$@"; do
	command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no $svr hostname 2>&${log_fd} || FAILURES[${#FAILURES[@]}]="$svr"
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
	log "${#FAILURES[@]} Failure(s)"
	log 'Remove failed hosts with `sed -e '"'/^($(join "${FAILURES[@]}"))/d'"' ~/.ssh/known_hosts -i`'
fi

exit ${#FAILURES[@]}
