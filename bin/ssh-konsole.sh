#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

SSH="${HERE}/ssh.sh"
SSH_NAME="${HERE}/ssh-name.sh"

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
		break
	fi
done

CMD=( "${SSH}" "${WHO}@${WHERE}" )

if [ -z "$(command which konsole 2>/dev/null)" ]; then
	if [ -t 0 ]; then
		echo "Konsole not found, will SSH directly..."
		exec "${CMD[@]}"
	else
		kdialog --sorry "Konsole not found, will not be able to SSH to server..."
		exit 1
	fi
else
	## TODO:  SSH-ing to a new server here (e.g. needing to install ssh-keys) poped up a KWallet dialog looking for a password.
	## Why?  ssh-askpass perhaps?
	## Also, where has my random background colouring gone?  They're transparrent now, but not coloured :(
	echo "Launching new Konsole window..."
	exec konsole --profile "Random-SSH-Server" -p "tabTitle=${WHO}@${WHERE}" --name "${WHO}@${WHERE}" --title "${WHO}@${WHERE}" -e "${CMD[@]}"
fi
