# shellcheck shell=bash

THIS="$(readlink -f "${BASH_SOURCE[0]}")"
# Save original command not found handle and install this one instead.  Needs to be idempotent.
if [ -n "$(declare -f command_not_found_handle)" ] && [ -z "$(declare -f __original_command_not_found_handle)" ]; then
	eval "__original_$(declare -f command_not_found_handle)"
fi
function _do_cnfh()
{
	if [ -z "$(declare -f __original_command_not_found_handle)" ]; then
		printf 'The program '"'%s'"' is currently not installed.\n' "$1"
		echo "No 'command_not_found_handle' installed.  You can install it by typing:"
		# TODO:  Instructions for Ubuntu/Linux as well.
		# shellcheck disable=SC2016 - Expressions don't expand in single quotes.
		printf '  %s\n' 'brew tap homebrew/command-not-found' 'eval "$(brew command-not-found-init)"' 'source "'"${THIS}"'"'
		return 127
	else
		CONTINUOUS_INTEGRATION="homebrew hack" __original_command_not_found_handle "$@"
		return $?
	fi
}
function command_not_found_handle()
{
	_do_cnfh "$@"
	rv=$?
	mapfile -t CMDS < <(_do_cnfh "$@")
	if [ ${#CMDS} -gt 0 ]; then
		in_commands="false"
		run_commands="false"
		for c in "${CMDS[@]}"; do
			if [ "${in_commands}" == "true" ]; then
				if [ "${run_commands}" == "true" ]; then
					# shellcheck disable=SC2086 - Double quote to prevent globbing and word splitting.
					echo '$' $c
					eval "$c"
				fi
			elif echo "$c" | grep -qE 'You can install it by typing:$'; then
				in_commands="true"
				read -rn1 -p"Run installation commands? [Y/n] "
				echo
				if [ "${REPLY,,}" != "n" ]; then
					run_commands="true"
				fi
			fi
		done
	fi
	return $rv
}

## Walk up the caller stack looking for executables that have matching bootstrapper files.
##  If found, offer to run the bootstrapper file, run it if yes.
## Fallback to the default command_not_found_handle, parse output for suggested installation command, offer to run it, run it if yes.
## If no default command_not_found_handle, offer to install it, install if yes.
## brew hint is `brew tap homebrew/command-not-found`.  Find linux hint

# How will this work for nested commands and libraries?  command_not_found_handle only kicks in for commands typed by the user?
# v1 can use `which` when things fail...

# Need to be able to work out what OS is running and point to the right bootstrapper
# Need to be able to declare dependencies? or just let this mechanism recurse?
# How to deal with things that require user interactions?
