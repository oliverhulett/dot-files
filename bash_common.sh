## Common function used by bashrc and bash_alias/* files.
## `source bash_common.sh` must be idempotent.

#DEBUG_BASHRC="${DEBUG_BASHRC:-*}"
function source()
{
	if [ -z "${DEBUG_BASHRC:+x}" ]; then
		builtin source "$@"
	else
		echo "${DEBUG_BASHRC} source $@"
		DEBUG_BASHRC="${DEBUG_BASHRC}"'*' builtin source "$@"
	fi
}

function reentrance_hash()
{
	for i in "$@"; do
		if [ "$(dirname "$i")" == "/dev/fd" ]; then
			/bin/cat "$i" 2>/dev/null 1>&2 2>/dev/null
		fi
	done
	/bin/cat "${HOME}/etc/dot-files/bash_common.sh" "$@" 2>/dev/null | md5sum
}

function reentrance_check()
{
	name="$1"
	FILE="$(basename "$1" .sh | tr '[a-z]' '[A-Z]' | tr -cd '[_a-zA-Z0-9]')"
	shift
	var="_${FILE}_GUARD"
	if [ "${REENTRANCE_GUARDS[$var]}" != "__ENTERED_${FILE}_$(reentrance_hash "$@")" ]; then
		REENTRANCE_GUARDS[$var]="__ENTERED_${FILE}_$(reentrance_hash "$@")"
		return 1
	else
		if [ -n "${DEBUG_BASHRC:+x}" ]; then
			echo "${DEBUG_BASHRC} - re-entered ${name}"
		fi
		return 0
	fi
}
function reentered()
{
	reentrance_check "$(basename "$(readlink -f "$(caller 0 | cut -d' ' -f3-)")")" "$@"
}
alias reentered='reentrance_check "$(basename "$(readlink -f "${BASH_SOURCE}")")"'
if ! declare -p REENTRANCE_GUARDS >/dev/null 2>/dev/null; then
	declare -xA REENTRANCE_GUARDS
fi

##  Get real (pathed) versions of commands we will later replace with aliases or functions.
##  TODO:  Handle executable paths with spaces and executable names with spaces.
function get_real_exe()
{
	exe="$1"
	for f in $(type -fa $exe 2>/dev/null | sed -re 's/[^ ]+ is (.+)$/\1/'); do
		if [ -x "$f" ]; then
			eval export REAL_$(echo $exe | tr '[a-z]' '[A-Z]')="$f"
			alias real_${exe}="$f"
			echo "$f"
			break
		fi
	done
}

function echo_clean_path()
{
	echo "$(echo $PATH | sed -re 's/^://;s/::+/:/g;s/:$//')"
}

function rm_path()
{
	for d in "$@"; do
		d="$(readlink -f "$d")"
		if [ -n "$d" ]; then
			PATH="$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	echo_clean_path
}

function prepend_path()
{
	for d in "$@"; do
		d="$(readlink -f "$d")"
		if [ -n "$d" ]; then
			PATH="$d:$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	echo_clean_path
}

function append_path()
{
	for d in "$@"; do
		d="$(readlink -f "$d")"
		if [ -n "$d" ]; then
			PATH="$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\2!g'):$d"
		fi
	done
	echo_clean_path
}

