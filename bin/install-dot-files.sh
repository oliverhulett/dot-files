#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ $# -eq 0 ]; then
	SERVERS=( $(ssh-list.sh 2>/dev/null | sort -u) )
else
	SERVERS=( "$@" )
fi
FILES=( "${HOME}/.ssh/config" "${HOME}/.ssh/known_hosts" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/olihul_rsa" "${HOME}/.ssh/olihul_rsa.pub" "${HOME}/etc" )

function run()
{
	echo -e "$1\t$2\t" "${@:3}"
	"$@"
}

run dev-push-all.sh --delete --exclude='backups/' "${SERVERS[@]/%/:}" "${FILES[@]}"

function hsh()
{
	command ssh "${relay_cmd[@]}" "${server}" '( cd "${HOME}/dot-files" && git rev-parse HEAD ) || ( find -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum )'
}

for server in "${SERVERS[@]}"; do
	relay_cmd=()
	rsync_relay_cmd=()
	relay="${server%%:*}"
	if [ "${relay}" == "${server}" ]; then
		relay=
	else
		server="${server#*:}"
		if [ -n "$relay" ]; then
			relay_cmd=( "-o" "ProxyCommand ssh -W %h:%p ${relay}" )
			rsync_relay_cmd=( "-e" "ssh -o 'ProxyCommand ssh -W %h:%p ${relay}'" )
		fi
	fi
	server="$(ssh-name.sh "${relay}:${server}")"

	HASH_B4="$(hsh)"
	command ssh "${relay_cmd[@]}" "${server}" 'git clone ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git ${HOME}/dot-files 2>/dev/null; cd ${HOME}/dot-files && git pull 2>/dev/null'
	command ssh "${relay_cmd[@]}" "${server}" 'test -d ${HOME}/dot-files/.git' || run rsync "${rsync_relay_cmd[@]}" --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${server}:"${HOME}/dot-files/"
	command ssh "${relay_cmd[@]}" "${server}" '${HOME}/dot-files/setup-home.sh'
	## TODO:  Special case for Vundle, copy if clone fails?  Or make sure vim and edt works without
	HASH_AFTER="$(hsh)"
	if [ "${HASH_B4}" != "${HASH_AFTER}" ]; then
		echo -e "\n\tUpdated dot-files; please re-source ~/.bashrc\n" | command ssh "${relay_cmd[@]}" "${server}" "write $(whoami)"
	fi
done
