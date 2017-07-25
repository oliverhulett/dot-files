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
	relay_cmd=()
	relay="${target%%:*}"
	if [ "${relay}" == "${target}" ]; then
		relay=
	else
		target="${target#*:}"
		if [ -n "${relay}" ]; then
			relay_cmd=( "-o" "ProxyCommand ssh -W %h:%p ${relay}" )
		fi
	fi

	echo "Looking up ${target} in DNS"
	if ! command nslookup "${target}" >/dev/null; then
		name="$(ssh-name.sh "${relay}:${target}")"
		if [ -n "$name" ]; then
			echo "DNS lookup failed; guessing at $name from convention"
			target="$name"
		else
			echo "DNS lookup failed; couldn't guess a name; continuing with $target anyway"
		fi
	fi

	echo "Testing SSH key on ${target}"
	if ! command ssh "${relay_cmd[@]}" "${user}@${target}" -o ConnectTimeout=2 -o PasswordAuthentication=no echo "SSH key already installed on ${target}" 2>/dev/null; then
		ssh-copy-id -i "${HOME}/.ssh/id_rsa.pub" "${relay_cmd[@]}" "${user}@${target}" 2>/dev/null
	fi

	echo "Testing SSH connection to ${target}"
	host="$(command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no "${relay_cmd[@]}" "${user}@${target}" hostname 2>/dev/null)"
	if [ -n "${host}" ]; then
		command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no "${relay_cmd[@]}" "${user}@${host}" echo "Successfully SSH-ed to ${target} \(which is really ${host}\) as ${user} without a password" 2>/dev/null
	fi

	# The `if' statement above ensures there was only one command line argument to begin with,
	# we can safely re-write them now that we're sure of the target.
	set -- "${relay_cmd[@]}" "${user}@${target}"

	echo "Setting up environment on ${target}"
	install-dot-files.sh "${relay}:${target}" >&${log_fd} 2>&${log_fd} &
	disown -h 2>/dev/null
	disown 2>/dev/null
fi
eval "${uncapture_output}"
command ssh -Y "$@"
