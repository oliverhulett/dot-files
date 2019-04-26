#!/usr/bin/env bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true

## Early exit to a generic editor for things that aren't commits.
if ! [ $# -eq 1 ] || ! [ "$1" -ef .git/COMMIT_EDITMSG ]; then
	eval "${uncapture_output}"
	$VISUAL "$@" || vim "$@"
	exit
fi

sed -re '/^#/d;/^$/d' .git/COMMIT_EDITMSG
echo
git status

branch="$(git branch --no-color | sed -nre 's/^\* //p' | rev | cut -d'/' -f1 | rev | cut -d'_' -f1)"
startmode="-c startinsert"

## If .git/COMMIT_EDITMSG is not empty, don't start vim in insert mode.
if grep -qE '^[^#].*$' .git/COMMIT_EDITMSG 2>/dev/null >/dev/null; then
	startmode=
fi

function special_vim()
{
	eval "${uncapture_output}"
	vim $startmode "$@"
	#vim -c "autocmd InsertLeave <buffer> let [c, l] = [getpos('.'), strlen(getline('.'))]" -c "autocmd InsertLeave <buffer> 1,!sed -re 's!^(${branch})?(.+)!${branch}\2!'" -c "autocmd InsertLeave <buffer> call setpos('.', c) | if l < strlen(getline('.')) | call setpos('.', [c[0], c[1], c[2] + ${#branch}, c[3]])" $startmode "$@"
}

function tolower()
{
	tr '[:upper:]' '[:lower:]' <<<"$*"
}
function ieq()
{
	test "$(tolower "$1")" == "$(tolower "$2")"
}

MSG_PROMPT="Enter a short (single line) commit message.  Press 'e' or enter 'edit' to launch \`vim'.  Press 'd' or enter 'diff' to see the commit diff."
while true; do
	echo "${MSG_PROMPT}"
	read -r -n1 -s
	if ieq "${REPLY}" "e" ; then
		special_vim "$@"
	elif ieq "${REPLY}" "d"; then
		git diff --cached
		continue
	elif [ -n "${REPLY}" ]; then
		msg="$REPLY"
		read -rei "${REPLY}"
		msg="$(col -b <<<"${msg}$REPLY")"
		if ieq "${msg}" "edit" || ieq "${msg}" "e"; then
			special_vim "$@"
		elif ieq "${msg}" "diff" || ieq "${msg}" "d"; then
			git diff --cached
			continue
		else
			if [ -n "${msg}" ]; then
				echo "${msg}" >.git/COMMIT_EDITMSG
			fi
		fi
	fi
	echo
	break
done

if [ "$branch" == "master" ]; then
	read -p "Prepend a ticket to commit message? [y/N] " -n1 -r
	echo
	if ieq "${REPLY}" "y"; then
		read -p "$(tput bold)Ticket:$(tput sgr0)  " -r
		sed -re '1s/^([^\w]+: )?/'"$REPLY"': /' -i .git/COMMIT_EDITMSG
	fi
else
	read -p "Prepend ticket ($branch) to commit message? [Y/n/o] " -n1 -r
	echo
	if ieq "$REPLY" "n"; then
		sed -re '1s/^([^\w]+: )?//' -i .git/COMMIT_EDITMSG
	elif ieq "$REPLY" "o"; then
		read -p "$(tput bold)Ticket:$(tput sgr0)  " -r
		sed -re '1s/^([^\w]+: )?/'"$REPLY"': /' -i .git/COMMIT_EDITMSG
	else
		sed -re '1s/^([^\w]+: )?/'"$branch"': /' -i .git/COMMIT_EDITMSG
	fi
fi
