#!/bin/bash
## Copy files and then add them to git

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") <files to copy...>"
	echo "    Copy files and then add them to git."
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

cd "$GIT_PREFIX" || ( echo "git could not cd into your directory: $GIT_PREFIX" && exit 1 )

cp -nv "$@"

declare -a toadd
dest="${*:$#}"
for arg in "${@:1:$# - 1}"; do
	if [ "${arg:0:1}" != "-" ]; then
		toadd[${#toadd[@]}]="${dest}/$(basename -- "$arg")"
	fi
done

if [ ${#toadd[@]} -eq 1 ] && [ ! -d "${toadd[0]}" ]; then
	toadd=( "${dest}" )
fi

git add -v --ignore-removal --ignore-errors "${toadd[@]}"
