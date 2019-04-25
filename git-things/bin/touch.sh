#!/bin/bash
## Create a new file and add it to the git repository.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") <files...>"
	echo "    Create a new file and add it to the git repository."
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

cd "$GIT_PREFIX" || ( echo "Git failed to cd into your directory: $GIT_PREFIX" && exit 1 )

for f in "$@"; do
	mkdir --parents "$(dirname "$f")" >/dev/null 2>/dev/null || true
done
touch "$@"
git add -Nvf "$@"
