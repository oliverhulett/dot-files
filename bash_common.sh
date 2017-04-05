## Common function used by bashrc and bash_alias/* files.
## `source bash_common.sh` must be idempotent.

_hidex='_setx=n; [[ $- == *x* ]] && _setx=y; set +x;'
eval "${_hidex}"
_restorex='[ ${_setx:-n} == y ] && set -x; unset _setx;'

export DEBUG_BASHRC="${DEBUG_BASHRC:-*}"
function source()
{
	log "${DEBUG_BASHRC} - source $@"
	DEBUG_BASHRC="${DEBUG_BASHRC}"'*'
	builtin source "$@"
	es=$?
	DEBUG_BASHRC="${DEBUG_BASHRC%\*}"
	log "${DEBUG_BASHRC} - ~source $@"
	return $es
}

function _reentrance_hash()
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
	FILE="$(basename -- "$1" .sh | tr '[a-z]' '[A-Z]' | tr -cd '[_a-zA-Z0-9]')"
	shift
	var="_${FILE}_GUARD"
	## Hash can only be a single 'token' otherwise the `eval` below doesn't work.
	guard="__ENTERED_${FILE}_$(_reentrance_hash "$@" | cut -d' ' -f1)"
	if [ "${!var}" != "${guard}" ]; then
		eval ${var}="${guard}"
		unset var guard name FILE
		return 1
	else
		log "${DEBUG_BASHRC} - re-entered ${name}"
		unset var guard name FILE
		return 0
	fi
}

function reentered()
{
	reentrance_check "$(basename -- "$(readlink -f "$(caller 0 | cut -d' ' -f3-)")")" "$@"
}

function _logfile()
{
	LOG_DIR="${HOME}/.dotlogs"
	mkdir "${LOG_DIR}" 2>/dev/null
	LOGFILE="${LOG_DIR}/$(date '+%Y%m%d')_$(whoami)_dot-files.log"
	echo "${LOGFILE}"
}

function log()
{
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$$] [$(basename -- "$0")] [LOG   ] $@" >>"$(_logfile)"
}

builtin source "${HOME}/dot-files/trap_stack.sh"

function _echo_clean_path()
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
	_echo_clean_path
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
	_echo_clean_path
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
	_echo_clean_path
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

function dotlogs()
{
	WHEN=
	WHO="$(whoami)"
	for a in "$@"; do
		if echo "$a" | grep -vqE '^[0-9]+$' >/dev/null 2>/dev/null && id -u "$a" >/dev/null 2>/dev/null; then
			WHO="$a"
		else
			WHEN="$WHEN $a"
		fi
	done
	if [ -z "$WHEN" ]; then
		WHEN="today"
	fi
	less "${HOME}/.dotlogs/$(date --date="${WHEN}" '+%Y%m%d')_${WHO}_dot-files.log"
}

function _tee_totaler()
{
	LOGFILE="$(_logfile)"

	KEYS=
	for k in "$@"; do
		KEYS="${KEYS} "'['"$k"']'
	done

	tee -i >(awk --assign T="%Y-%m-%d %H:%M:%S${KEYS} " '{ print strftime(T) $0 ; fflush(stdout) }' >>"${LOGFILE}")
}

_redirect='{
	if [ -z "$_redirected" ]; then
		trap -n redirect "unset _redirected" EXIT;
		_orig_stdout="$(readlink -f /proc/$$/fd/1)";
		_orig_stderr="$(readlink -f /proc/$$/fd/2)";
		exec > >(_tee_totaler "$$" "$(basename -- "$0")" STDOUT 2>/dev/null);
		exec 2> >(_tee_totaler "$$" "$(basename -- "$0")" STDERR >&2);
		_redirected="true";
	fi;
}'
setup_log_fd='{
	eval "$_hidex" 2>/dev/null;
	log_fd=3;
	if [ ! -t "${log_fd}" ]; then
		trap -n log_fd "unset log_fd" EXIT;
		exec 3> >(_tee_totaler "$$" "$(basename -- "$0")" "DEBUG " >/dev/null 2>/dev/null);
	fi;
	trap -n setup_log_fd "echo '"'"'\$ $0 $*;'"'"' Returned=\$? >&${log_fd}" EXIT;
	echo "$ $0 $@" >&${log_fd};
	callstack >&${log_fd};
	eval "$_restorex";
}'
capture_output='{
	eval "$_hidex" 2>/dev/null;
	eval "$_redirect";
	eval "$setup_log_fd";
	eval "$_restorex";
}'
uncapture_output='{ unset _redirected; exec >"${_orig_stdout:-/dev/tty}" 2>"${_orig_stderr:-/dev/tty}"; }'
eval "${_restorex}"
