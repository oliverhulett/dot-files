#!/bin/bash

HERE="$(cd "$(dirname "$0")" && pwd -P)"
RELPATH="${HERE}/bin/relpath.sh"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "${HERE}/bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup -q
fi

echo "Updating dot-files..."
# Can't pull here, you risk changing this file
( cd "${HERE}" && git submodule init && git submodule sync && git submodule update ) &
disown -r
disown -rh

if [ -f "${HERE}/crontab.$(hostname -s)" ]; then
	echo "Installing crontab from ~/dot-files/crontab.$(hostname -s)..."
	crontab <(head -n -2 "${HERE}/crontab.$(hostname -s)")
elif [ -f "${HERE}/crontab" ]; then
	echo "Installing crontab from ~/dot-files/crontab..."
	crontab "${HERE}/crontab"
fi

DOTFILES=
if [ -f "${HERE}/dot-files.$(hostname -s)" ]; then
	echo "Linking dot files from ~/dot-files/dot-files.$(hostname -s)..."
	DOTFILES="${HERE}/dot-files.$(hostname -s)"
elif [ -f "${HERE}/dot-files" ]; then
	echo "Linking dot files from ~/dot-files/dot-files..."
	DOTFILES="${HERE}/dot-files"
fi
if [ -n "${DOTFILES}" ]; then
	# Find and delete any links pointing to existing dot-files files.  They'll be re-added later.
	# Prune the search of a bunch of directories we know to be large and not have links to dot-files files
	PRUNE="-name repo -prune -o -name pyvenv -prune -o -name .conda -prune"
	find "${HOME}" -xdev \( $PRUNE \) -o -type l -lname '*dot-files/*' -delete 2>/dev/null

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

wait
