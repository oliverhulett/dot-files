#!/bin/bash
# Allegories of `which`, `type`, and `alias` for git.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
set -x

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") <CMDS...>"
	echo "    <CMDS...>:     The commands to look for."
}

OPTS=$(getopt -o "h" --long "help" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

for cmd in "$@"; do
	echo -n "\`git ${cmd}' is: "
	command which git-${cmd} 2>/dev/null || git config alias.${cmd}
done
