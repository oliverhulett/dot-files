## Common function used by bashrc and bash_alias/* files.
## `source bash_common.sh` must be idempotent.

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

