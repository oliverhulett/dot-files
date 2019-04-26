#!/usr/bin/env bash
# Allegories of `which`, `type`, and `alias` for git.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") <CMDS...>"
	echo "    <CMDS...>:     The commands to look for."
}

OPTS=$(getopt -o "ha" --long "help,all" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

ALL="no"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-a | --all )
			ALL="yes"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

rv=0
for cmd in "$@"; do
	preamble="\`git ${cmd}' is"
	found="no"
	for o in "$(command which "git-${cmd}" 2>/dev/null)" \
	         "$(command git config "alias.${cmd}" 2>/dev/null)"; do
		if [ -n "$o" ]; then
			printf "%s: %s\n" "$preamble" "$o"
			preamble="$(printf "% ${#preamble}s" " ")"
			found="yes"
		fi
		if [ "$found" == "yes" ] && [ "$ALL" == "no" ]; then
			break
		fi
	done
	if [ "$found" == "no" ]; then
		echo "$preamble: not found"
		rv=$(( rv + 1 ))
	fi
done

exit $rv
