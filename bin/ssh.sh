#!/bin/bash

## Wrap SSH to install ID keys.
if [ $# -eq 1 ]; then
	user="${1%%@*}"
	target="${1#*@}"
	if [ "${user}" == "${target}" ]; then
		user="$(whoami)"
	fi
	echo "Testing SSH key on ${target}"
	if ! command ssh ${user}@${target} -o ConnectTimeout=2 -o PasswordAuthentication=no echo "SSH key already installed on ${target}"; then
		ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub ${user}@${target}
	fi
	echo "Testing SSH connection to ${target}"
	host="$(command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${target} hostname)"
	if [ -n "${host}" ]; then
		command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${host} echo "Successfully SSH-ed to ${target} \(which is really ${host}\) as ${user} without a password"
	fi
	echo "Setting up environment on ${target}"
	command ssh ${target} 'sh -c "(
		cd ${HOME} 2>/dev/null && git clone --recursive ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git dot-files 2>/dev/null;
		cd ${HOME}/dot-files 2>/dev/null && git pull && git submodule init && git submodule sync && git submodule update )"
	' || run rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${target}:"${HOME}/dot-files/"
	command ssh ${target} '${HOME}/dot-files/setup-home.sh'
	install-dot-files.sh ${target} >/dev/null 2>/dev/null &
fi
command ssh -Y "$@"

