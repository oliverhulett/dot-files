#!/bin/bash

if [ $# -eq 0 ]; then
	SERVERS=( $(ssh-ping.sh 2>/dev/null | sort -u) )
else
	SERVERS=( "$@" )
fi
FILES=( "${HOME}/.bash_profile" "${HOME}/.profile" "${HOME}/.bash_logout" "${HOME}/.bashrc" "${HOME}/.vim" "${HOME}/.vimrc" "${HOME}/.gitconfig" "${HOME}/.git_wrappers" "${HOME}/.gitignore" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.pydistutils.cfg" "${HOME}/.pypirc" "${HOME}/.curlrc" "${HOME}/bin" "${HOME}/etc" )

function run()
{
	echo -e "$1\t$2\t${@:3}"
	"$@"
}

for server in "${SERVERS[@]}"; do
	run ssh ${server} 'mkdir ${HOME}/.bash_aliases ${HOME}/etc 2>/dev/null'
	run ssh ${server} 'sh -c "ping -qc1 -W2 git.comp.optiver.com >/dev/null && cd ${HOME} && yes | git clone --recursive ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git dot-files 2>/dev/null"'
	run ssh ${server} 'sh -c "ping -qc1 -W2 git.comp.optiver.com >/dev/null && cd ${HOME}/dot-files && git pull && git submodule init && git submodule sync && git submodule update"'
done

run dev-push-all.sh --delete "${SERVERS[@]/%/:}" "${FILES[@]}"

for server in "${SERVERS[@]}"; do
	ssh ${server} 'ping -qc1 -W2 git.comp.optiver.com >/dev/null' || rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${server}:"${HOME}/dot-files/"
	run ssh ${server} 'find -L ${HOME}/.bash_aliases/ -type l -delete'
done
