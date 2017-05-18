#!/bin/bash

OPTS=$(getopt -o "chptvl:" --long "count,help,pretty,tap,version,parallel:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	bats --help
	exit $es
fi

PARALLEL=$(nproc)
PARALLEL=1
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
		-l | --parallel )
			if [ -z "$2" ] || ! echo "$2" | command grep -vqE '[0-9]+' 2>/dev/null || [ $2 -le 0 ]; then
				PARALLEL=1
			else
				PARALLEL=$2
			fi
			shift 2
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

function get_all_tests()
{
	find "$(dirname "${BASH_SOURCE[0]}")" -not \( -name '.git' -prune -or -name '.svn' -prune -or -name '.venv' -prune -or -name '.virtualenv' -prune -or -name 'x_*' -prune \) \( -name '*.bats' \) | sort -u
}


function checkprocs()
{
	( cd /proc >/dev/null 2>/dev/null && command ls -1d "$@" 2>/dev/null )
}

if [ $# -eq 0 ]; then
	set -- $(get_all_tests)
fi

NUM_TESTS=$(bats --count "$@")
if [ $# -lt ${PARALLEL} ]; then
	PARALLEL=$#
fi

export BATS_TMPDIR="/tmp/bats/$(date '+%Y%m%d-%H%M%S')"
export BATS_MOCK_TMPDIR="${BATS_TMPDIR}"
export TMPDIR="${BATS_TMPDIR}"
rm -rf "${BATS_TMPDIR}"
mkdir --parents "${BATS_TMPDIR}"

if [ ${PARALLEL} -eq 1 ]; then
	bats "${ARGS}" "$@"
else
	echo "1..${NUM_TESTS}"
	proclst=
	testnum_offset=0
	for f in "$@"; do
		numtests=$(bats --count "$f")
		( trap "kill 0" EXIT; bats "${ARGS}" "$f" 2>&1; trap - EXIT ) &
		proclst="${proclst} $!"
		testnum_offset=$((testnum_offset + numtests))
	done
	wait ${proclst}
fi
