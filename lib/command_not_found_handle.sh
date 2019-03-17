#!/usr/bin/env bash

DOTFILES="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)")"

function _do_cnfh()
{
	if [ -z "$(declare -f __original_command_not_found_handle)" ]; then
		printf 'The program '"'%s'"' is currently not installed.\n' "$1"
		echo "No 'command_not_found_handle' installed.  You can install it by typing:"
		# TODO:  Instructions for Ubuntu/Linux as well.
		# shellcheck disable=SC2016 - Expressions don't expand in single quotes.
		printf '  %s\n' 'brew tap homebrew/command-not-found' 'eval "$(brew command-not-found-init)"' 'source "'"${DOTFILES}/bash-aliases/45-setup-command_not_found_handle.sh"'"'
		return 127
	else
		CONTINUOUS_INTEGRATION="homebrew hack" __original_command_not_found_handle "$@"
		return $?
	fi
}

notfound="$1"
shift

bootstrapper_found="false"
bootstrapper=
for file in "$@"; do
	bootstrapper="$(dirname "${file}")/.bootstraps/$(basename -- "${file}")"
	if [ -x "${bootstrapper}" ]; then
		bootstrapper_found="true"
		break
	fi
done

if [ $# -ne 0 ]; then
	echo "The script '${file}' is trying to run the program '${notfound[*]}', which is not currently installed."
fi

if [ "${bootstrapper_found}" == "true" ]; then
	echo "You can install all of the dependencies for '${file}' by typing:"
	printf '  %s\n' "${bootstrapper}"
	exit 127
else
	if [ -n "${bootstrapper}" ]; then
		echo "You can write a bootstrapper for '${file}' by implementing '${bootstrapper}'"
	fi
	_do_cnfh "${notfound}"
fi
