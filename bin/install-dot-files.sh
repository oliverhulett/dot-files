#!/bin/bash

if [ $# -eq 0 ]; then
	SERVERS=( $(ssh-ping.sh 2>/dev/null | sort -u) )
else
	SERVERS=( "$@" )
fi
FILES=( "${HOME}/.bash_profile" "${HOME}/.profile" "${HOME}/.bash_logout" "${HOME}/.bashrc" "${HOME}/.vim" "${HOME}/.vimrc" "${HOME}/.gitconfig" "${HOME}/.git_wrappers" "${HOME}/.gitignore" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.pip/pip.conf" "${HOME}/.pydistutils.cfg" "${HOME}/.pypirc" "${HOME}/.curlrc" "${HOME}/bin" "${HOME}/etc" )

function run()
{
	echo -e "$1\t$2\t${@:3}"
	"$@"
}

for server in "${SERVERS[@]}"; do
	run ssh ${server} 'mkdir .bash_aliases .git_wrappers etc 2>/dev/null'
	run ssh ${server} 'rm -rf pyvenv 2>/dev/null'
	run ssh ${server} 'sh -c "ping -qc1 -W2 git.comp.optiver.com >/dev/null && git clone --recursive ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git etc/dot-files 2>/dev/null"'
	run ssh ${server} 'sh -c "ping -qc1 -W2 git.comp.optiver.com >/dev/null && cd etc/dot-files && git pull && git submodule update"'
done

run dev-push-all.sh --delete --exclude='.git' --exclude='dot-files' "${SERVERS[@]/%/:}" "${FILES[@]}"

for server in "${SERVERS[@]}"; do
	ssh ${server} 'ping -qc1 -W2 git.comp.optiver.com >/dev/null' || rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/etc/dot-files/" ${server}:"${HOME}/etc/dot-files/"
	run ssh ${server} 'find -L .bash_aliases/ -type l -delete'
done
