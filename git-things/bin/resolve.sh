#!/usr/bin/env bash
## Resolve conflicts and add them.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") <conflicted files...>"
	echo "    Resolve conflicts and add them to git"
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

if [ $# -eq 0 ]; then
	# shellcheck disable=SC2046 -- Quote this to prevent word splitting.
	set -- $(git diff --name-only --diff-filter=U)
fi

cd "$GIT_PREFIX" || ( echo "git could not cd into your directory: $GIT_PREFIX" && exit 1 )

vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$@"

read -n1 -rp"Resolved? [y/N]: "
echo
if [ "$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')" == "y" ]; then
	git add "$@"
fi
