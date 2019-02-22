#!/usr/bin/env bash

HERE="$(cd "$(dirname "$0")" && pwd -P)"
source "${HERE}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true
## Be careful prepending to path here, setup is called by tests and you might break bats-mock
PATH="$(append_path "${PATH}" "${HERE}/bin" "/usr/local/bin" "/usr/bin" "/bin")"
export PATH

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
	# shellcheck disable=SC2089
	PRUNE="-name $(basename -- "${HERE}") -prune"
	for i in Applications Downloads Music src Desktop Library Pictures etc tmp Documents Movies Public repo .backups; do
		PRUNE="${PRUNE} -o -name $i -prune"
	done
	# shellcheck disable=SC2086
	find "${HOME}" -xdev \( $PRUNE \) -o -type l -lname '*/'"$(basename -- "$HERE")"'/*' -print0 2>&${log_fd} | xargs -0 rm -v 2>&${log_fd} >&${log_fd}

	for df in "${DOTFILES[@]}"; do
		## SRC is relative to $HERE.  TARGET is relative to $HOME
		while read -r SRC TARGET; do
			DEST="${HOME}/${TARGET}"
			rm "${DEST}" 2>/dev/null
			mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
			( cd "$(dirname "${DEST}")" && ln -vsf "$(relpath.sh . "${HERE}/${SRC}")" "$(basename -- "${DEST}")" ) >&"${log_fd}"
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

if [ -e "${HOME}/etc/ngrok.yml" ]; then
	DEST="${HOME}/.ngrok2/ngrok.yml"
	rm "${DEST}" 2>/dev/null
	mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
	ln -s "$(relpath.sh "$(dirname "${DEST}")" "${HOME}/etc/ngrok.yml" )" "${DEST}" >&"${log_fd}"
fi

if [ -e "${HOME}/etc/authrc" ]; then
	DEST="${HOME}/.authrc"
	rm "${DEST}" 2>/dev/null
	mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
	ln -s "$(relpath.sh "$(dirname "${DEST}")" "${HOME}/etc/authrc" )" "${DEST}" >&"${log_fd}"
fi

if [ -e "${HOME}/etc/npmrc" ]; then
	DEST="${HOME}/.npmrc"
	rm "${DEST}" 2>/dev/null
	mkdir --parents "$(dirname "${DEST}")" 2>/dev/null
	ln -s "$(relpath.sh "$(dirname "${DEST}")" "${HOME}/etc/npmrc" )" "${DEST}" >&"${log_fd}"
fi

if [ ! -e "${HERE}/.git/hooks/pre-push" ] || [ ! "${HERE}/.git/hooks/pre-push" -ef "${HERE}/git-wrappers/pre-push.sh" ]; then
	rm -f "${HERE}/.git/hooks/pre-push" || true
	ln -sv "${HERE}/git-wrappers/pre-push.sh" "${HERE}/.git/hooks/pre-push"
fi
