# shellcheck shell=bash
## Introduce the concept of named traps.
## There exists one anonymous trap stack, which has the usual installation semantics of:
##   $ trap <spec> SIGS...
## You can also install a named trap:
##   $ trap -n name <spec> SIGS...
## Each named trap works like the anonymous stack, in that installing another spec with the same name replaces any existing trap,
## but of course installing a trap with a new name does not overwrite the existing trap for that signal.
## When a trap fires, the anonymous trap is fired, followed by each of the named stacks in reverse installation order.
##
## Concepts stolen from http://stackoverflow.com/a/16115145
##
## `source trap-stack.sh` is sourced by bash-common.sh, so must be idempotent.
# shellcheck source=bash-common.sh
# shellcheck disable=SC2016,SC2086,SC2046

__ANON_STACK_NAME="__anon__"

function _stack_size()
{
	eval 'echo ${#'"$1"'[@]}'
}

function _trap_stack()
{
	local sig=${1//[^a-zA-Z0-9]/_}
	echo "__trap_stack_$sig"
}

function _trap_stack_name_list()
{
	echo "__name$1"
}

function _print_traps()
{
	if [ $# -eq 0 ]; then
		set -- $(builtin trap -p | awk 'NF{ print $NF }')
	fi
	local es=0
	for sig in "$@"; do
		builtin trap -p -- "$sig"
		es=$?
		if [ $es != 0 ]; then
			break
		fi
		local stack name_list ref nameref
		stack="$(_trap_stack "$sig")"
		name_list="$(_trap_stack_name_list "$stack")"
		ref='echo "${'"${stack}"'[$idx]}"'
		nameref='echo "${'"__name${stack}"'[$idx]}"'
		for (( idx=0 ; idx < $(_stack_size "${stack}") ; idx += 1 )); do
			local spec NAME
			spec="$(eval $ref)"
			if [ -z "${spec}" ]; then
				continue
			fi
			NAME="$(eval $nameref)"
			if [ "$NAME" == "${__ANON_STACK_NAME}" ]; then
				echo "trap -- '${spec}' $sig"
			else
				echo "trap --name=$NAME -- '${spec}' $sig"
			fi
		done
	done
	return $es
}

function _install_trap()
{
	local NAME spec sig stack name_list lookup s cnt es
	NAME="$1"
	spec="$2"
	sig="$3"
	## For each signal, we have an array of traps and an array of names.
	## The trap at a given index has the name given at the same index of the names array.
	stack="$(_trap_stack "$sig")"
	name_list="$(_trap_stack_name_list "$stack")"
	## There is also a named variable giving the index of that name in both arrays.
	lookup="${stack}_${NAME}"
	## Here we have the name, so look up the index.  If the variable giving the index doesn't exist,
	## it should default to the size of the signal's list of traps.
	# shellcheck disable=SC2034
	s=$(_stack_size "$stack")
	cnt=$(eval 'echo ${'"${lookup}"':-$s}')
	if [ $cnt == 0 ] && [ "$NAME" != "${__ANON_STACK_NAME}" ]; then
		## Force anonymous trap to be at index zero.
		eval "${stack}_${__ANON_STACK_NAME}=$cnt"
		eval "${stack}"'['"${cnt}"']=""'
		eval "${name_list}"'['"${cnt}"']="${__ANON_STACK_NAME}"'
		cnt=$(( cnt + 1 ))
	fi
	## Write the index back to the variable (:= doesn't work in an eval, and the value of `lookup` is not exposed if eval'd in a function)
	eval "${lookup}=$cnt"
	es=0
	if [ "${spec}" == "-" ]; then
		## Set trap to original disposition...
		if [ "$NAME" == "${__ANON_STACK_NAME}" ]; then
			builtin trap - $sig
			es=$?
		fi
		spec=
	elif [ -z "${spec}" ]; then
		## Ignore signal...
		if [ "$NAME" == "${__ANON_STACK_NAME}" ]; then
			builtin trap "" $sig
			es=$?
		fi
	fi
	eval "${stack}"'['"${cnt}"']="$spec"'
	## Also, store the name of the trap in the list of names.
	eval "${name_list}"'['"${cnt}"']="$NAME"'
	if [ -n "$spec" ] || [ "${NAME}" != "${__ANON_STACK_NAME}" ]; then
		builtin trap "_fire $sig" $sig
		es=$?
	fi
	dotlog "Installed trap: Signal=$sig StackIdx=$cnt TrapName=$NAME Spec="'"'"$spec"'"'
	return $es
}

# shellcheck disable=SC2154
function _fire()
{
	_last_exit_status=$?
	local sig stack ref
	eval "${_hidex}"
	sig="$1"
	stack="$(_trap_stack "$sig")"
	ref='echo "${'"${stack}"'[$idx]}"'
	for (( idx=0 ; idx < $(_stack_size "${stack}") ; idx += 1 )); do
		local spec
		spec="$(eval $ref)"
		dotlog "Firing trap: Signal=$sig StackIdx=$idx TrapName=$stack Spec="'"'"$spec"'"'
		( return $_last_exit_status )
		eval "${spec:-:}"
	done
	eval "${_restorex}"
	return $_last_exit_status
}

function trap()
{
	local USAGE OPTS es NAME p spec
	USAGE="trap: usage: trap [-lp] [-n|--name=name] [[arg] signal_spec ...]"
	OPTS=$(getopt -o "hlpn:" --long "help,name:" -n "trap" -- "$@")
	es=$?
	if [ $es != 0 ]; then
		echo "${USAGE}"
		return $es
	fi
	eval set -- "${OPTS}"
	NAME="${__ANON_STACK_NAME}"
	p="n"
	while true; do
		case "$1" in
			-h | '-?' | --help )
				echo "${USAGE}"
				return 0
				;;
			-n | --name )
				NAME="$2"
				shift 2
				;;
			-p )
				p="y"
				shift
				;;
			-- ) shift; break ;;
			-* )
				builtin trap "$@"
				return $?
				;;
			* ) break ;;
		esac
	done
	if [ "$p" == "y" ]; then
		_print_traps "$@"
		return $?
	fi
	spec="$1"
	shift
	if [ $# == 0 ]; then
		set -- $spec
		spec="-"
	fi
	for sig in "$@"; do
		_install_trap "$NAME" "$spec" "$sig" || return $?
	done
}
