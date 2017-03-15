## Common function used by bashrc and bash_alias/* files.
## `source bash_common.sh` must be idempotent.

#DEBUG_BASHRC="${DEBUG_BASHRC:-*}"
function source()
{
	log "source $@"
	if [ -z "${DEBUG_BASHRC:+x}" ]; then
		builtin source "$@"
	else
		echo "$(date '+%T.%N') ${DEBUG_BASHRC} source $@"
		DEBUG_BASHRC="${DEBUG_BASHRC}"'*' builtin source "$@"
	fi
}

function reentrance_hash()
{
	for i in "$@"; do
		if [ "$(dirname "$i")" == "/dev/fd" ]; then
			## I don't know what's going on here, but temporary files (of the form
			## <(echo this)) tend not to work without this cat-in-a-loop.  :(
			command cat "$i" 2>/dev/null 1>&2
		fi
	done
	command cat "${HOME}/dot-files/bash_common.sh" "$@" 2>/dev/null | md5sum
}

function reentrance_check()
{
	name="$1"
	FILE="$(basename "$1" .sh | tr '[a-z]' '[A-Z]' | tr -cd '[_a-zA-Z0-9]')"
	shift
	var="_${FILE}_GUARD"
	## Hash can only be a single 'token' otherwise the `eval` below doesn't work.
	guard="__ENTERED_${FILE}_$(reentrance_hash "$@" | cut -d' ' -f1)"
	if [ "${!var}" != "${guard}" ]; then
		eval ${var}="${guard}"
		unset var guard name FILE
		return 1
	else
		log "re-entered ${name}"
		if [ -n "${DEBUG_BASHRC:+x}" ]; then
			echo "$(date '+%T.%N') ${DEBUG_BASHRC} - re-entered ${name}"
		fi
		unset var guard name FILE
		return 0
	fi
}
function reentered()
{
	reentrance_check "$(basename "$(readlink -f "$(caller 0 | cut -d' ' -f3-)")")" "$@"
}

function echo_clean_path()
{
	echo "$(echo $PATH | sed -re 's/^://;s/::+/:/g;s/:$//')"
}

function rm_path()
{
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			PATH="$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	unset d
	echo_clean_path
}

function prepend_path()
{
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			PATH="$d:$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	unset d
	echo_clean_path
}

function append_path()
{
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			PATH="$(echo "${PATH}" | sed -re 's!(^|:)'"$d"'/?(:|$)!\2!g'):$d"
		fi
	done
	unset d
	echo_clean_path
}

function callstack()
{
	frame=${1:-0}
	while caller $frame >/dev/null 2>/dev/null; do
		set -- $(caller $frame)
		line="$1"
		shift
		fn="$1"
		shift
		echo "frame=$frame caller=$fn line=$line file="'"'"$*"'"'
		frame=$(($frame + 1))
	done
}

function _logfile()
{
	LOG_DIR="${HOME}/.setup-logs"
	mkdir "${LOG_DIR}" 2>/dev/null
	LOGFILE="${LOG_DIR}/$(date '+%Y%m%d')_$(whoami)_dot-files.log"
	echo "${LOGFILE}"
}

function log()
{
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$$] [$(basename "$0")] [LOG   ] $@" >>"$(_logfile)"
}

function tee_totaler()
{
	LOGFILE="$(_logfile)"

	KEYS=
	for k in "$@"; do
		KEYS="${KEYS} "'['"$k"']'
	done

	tee -i >(awk --assign T="%Y-%m-%d %H:%M:%S${KEYS} " '{ print strftime(T) $0 ; fflush(stdout) }' >>"${LOGFILE}")
}
capture_output='{
	if [ -z "$log_fd" ]; then
		declare -x log_fd=3;
		exec 3> >(tee_totaler $$ "$(basename "$0")" "DEBUG " >/dev/null 2>/dev/null);
		exec > >(tee_totaler $$ "$(basename "$0")" STDOUT 2>/dev/null);
		exec 2> >(tee_totaler $$ "$(basename "$0")" STDERR >&2);
		trap "unset log_fd" EXIT;
	fi;
	echo "$ $0 $@" >&${log_fd};
	trap "echo \$ $0 $*\; Returned=\$? >&${log_fd}" EXIT;
	callstack >&${log_fd};
}'
uncapture_output='exec >/dev/tty 2>/dev/tty'
