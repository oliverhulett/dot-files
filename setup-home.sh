#!/bin/bash
source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

HERE="$(cd "$(dirname "$0")" && pwd -P)"
RELPATH="/usr/local/bin/relpath.sh"

chmod +x "${HERE}/src/install" "${HERE}/setup-home.sh" "${HERE}/lessfilter" "${HERE}/tests/run.sh"
"${HERE}/src/install" -k ${HERE}/src/*.*

DOTFILES=
if [ -f "${HERE}/dot-files.$(hostname -s | tr '[A-Z]' '[a-z]')" ]; then
	echo "Linking dot files from ~/dot-files/dot-files.$(hostname -s | tr '[A-Z]' '[a-z]')..."
	DOTFILES="${HERE}/dot-files.$(hostname -s | tr '[A-Z]' '[a-z]')"
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

if [ -f "${HERE}/crontab.$(hostname -s | tr '[A-Z]' '[a-z]')" ]; then
	echo "Installing crontab from ~/dot-files/crontab.$(hostname -s | tr '[A-Z]' '[a-z]')..."
	crontab "${HERE}/crontab.$(hostname -s | tr '[A-Z]' '[a-z]')"
fi

#GIT_CREDS="${HOME}/.git-credentials"
#rm "${GIT_CREDS}" 2>/dev/null || true
#echo "https://oliverhulett:$(sed -ne '1p' "${HOME}/etc/passwd.github")@github.com" >>"${GIT_CREDS}"
#chmod 0600 "${GIT_CREDS}"
