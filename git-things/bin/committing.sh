#!/usr/bin/env bash
## Tag a commit message with the issue tag or branch name.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "Tag a commit message with the issue tag or branch name."
	echo "Run 'git commit -h' for more information."
}

for i in "$@"; do
	if [ "$i" == "--help" ] || [ "$i" == "-h" ]; then
		print_help
		exit 0
	fi
done


TICKET="$(git ticket)"
if [ -n "${TICKET}" ]; then
	ARGS=()
	FOUND_FIRST_MSG="no"
	NEXT_IS_FIRST_MSG="no"
	for a in "$@"; do
		if [ "${FOUND_FIRST_MSG}" == "yes" ]; then
			ARGS[${#ARGS[@]}]="$a"
		elif [ "${NEXT_IS_FIRST_MSG}" == "yes" ]; then
			ARGS[${#ARGS[@]}]="${TICKET}: $a"
			FOUND_FIRST_MSG="yes"
		elif [ "$a" == "--message" ] || echo "$a" | grep -qE '^-[a-zA-Z0-9]*m$'; then
			ARGS[${#ARGS[@]}]="$a"
			NEXT_IS_FIRST_MSG="yes"
		else
			NEW_ARG="$(echo "$a" | sed -nre 's/^(--message=)(.+)()$/\1'"${TICKET}: "'\2\3/p')"
			if [ -z "${NEW_ARG}" ]; then
				NEW_ARG="$(echo "$a" | sed -nre 's/^(-[a-ln-zA-Z0-9]*m)(.+)()$/\1'"${TICKET}: "'\2\3/p')"
			fi
			if [ -n "${NEW_ARG}" ] && [ "$a" != "${NEW_ARG}" ]; then
				ARGS[${#ARGS[@]}]="${NEW_ARG}"
				FOUND_FIRST_MSG="yes"
			else
				ARGS[${#ARGS[@]}]="$a"
			fi
		fi
	done
	set -- "${ARGS[@]}"
fi
git commit "$@"
