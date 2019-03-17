# shellcheck shell=bash

DOTFILES="$(dirname "$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)")"
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
	mapfile -t CMDS < <("${DOTFILES}/lib/command_not_found_handle.sh" "$@")
	if [ ${#CMDS} -gt 0 ]; then
		in_commands="false"
		run_commands="false"
		for c in "${CMDS[@]}"; do
			if [ "${in_commands}" == "true" ]; then
				if [ "${run_commands}" == "true" ]; then
					# shellcheck disable=SC2086 - Double quote to prevent globbing and word splitting.
					_err_echo '$' $c
					eval "$c"
				fi
			elif echo "$c" | grep -qE 'You can install .+ by typing:$'; then
				in_commands="true"
				if [ -t 0 ]; then
					read -rn1 -p"Run installation commands? [Y/n] "
					_err_echo
					if [ "${REPLY,,}" != "n" ]; then
						run_commands="true"
					fi
				fi
			fi
		done
	fi
}

function command_not_found_handle()
{
	notfound="$*"
	stack=()
	frame=0
	while caller "${frame}" >/dev/null 2>/dev/null; do
		# shellcheck disable=SC2046 - quote to prevent splitting
		set -- $(caller "${frame}")
		# Strip line and function
		while [ $# -ne 0 ]; do
			if [ "${1:0:1}" == "/" ]; then
				break
			fi
			shift
		done
		stack[${#stack[@]}]="$*"
		frame=$((frame + 1))
	done
	#shellcheck disable=SC2046 - double quote to prevent word splitting
	"${DOTFILES}/lib/command_not_found_handle.sh" "${notfound}" "${stack[@]}" >&2
	rv=$?
	_run_bootstrapper "${notfound}" "${stack[@]}"
	return $rv
}
