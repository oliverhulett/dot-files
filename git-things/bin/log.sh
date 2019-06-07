#!/usr/bin/env bash
## Show user friendly logs with history as a tree

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-a|--all|-c|--count]"
	echo "    Show user friendly logs with history as a tree"
	echo "    --count=N : The number of lines to print.  Default 10."
}

OPTS=$(getopt -o "hac:" --long "help,all,count:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

COUNT="--max-count=10"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help
			exit 0
			;;
		-c | --count )
			COUNT="--max-count=$2"
			shift 2
			;;
		-a | --all )
			COUNT=
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

if echo "$1" | grep -qwE '[0-9]+'; then
	COUNT="--max-count=$1"
	shift
fi
# shellcheck disable=SC2086 - Double quote to prevent globbing and word splitting.
git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd)%C(bold blue)<%an>%Creset' --abbrev-commit $COUNT "$@"
