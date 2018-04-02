# shellcheck shell=sh
## Common function used by bashrc and bash_alias/* files.
## `source bash_common.sh` must be idempotent.
# shellcheck disable=SC2016,SC2015

_hidex='_setx=n; [[ $- == *x* ]] && _setx=y; set +x;'
_hidex=
eval "${_hidex}"
_restorex='[ ${_setx:-n} == y ] && set -x; unset _setx;'
_restorex=

# Alias gnu utils installed on the mac with homebrew to their usual names.
## Do we need to detect mac-ness?
## This should work on linux too (mostly it'll be a no-op, worst case it create some useless links)
for f in /usr/local/bin/g*; do
	g="$(basename -- "$f")"
	if [ "$g" != 'g[' ] && [ ! -e "/usr/local/bin/${g:1}" ]; then
		( cd /usr/local/bin/ && ln -s "$g" "${g:1}" 2>/dev/null )
	fi
done
# Doesn't work, for some reason.
rm '/usr/local/bin/[' 2>/dev/null

export DEBUG_BASHRC="${DEBUG_BASHRC:-*}"
function source()
{
	dotlog "${DEBUG_BASHRC} - source $*"
	DEBUG_BASHRC="${DEBUG_BASHRC}"'*'
	builtin source "$@"
	es=$?
	DEBUG_BASHRC="${DEBUG_BASHRC%\*}"
	dotlog "${DEBUG_BASHRC} - ~source $*"
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
	FILE="$(basename -- "$1" .sh | tr '[:lower:]' '[:upper:]' | tr -cd '_a-zA-Z0-9')"
	shift
	var="_${FILE}_GUARD"
	## Hash can only be a single 'token' otherwise the `eval` below doesn't work.
	guard="__ENTERED_${FILE}_$(_reentrance_hash "$@" | cut -d' ' -f1)"
	if [ "${!var}" != "${guard}" ]; then
		eval "${var}"="${guard}"
		unset var guard name FILE
		return 1
	else
		dotlog "${DEBUG_BASHRC} - re-entered ${name}"
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

function dotlog()
{
	echo "$(date '+%H:%M:%S.%N') [$$] [$(basename -- "$0")] [LOG   ] $*" >>"$(_logfile)"
}

builtin source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/trap_stack.sh"

function _echo_clean_path()
{
	echo "$@" | sed -re 's/^://;s/::+/:/g;s/:$//'
}

function rm_path()
{
	local p="$1"
	shift
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			p="$(echo "$p" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	unset d
	_echo_clean_path "$p"
}

function prepend_path()
{
	local p="$1"
	shift
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			p="$d:$(echo "$p" | sed -re 's!(^|:)'"$d"'/?(:|$)!\1!g')"
		fi
	done
	unset d
	_echo_clean_path "$p"
}

function append_path()
{
	local p="$1"
	shift
	for d in "$@"; do
		d="$(cd "$d" 2>/dev/null && pwd || echo "${d%%/}" | sed -re 's!/+!/!g')"
		if [ -n "$d" ]; then
			p="$(echo "$p" | sed -re 's!(^|:)'"$d"'/?(:|$)!\2!g'):$d"
		fi
	done
	unset d
	_echo_clean_path "$p"
}

function callstack()
{
	frame=${1:-0}
	while caller "$frame" >/dev/null 2>/dev/null; do
		set -- $(caller "$frame")
		line="$1"
		shift
		fn="$1"
		shift
		echo "frame=$frame caller=$fn line=$line file="'"'"$*"'"'
		frame=$((frame + 1))
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

	## That time format is HH:MM:SS followed by 10 spaces to line up with the dot and the 9 nanoseconds printed by log()
	tee -i >(awk --assign T="%H:%M:%S          ${KEYS} " '{ print strftime(T) $0 ; fflush(stdout) }' >>"${LOGFILE}")
}

_redirect='{
	if [ "$0" == "${BASH_SOURCE}" -a -z "$_redirected" ]; then
		trap -n redirect "unset _redirected" EXIT;
		f="$(readlink -f /proc/$$/fd/1)";
		if [ -e "$f" ]; then
			_orig_stdout="$f";
		else
			_orig_stdout="/dev/tty";
		fi;
		f="$(readlink -f /proc/$$/fd/2)";
		if [ -e "$f" ]; then
			_orig_stderr="$f";
		else
			_orig_stderr="/dev/tty";
		fi;
		#builtin trap "dotlog \$ \$BASH_COMMAND" DEBUG;
		exec > >(_tee_totaler "$$" "$(basename -- "$0")" STDOUT 2>/dev/null);
		exec 2> >(_tee_totaler "$$" "$(basename -- "$0")" STDERR >&2);
		_redirected="true";
	fi;
}'
setup_log_fd='{
	eval "$_hidex" 2>/dev/null;
	if [ -z "${log_fd}" ]; then
		trap -n log_fd "unset log_fd" EXIT;
		exec 3> >(_tee_totaler "$$" "$(basename -- "$0")" "DEBUG " >/dev/null 2>/dev/null);
		log_fd=3;
	fi;
	if [ "$0" == "${BASH_SOURCE}" ]; then
		trap -n setup_log_fd "echo '"'"'\$ $0 $*;'"'"' Returned=\$? >&${log_fd}" EXIT;
		callstack >&${log_fd};
		echo "$ $0 $@" >&${log_fd};
		echo "/bin/bash $-" >&${log_fd};
	fi;
	eval "$_restorex";
}'
eval "${setup_log_fd}"
capture_output='{
	eval "$_hidex" 2>/dev/null;
	eval "$setup_log_fd";
	eval "$_redirect";
	eval "$_restorex";
}'
uncapture_output='{
	if [ -n "$_redirected" ]; then
		unset _redirected;
		exec >"${_orig_stdout:-/dev/tty}" 2>"${_orig_stderr:-/dev/tty}";
	fi;
}'
eval "${_restorex}"
