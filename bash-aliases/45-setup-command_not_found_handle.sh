# shellcheck shell=bash

# Save original command not found handle and install this one instead.  Needs to be idempotent.
if [ -n "$(declare -f command_not_found_handle)" ] && [ -z "$(declare -f __original_command_not_found_handle)" ]; then
	eval "__original_$(declare -f command_not_found_handle)"
fi

function _err_echo()
{
	echo >&2 "$@"
}

# Testing shim, don't refactor.
function _run_bootstrapper()
{
	in_commands="false"
	run_commands="false"
	for c in "$@"; do
		if [ "${in_commands}" == "true" ]; then
			if [ "${run_commands}" == "true" ]; then
				# shellcheck disable=SC2086 - Double quote to prevent globbing and word splitting.
				_err_echo '$' $c
				eval "$c"
			fi
		elif echo "$c" | command grep -qE 'You can install .+ by typing:$'; then
			in_commands="true"
			if [ -t 0 ]; then
				read -rn1 -p"Run installation commands? [y/N] "
				_err_echo
				if [ "${REPLY,,}" == "y" ]; then
					run_commands="true"
				fi
			fi
		fi
	done
}

function _find_bootstrapper()
{
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
		echo "The script '${file}' is trying to run the program '${notfound}', which is not currently installed."
	fi

	if [ "${bootstrapper_found}" == "true" ]; then
		echo "You can install all of the dependencies for '${file}' by typing:"
		printf '  %s\n' "${bootstrapper}"
	else
		if [ -n "${bootstrapper}" ]; then
			echo "You can write a bootstrapper for '${file}' by implementing '${bootstrapper}'"
		fi
	fi
}

function _do_cnfh()
{
	if [ -z "$(declare -f __original_command_not_found_handle)" ]; then
		echo "The program '$1' is currently not installed."
		echo "No 'command_not_found_handle' installed.  You can install it by typing:"
		# TODO:  Instructions for Ubuntu/Linux as well.
		# shellcheck disable=SC2016 - Expressions don't expand in single quotes.
		printf '  %s\n' \
			'brew tap homebrew/command-not-found' \
			'eval "$(brew command-not-found-init)"' \
			'source "~/.bash-aliases/05-profile.d-command_not_found.sh"'
	else
		CONTINUOUS_INTEGRATION="homebrew hack" __original_command_not_found_handle "$@"
	fi
}

function command_not_found_handle()
{
	CMDS=()
	## Skip these things, we can't actually do it from here.  We'll have to integrate things with command prompt fn.
#	stack=()
#	frame=0
#	while caller "${frame}" >/dev/null 2>/dev/null; do
#		# shellcheck disable=SC2046 - quote to prevent splitting
#		set -- $(caller "${frame}")
#		# Strip line and function
#		while [ $# -ne 0 ]; do
#			if [ "${1:0:1}" == "/" ]; then
#				break
#			fi
#			shift
#		done
#		stack[${#stack[@]}]="$*"
#		frame=$((frame + 1))
#	done
#	if [ ${#stack[@]} -gt 0 ]; then
#		mapfile -t CMDS < <(_find_bootstrapper "$1" "${stack[@]}")
#	fi
	if [ ${#CMDS[@]} -lt 1 ]; then
		mapfile -t -O ${#CMDS[@]} CMDS < <(_do_cnfh "$@")
	fi
	for l in "${CMDS[@]}"; do
		_err_echo "$l"
	done
	_run_bootstrapper "${CMDS[@]}"
	return 127
}

#shellcheck disable=SC2034 - unused verify or export
typeset -fx command_not_found_handle
