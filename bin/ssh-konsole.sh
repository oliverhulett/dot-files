#!/bin/bash

SSH="$(dirname "$0")/ssh.sh"
SSH_NAME="$(dirname "$0")/ssh-name.sh"
KONSOLE=( "konsole" "--profile" "Random-SSH-Server" "-e" )

WHERE_PROMPT="Where would you like to go today?"
WHERE=
WHO_PROMPT="As whom would you like to SSH?"
WHO="$(whoami)"

function svr_is_valid()
{
	MSG="$("${SSH_NAME}" "${WHERE}" 2>&1)"
	if [ $? -ne 0 ]; then
		kdialog --dontagain ssh-konsole:badsvr --msgbox "${MSG}"
		return 1
	fi
	return 0
}

if [ -z "$(command which "${KONSOLE[0]}" 2>/dev/null)" ]; then
	if [ -t 0 ]; then
		echo "Konsole not found, will SSH directly..."
		KONSOLE=()
	else
		kdialog --sorry "Konsole not found, will not be able to SSH to server..."
		exit 1
	fi
fi

while true; do
	WHERE="$(kdialog --title "Random SSH Server" --inputbox "${WHERE_PROMPT}" "${WHERE}")"
	if [ $? -ne 0 ]; then
		exit 1
	fi
	WHO="$(kdialog --title "Random SSH Server" --inputbox "${WHO_PROMPT}" "${WHO}")"
	if [ $? -ne 0 ]; then
		exit 1
	fi

	if svr_is_valid; then
		exec "${KONSOLE[@]}" "${SSH}" "${WHO}"@"$("${SSH_NAME}" "${WHERE}")"
	fi
done
