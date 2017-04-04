## Stolen shamelessly from http://stackoverflow.com/a/16115145
function _trap_stack_name()
{
	local sig=${1//[^a-zA-Z0-9]/_}
	echo "__trap_stack_$sig"
}

function _extract_trap()
{
	echo ${@:3:$(($#-3))}
}

function _get_trap()
{
	eval echo $(_extract_trap $(builtin trap -p $1))
}

function trap_push()
{
	local new_trap=$1
	shift
	local sigs=$*
	for sig in $sigs; do
		local stack_name=`_trap_stack_name "$sig"`
		local old_trap=$(_get_trap $sig)
		eval "${stack_name}"'[${#'"${stack_name}"'[@]}]=$old_trap'
		builtin trap "${new_trap}" "$sig"
	done
}

function trap_pop()
{
	local sigs=$*
	for sig in $sigs; do
		local stack_name=`_trap_stack_name "$sig"`
		local count; eval 'count=${#'"${stack_name}"'[@]}'
		[[ $count -lt 1 ]] && return 127
		local new_trap
		local ref="${stack_name}"'[${#'"${stack_name}"'[@]}-1]'
		local cmd='new_trap=${'"$ref}"; eval $cmd
		builtin trap "${new_trap}" "$sig"
		eval "unset $ref"
	done
}

function trap_prepend()
{
	local new_trap=$1
	shift
	local sigs=$*
	for sig in $sigs; do
		if [[ -z $(_get_trap $sig) ]]; then
			builtin trap_push "$new_trap" "$sig"
		else
			builtin trap_push "$new_trap ; $(_get_trap $sig)" "$sig"
		fi
	done
}

function trap_append()
{
	local new_trap=$1
	shift
	local sigs=$*
	for sig in $sigs; do
		if [[ -z $(_get_trap $sig) ]]; then
			trap_push "$new_trap" "$sig"
		else
			trap_push "$(_get_trap $sig) ; $new_trap" "$sig"
		fi
	done
}
