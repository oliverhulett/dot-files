#!/usr/bin/env bash
## Clean local branches who's upstream target has been deleted.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") will clean any local references to branches who's upstream tracking branch has been deleted."
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

GITDIR=".git"
if [ ! -d "${GITDIR}" ]; then
	GITDIR="$(sed -nre 's/^gitdir: (.+)$/\1/p' .git)"
fi
test -d "${GITDIR}" || ( echo "GITDIR not found: $GITDIR"; file .git; exit 1 )
GITDIR="$(cd "${GITDIR}" && pwd -P)"

inarray ()
{
	pat="$1";
	shift;
	printf '%s\n' "$@" | grep -qwE "^${pat}$"
}

shopt -s nullglob
HEAD_REFS=()
for r in "${GITDIR}"/refs/remotes/*/HEAD; do
	ref="$(sed -nre 's/^ref: (.+)$/\1/p' "$r")"
	if [ -n "${ref}" ]; then
		HEAD_REFS[${#HEAD_REFS[@]}]="$(basename -- "${ref}")"
	fi
done

HEADS="${GITDIR}/refs/heads"
test -d "${HEADS}"
(
	cd "${HEADS}" && \
	find ./ -type f | while read -r; do
		b="${REPLY#./}"
		set -- "${GITDIR}"/refs/remotes/*/"${b}"
		if [ $# -eq 0 ] && [ "$(basename -- "$b")" != "master" ] && ! inarray "$(basename -- "$b")" "${HEAD_REFS[@]}"; then
			git branch -d "$b"
		fi
	done
)
