#!/bin/bash

HERE="$(cd "$(dirname "$0")" && pwd -P)"
source "${HERE}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
RELPATH="${HERE}/bin/relpath.sh"

[ -e "${HOME}/.bash-aliases/49-setup-proxy.sh" ] && source "${HOME}/.bash-aliases/49-setup-proxy.sh" 2>/dev/null

echo "Updating dot-files..."
# Can't pull here, you risk changing this file
( cd "${HERE}" && git submodule init && git submodule sync && git submodule update ) >&${log_fd} &
disown -h 2>/dev/null
disown 2>/dev/null

HOSTNAME="$(hostname -s | tr '[:upper:]' '[:lower:]')"
if [ -f "${HERE}/crontab.${HOSTNAME}" ]; then
	echo "Installing crontab from ~/dot-files/crontab.${HOSTNAME}..."
	crontab "${HERE}/crontab.${HOSTNAME}"
elif [ -f "${HERE}/crontab" ]; then
	echo "Installing crontab from ~/dot-files/crontab..."
	crontab "${HERE}/crontab"
fi

DOTFILES=( "${HERE}/dot-files-common" )
if [ -f "${HERE}/dot-files.${HOSTNAME}" ]; then
	echo "Linking dot files from ~/dot-files/dot-files.${HOSTNAME}..."
	DOTFILES[${#DOTFILES[@]}]="${HERE}/dot-files.${HOSTNAME}"
elif [ -f "${HERE}/dot-files" ]; then
	echo "Linking dot files from ~/dot-files/dot-files..."
	DOTFILES[${#DOTFILES[@]}]="${HERE}/dot-files"
fi

if [ ${#DOTFILES[@]} -ne 0 ]; then
	# Find and delete any links pointing to existing dot-files files.  They'll be re-added later.
	# Prune the search of a bunch of directories we know to be large and not have links to dot-files files
	PRUNE="-name repo -prune -o -name pyvenv -prune -o -name .conda -prune"
	find "${HOME}" -xdev \( $PRUNE \) -o -type l -lname '*/'"$(basename "$HERE")"'/*' -print0 2>&${log_fd} | xargs -0 rm -v 2>&${log_fd} >&${log_fd}

	for df in "${DOTFILES[@]}"; do
		## SRC is relative to $HERE.  TARGET is relative to $HOME
		while read -r SRC TARGET; do
			DEST="${HOME}/${TARGET}"
			rm "${DEST}" 2>/dev/null
			mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
			( cd "$(dirname "${DEST}")" && ln -vsf "$(${RELPATH} . "${HERE}/${SRC}")" "$(basename -- "${DEST}")" ) >&${log_fd}
		done <"${df}"
	done
else
	echo "No dot-files file found, not linking anything..."
fi

if [ -e "${HOME}/etc/git.passwds" ]; then
	GIT_CREDS="${HOME}/.git-credentials"
	rm "${GIT_CREDS}" 2>/dev/null || true
	for f in "${HOME}/etc/git.passwds/"*; do
		b="$(basename -- "$f")"
		user="${b%%@*}"
		addr="${b#*@}"
		echo "https://${user}:$(sed -ne '1p' "$f")@${addr}" >>"${GIT_CREDS}"
	done
	chmod 0600 "${GIT_CREDS}"
fi
