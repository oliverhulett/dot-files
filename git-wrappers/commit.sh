#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${setup_log_fd}" || true

## Early exist to a generic editor for things that aren't commits.
if ! [ $# -eq 1 ] || ! [ "$1" -ef .git/COMMIT_EDITMSG ]; then
	$VISUAL "$@" || vim "$@"
	exit
fi

existing_msg="$(sed -re '/^#/d;/^$/d' .git/COMMIT_EDITMSG)"

echo "$existing_msg"
echo
git status

branch="$(git branch --no-color | sed -nre 's/^\* //p' | cut -d'_' -f1 | sed -re 's!^[^/]+/!!')"
startmode="-c startinsert"
if [ "$branch" == "master" ]; then
	branch=
	read -p "Prepend a ticket to commit message? [y/N/q] " -n1 -r
	echo
	if [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "y" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read -r
		branch="$REPLY:  "
		REPLY=
	elif [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "q" ]; then
		exit
	else
		branch=
		if [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "n" ]; then
			REPLY=
		fi
	fi
else
	read -p "Prepend ticket ($branch) to commit message? [Y/n/o/q] " -n1 -r
	echo
	if [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "n" ]; then
		branch=
		REPLY=
	elif [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "o" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read -r
		branch="$REPLY:  "
		REPLY=
	elif [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "q" ]; then
		exit
	else
		branch="$branch:  "
		if [ "$(echo $REPLY | tr '[:upper:]' '[:lower:]')" == "y" ]; then
			REPLY=
		fi
	fi
fi

## If .git/COMMIT_EDITMSG is not empty, don't start vim in insert mode.
if grep -qE '^[^#].*$' .git/COMMIT_EDITMSG 2>/dev/null >/dev/null; then
	startmode=
fi

## If .git/COMMIT_EDITMSG contains a non-branch prefixed message, don't auto-prefix lines.
if ! sed -re '/^#/! s!^('"${branch}"')?(.+)!'"${branch}"'\2!' .git/COMMIT_EDITMSG -i; then
	$VISUAL "$@" || vim "$@"
	exit
fi

function special_vim()
{
	eval "${uncapture_output}"
	vim -c "autocmd InsertLeave <buffer> let [c, l] = [getpos('.'), strlen(getline('.'))]" -c "autocmd InsertLeave <buffer> 1,!sed -re 's!^(${branch})?(.+)!${branch}\2!'" -c "autocmd InsertLeave <buffer> call setpos('.', c) | if l < strlen(getline('.')) | call setpos('.', [c[0], c[1], c[2] + ${#branch}, c[3]])" $startmode "$@"
}

echo "Type a simple, single line, commit message that will be prefixed with the ticket name; or press 'e' or type 'edit' to launch ${VISUAL:-vim}"
msg="${REPLY}"
read -r -n1 -s
if [ "${REPLY}" == "e" ] || [ "${REPLY}" == "E" ]; then
	special_vim "$@"
elif [ -n "${REPLY}" ]; then
	read -rei ${msg}${REPLY}
	if [ "$(echo ${REPLY} | tr '[:upper:]' '[:lower:]')" == "edit" ] || [ "${REPLY}" == "e" ] || [ "${REPLY}" == "E" ]; then
		special_vim "$@"
	else
		if [ -n "${REPLY}" ]; then
			echo "${branch}${REPLY}" >.git/COMMIT_EDITMSG
		fi
	fi
fi
echo
