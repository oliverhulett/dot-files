# shellcheck shell=bash

# added by pipsi (https://github.com/mitsuhiko/pipsi)
source "${HOME}/dot-files/bash-common.sh"
PATH="$(append_path "${PATH}" "${HOME}/.local/bin")"
export PATH

# Wrap pipsi into Python 3 and Python 2 versions explicitly

function pipsi3()
{
	if inarray install "$@"; then
		command pipsi "$@" --python python3
	else
		command pipsi "$@"
	fi
}

function pipsi2()
{
	if inarray install "$@"; then
		command pipsi "$@" --python python2
	else
		command pipsi "$@"
	fi
}

function pipsi()
{
	echo "Use either 'pipsi2' or 'pipsi3' explicitly.  (Or 'command pipsi')"
	return 1
}
