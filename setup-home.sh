#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd -P)"
RELPATH="${HERE}/bin/relpath.sh"

DOTFILES=
if [ -f "${HERE}/dot-files.$(hostname -s)" ]; then
	echo "Linking dot files from ~/dot-files/dot-files.$(hostname -s)..."
	DOTFILES="${HERE}/dot-files.$(hostname -s)"
elif [ -f "${HERE}/dot-files" ]; then
	echo "Linking dot files from ~/dot-files/dot-files..."
	DOTFILES="${HERE}/dot-files"
fi
if [ -n "${DOTFILES}" ]; then
	find "${HOME}" -xdev -type l -lname '*dot-files/*' -delete 2>/dev/null
	## SRC is relative to $HERE.  TARGET is relative to $HOME
	while read SRC TARGET; do
		DEST="${HOME}/${TARGET}"
		rm "${DEST}" 2>/dev/null
		mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
		( cd "$(dirname "${DEST}")" && ln -sf "$(${RELPATH} . "${HERE}/${SRC}")" "$(basename "${DEST}")" )
	done <"${DOTFILES}"
else
	echo "No dot-files file found, not linking anything..."
fi

if [ -f "${HERE}/crontab.$(hostname -s)" ]; then
	echo "Installing crontab from ~/dot-files/crontab.$(hostname -s)..."
	crontab <(head -n -2 "${HERE}/crontab.$(hostname -s)")
elif [ -f "${HERE}/crontab" ]; then
	echo "Installing crontab from ~/dot-files/crontab..."
	crontab "${HERE}/crontab"
fi
