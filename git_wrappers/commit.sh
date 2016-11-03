#!/bin/bash

## Early exist to a generic editor for things that aren't commits.
if ! [ $# -eq 1 -a "$1" -ef .git/COMMIT_EDITMSG ]; then
	$VISUAL "$@" || vim "$@"
	exit
fi

existing_msg="$(cat .git/COMMIT_EDITMSG | sed -re '/^#/d;/^$/d')"

echo "$existing_msg"
echo
git status

branch="$(git branch --no-color | sed -nre 's/^\* //p' | cut -d'_' -f1)"
startmode="-c startinsert"
if [ "$branch" == "master" ]; then
	branch=
	read -p "Prepend a ticket to commit message? [y/N/q] " -n1 -r
	echo
	if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "y" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
		REPLY=
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "q" ]; then
		exit
	else
		branch=
		if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "n" ]; then
			REPLY=
		fi
	fi
else
	read -p "Prepend ticket ($branch) to commit message? [Y/n/o/q] " -n1 -r
	echo
	if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "n" ]; then
		branch=
		REPLY=
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "o" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
		REPLY=
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "q" ]; then
		exit
	else
		branch="$branch:  "
		if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "y" ]; then
			REPLY=
		fi
	fi
fi

## If .git/COMMIT_EDITMSG is not empty, don't start vim in insert mode.
if grep -qE '^[^#].*$' .git/COMMIT_EDITMSG 2>/dev/null >/dev/null; then
	startmode=
fi

## If .git/COMMIT_EDITMSG contains a non-branch prefixed message, don't auto-prefix lines.
if ! sed -re '/^#/! s/^('"${branch}"')?(.+)/'"${branch}"'\2/' .git/COMMIT_EDITMSG -i; then
	$VISUAL "$@" || vim "$@"
	exit
fi

function special_vim()
{
	vim -c "autocmd InsertLeave <buffer> let [c, l] = [getpos('.'), strlen(getline('.'))]" -c "autocmd InsertLeave <buffer> 1,!sed -re 's/^(${branch})?(.+)/${branch}\2/'" -c "autocmd InsertLeave <buffer> call setpos('.', c) | if l < strlen(getline('.')) | call setpos('.', [c[0], c[1], c[2] + ${#branch}, c[3]])" $startmode "$@"
}

echo "Type a simple, single line, commit message that will be prefixed with the ticket name; or press 'e' or type 'edit' to launch ${VISUAL:-vim}"
msg="${REPLY}"
read -r -n1 -s
if [ "${REPLY}" == "e" -o "${REPLY}" == "E" ]; then
	special_vim "$@"
elif [ -n "${REPLY}" ]; then
	read -ei ${msg}${REPLY}
	if [ "$(echo ${REPLY} | tr '[A-Z]' '[a-z]')" == "edit" -o "${REPLY}" == "e" -o "${REPLY}" == "E" ]; then
		special_vim "$@"
	else
		if [ -n "${REPLY}" ]; then
			echo "${branch}${REPLY}" >.git/COMMIT_EDITMSG
		fi
	fi
fi
echo
