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
## `source trap_stack.sh` is sourced by bash_common.sh, so must be idempotent.

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
		builtin trap -p -- $sig
		es=$?
		if [ $es != 0 ]; then
			break
		fi
		local stack="`_trap_stack "$sig"`"
		local name_list="`_trap_stack_name_list "$stack"`"
		local ref='echo "${'"${stack}"'[$idx]}"'
		local nameref='echo "${'"__name${stack}"'[$idx]}"'
		for (( idx=0 ; idx < `_stack_size "${stack}"` ; idx += 1 )); do
			local spec="`eval $ref`"
			if [ -z "${spec}" ]; then
				continue
			fi
			local NAME="`eval $nameref`"
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
	local NAME="$1"
	local spec="$2"
	local sig="$3"
	## For each signal, we have an array of traps and an array of names.
	## The trap at a given index has the name given at the same index of the names array.
	local stack="`_trap_stack "$sig"`"
	local name_list="`_trap_stack_name_list "$stack"`"
	## There is also a named variable giving the index of that name in both arrays.
	local lookup="${stack}_${NAME}"
	## Here we have the name, so look up the index.  If the variable giving the index doesn't exist,
	## it should default to the size of the signal's list of traps.
	local s=`_stack_size "$stack"`
	local cnt=`eval 'echo ${'"${lookup}"':-$s}'`
	if [ $cnt == 0 -a "$NAME" != "${__ANON_STACK_NAME}" ]; then
		## Force anonymous trap to be at index zero.
		eval "${stack}_${__ANON_STACK_NAME}=$cnt"
		eval "${stack}"'['"${cnt}"']=""'
		eval "${name_list}"'['"${cnt}"']="${__ANON_STACK_NAME}"'
		cnt=$(( $cnt + 1 ))
	fi
	## Write the index back to the variable (:= doesn't work in an eval, and the value of `lookup` is not exposed if eval'd in a function)
	eval "${lookup}=$cnt"
	local es=0
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
	if [ -n "$spec" -o "${NAME}" != "${__ANON_STACK_NAME}" ]; then
		builtin trap "_fire $sig" $sig
		es=$?
	fi
	log "Installed trap: Signal=$sig TrapName=$NAME StackIdx=$cnt Spec='$spec'"
	return $es
}

function _fire()
{
	eval "${_hidex}"
	local sig="$1"
	local stack="`_trap_stack "$sig"`"
	local ref='echo "${'"${stack}"'[$idx]}"'
	local es=0
	for (( idx=0 ; idx < `_stack_size "${stack}"` ; idx += 1 )); do
		local spec="`eval $ref`"
		eval ${spec:-:}
		es=$(( $es + $? ))
	done
	eval "${_restorex}"
	return $es
}

function trap()
{
	local USAGE="trap: usage: trap [-lp] [-n|--name=name] [[arg] signal_spec ...]"
	local OPTS=$(getopt -o "hlpn:" --long "help,name:" -n "trap" -- "$@")
	local es=$?
	if [ $es != 0 ]; then
		echo "${USAGE}"
		return $es
	fi
	eval set -- "${OPTS}"
	local NAME="${__ANON_STACK_NAME}"
	local p="n"
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
		_print_traps $*
		return $?
	fi
	local spec="$1"
	shift
	if [ $# == 0 ]; then
		set -- $spec
		spec="-"
	fi
	for sig in "$@"; do
		_install_trap "$NAME" "$spec" "$sig" || return $?
	done
}
