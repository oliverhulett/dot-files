#!/bin/bash

existing_msg="$(cat .git/COMMIT_EDITMSG | sed -re '/^#/d')"

echo $existing_msg
git status

branch="$(git branch --no-color | sed -nre 's/^\* //p' | cut -d'_' -f1)"
if [ "$branch" == "master" ]; then
	branch=
	read -p "Prepend a ticket to commit message? [Y/n/q] " -n1 -r
	echo
	if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "n" ]; then
		branch=
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "q" ]; then
		exit
	else
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
	fi
else
	read -p "Prepend ticket ($branch) to commit message? [Y/n/o/q] " -n1 -r
	echo
	if [ "`echo $REPLY | tr [A-Z] [a-z]`" == "n" ]; then
		branch=
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "o" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "q" ]; then
		exit
	else
		branch="$branch:  "
	fi
fi

sed -re '/^#/! s/^('"${branch}"')?(.+)/'"${branch}"'\2/' .git/COMMIT_EDITMSG -i

vim -c "autocmd InsertLeave <buffer> let [c, l] = [getpos('.'), strlen(getline('.'))]" -c "autocmd InsertLeave <buffer> 1,!sed -re 's/^(${branch})?(.+)/${branch}\2/'" -c "autocmd InsertLeave <buffer> call setpos('.', c) | if l < strlen(getline('.')) | call setpos('.', [c[0], c[1], c[2] + ${#branch}, c[3]])" "$@"

