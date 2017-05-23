#!/bin/bash
source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

HERE="$(cd "$(dirname "$0")" && pwd -P)"
RELPATH="${HERE}/bin/relpath.sh"

[ -e "${HOME}/.bash_aliases/49-setup-proxy.sh" ] && source "${HOME}/.bash_aliases/49-setup-proxy.sh" 2>/dev/null

echo "Updating dot-files..."
# Can't pull here, you risk changing this file
( cd "${HERE}" && git submodule init && git submodule sync && git submodule update ) >&${log_fd} &
disown -h 2>/dev/null
disown 2>/dev/null

HOSTNAME="$(hostname -s | tr A-Z a-z)"
if [ -f "${HERE}/crontab.${HOSTNAME}" ]; then
	echo "Installing crontab from ~/dot-files/crontab.${HOSTNAME}..."
	crontab <(head -n -2 "${HERE}/crontab.${HOSTNAME}")
elif [ -f "${HERE}/crontab" ]; then
	echo "Installing crontab from ~/dot-files/crontab..."
	crontab "${HERE}/crontab"
fi

DOTFILES=
if [ -f "${HERE}/dot-files.${HOSTNAME}" ]; then
	echo "Linking dot files from ~/dot-files/dot-files.${HOSTNAME}..."
	DOTFILES="${HERE}/dot-files.${HOSTNAME}"
elif [ -f "${HERE}/dot-files" ]; then
	echo "Linking dot files from ~/dot-files/dot-files..."
	DOTFILES="${HERE}/dot-files"
fi
if [ -n "${DOTFILES}" ]; then
	# Find and delete any links pointing to existing dot-files files.  They'll be re-added later.
	# Prune the search of a bunch of directories we know to be large and not have links to dot-files files
	PRUNE="-name repo -prune -o -name pyvenv -prune -o -name .conda -prune"
	find "${HOME}" -xdev \( $PRUNE \) -o -type l -lname '*dot-files/*' -print0 2>&${log_fd} | xargs -0 rm -v 2>&${log_fd} >&${log_fd}

	## SRC is relative to $HERE.  TARGET is relative to $HOME
	while read SRC TARGET; do
		DEST="${HOME}/${TARGET}"
		rm "${DEST}" 2>/dev/null
		mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
		( cd "$(dirname "${DEST}")" && ln -vsf "$(${RELPATH} . "${HERE}/${SRC}")" "$(basename -- "${DEST}")" ) >&${log_fd}
	done <"${DOTFILES}"
else
	echo "No dot-files file found, not linking anything..."
fi

if [ -e "${HOME}/etc/passwd.github" ]; then
	GIT_CREDS="${HOME}/.git-credentials"
	rm "${GIT_CREDS}" 2>/dev/null || true
	echo "https://oliverhulett:$(sed -ne '1p' "${HOME}/etc/passwd.github")@github.com" >>"${GIT_CREDS}"
	chmod 0600 "${GIT_CREDS}"
fi
