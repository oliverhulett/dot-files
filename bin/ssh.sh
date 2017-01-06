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
	echo "Checking environment set-up on ${target}"
	if ! command ssh ${user}@${target} -o ConnectTimeout=2 -o PasswordAuthentication=no test -d dot-files; then
		install-dot-files.sh ${target}
		command ssh ${target} 'cd .bash_aliases && ln -s ../dot-files/bash_aliases/* ./'
	fi
fi
command ssh -Y "$@"

