#!/bin/bash

git status

branch="$(git branch --no-color | sed -nre 's/^\* //p' | cut -d'_' -f1)"
if [ "$branch" == "master" ]; then
	branch=
	read -p "Prepend a ticket to commit message? [Y/n] " -n1 -r
	echo
	if [ -z "$REPLY" -o "`echo $REPLY | tr [A-Z] [a-z]`" == "y" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
	fi
else
	read -p "Prepend ticket ($branch) to commit message? [Y/n/o] " -n1 -r
	echo
	if [ -z "$REPLY" -o "`echo $REPLY | tr [A-Z] [a-z]`" == "y" ]; then
		branch="$branch:  "
	elif [ "`echo $REPLY | tr [A-Z] [a-z]`" == "o" ]; then
		echo -n "$(tput bold)Ticket:$(tput sgr0)  "
		read
		branch="$REPLY:  "
	else
		branch=
	fi
fi

vim -c "autocmd InsertLeave <buffer> let [c, l] = [getpos('.'), strlen(getline('.'))]" -c "autocmd InsertLeave <buffer> 1,!sed -re 's/^(${branch})?(.+)/${branch}\2/'" -c "autocmd InsertLeave <buffer> call setpos('.', c) | if l < strlen(getline('.')) | call setpos('.', [c[0], c[1], c[2] + ${#branch}, c[3]])" -c start "$@"

