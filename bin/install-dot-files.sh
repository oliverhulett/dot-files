#!/bin/bash

if [ $# -eq 0 ]; then
	SERVERS=( $(ssh-ping.sh 2>/dev/null | sort -u) )
else
	SERVERS=( "$@" )
fi
FILES=( "${HOME}/.bash_profile" "${HOME}/.profile" "${HOME}/.bash_logout" "${HOME}/.bashrc" "${HOME}/.vim" "${HOME}/.vimrc" "${HOME}/.gitconfig" "${HOME}/.git_wrappers" "${HOME}/.gitignore" "${HOME}/etc/dot-files" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.pip/pip.conf" "${HOME}/.pydistutils.cfg" "${HOME}/.pypirc" "${HOME}/.curlrc" "${HOME}/bin" "${HOME}/etc" )

for server in "${SERVERS[@]}"; do
	ssh ${server} 'mkdir .bash_aliases .git_wrappers 2>/dev/null'
done

dev-push-all.sh --delete --exclude='.git' "${SERVERS[@]/%/:}" "${FILES[@]}"
for server in "${SERVERS[@]}"; do
	ssh ${server} 'find -L .bash_aliases/ .git_wrappers/ bin/ -type l -delete'
done

