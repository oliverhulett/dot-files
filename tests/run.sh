#!/bin/bash

OPTS=$(getopt -o "chptv" --long "count,help,pretty,tap,version" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	bats --help
	exit $es
fi

ARGS="-t"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			bats --help
			exit
			;;
		-v | --version )
			bats --version
			exit
			;;
		-c | --count | \
		-p | --pretty | \
		-t | --tap )
			ARGS="$1"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

function get_all_tests()
{
	find "$(dirname "${BASH_SOURCE[0]}")" -not \( -name '.git' -prune -or -name '.svn' -prune -or -name '.venv' -prune -or -name '.virtualenv' -prune -or -name 'x_*' -prune \) \( -name '*.bats' \) -print0 | xargs -0 -n1 dirname | sort -u
}

if [ $# -eq 0 ]; then
	set -- $(get_all_tests)
fi
bats "${ARGS}" "$@"
