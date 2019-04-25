#!/bin/bash
## Update dependencies for a git module.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-c|--clean]"
	echo "    Update dependencies for a git module."
	echo "    -c : Clean dependencies instead of updating them"
}

OPTS=$(getopt -o "hc" --long "help,clean" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

eval set -- "${OPTS}"
CLEAN="false"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help
			exit 0
			;;
		-c | --clean )
			CLEAN="true"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done


if [ "${CLEAN}" == "true" ]; then
	git submodule deinit --force .
else
	git submodule init
	git submodule sync
	git submodule update
fi
