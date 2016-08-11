#!/bin/bash

## Wrap SSH to install ID keys.
source "${HOME}/etc/dot-files/bash_common.sh"

get_real_exe ssh >/dev/null
if [ -z "${REAL_SSH}" ]; then
	REAL_SSH="/usr/bin/ssh"
fi
if [ $# -eq 1 ]; then
	user="${1%%@*}"
	target="${1#*@}"
	if [ "${user}" == "${target}" ]; then
		user="$(whoami)"
	fi
	echo "Testing SSH key on ${target}"
	if ! $REAL_SSH ${user}@${target} -o ConnectTimeout=2 -o PasswordAuthentication=no echo "SSH key already installed on ${target}"; then
		ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub ${user}@${target}
	fi
	echo "Testing SSH connection to ${target}"
	host="$($REAL_SSH -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${target} hostname)"
	if [ -n "${host}" ]; then
		$REAL_SSH -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${host} echo "Successfully SSH-ed to ${target} \(which is really ${host}\) as ${user} without a password"
	fi
	echo "Checking environment set-up on ${target}"
	if ! $REAL_SSH ${user}@${target} -o ConnectTimeout=2 -o PasswordAuthentication=no test -d etc/dot-files; then
		install-dot-files.sh ${target}
		$REAL_SSH ${target} 'cd .bash_aliases && ln -s ../etc/dot-files/bash_aliases/* ./'
	fi
fi
$REAL_SSH -Y "$@"

