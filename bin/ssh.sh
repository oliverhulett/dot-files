#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

echo "$0" "$@"
## Wrap SSH to install ID keys.
if [ $# -eq 1 ]; then
	user="${1%%@*}"
	target="${1#*@}"
	if [ "${user}" == "${target}" ]; then
		user="$(whoami)"
	fi

	echo "Looking up ${target} in DNS"
	if ! command nslookup "${target}" >/dev/null; then
		name="$(ssh-name.sh "$target")"
		if [ -n "$name" ]; then
			echo "DNS lookup failed; guessing at $name from convention"
			target="$name"
		else
			echo "DNS lookup failed; couldn't guess a name; continuing with $target anyway"
		fi
	fi

	echo "Testing SSH key on ${target}"
	if ! command ssh ${user}@${target} -o ConnectTimeout=2 -o PasswordAuthentication=no echo "SSH key already installed on ${target}" 2>/dev/null; then
		ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub ${user}@${target} 2>/dev/null
	fi

	echo "Testing SSH connection to ${target}"
	host="$(command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${target} hostname 2>/dev/null)"
	if [ -n "${host}" ]; then
		command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no ${user}@${host} echo "Successfully SSH-ed to ${target} \(which is really ${host}\) as ${user} without a password" 2>/dev/null
	fi

	# The `if' statement above ensures there was only one command line argument to begin with,
	# we can safely re-write them now that we're sure of the target.
	set -- "${user}@${target}"

	echo "Setting up environment on ${target}"
	# Don't actually want submodules here, leave that to install-dot-files.sh
	command ssh ${target} 'git clone ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git ${HOME}/dot-files 2>/dev/null; cd ${HOME}/dot-files && git pull' 2>/dev/null
	command ssh ${target} 'test -d ${HOME}/dot-files/.git' 2>/dev/null || run rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${target}:"${HOME}/dot-files/" 2>/dev/null
	command ssh ${target} '${HOME}/dot-files/setup-home.sh' 2>/dev/null

	install-dot-files.sh ${target} >&${log_fd} 2>&${log_fd} &
	disown -h 2>/dev/null
	disown 2>/dev/null
fi
eval "${uncapture_output}"
command ssh -Y "$@"
