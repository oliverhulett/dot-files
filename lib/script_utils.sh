# shellcheck shell=bash
## Utilities for writing useful and user friendly scripts.  To be sourced.  Should be idempontent, only defines functions.

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash_common.sh"

export TERM="${TERM:-xterm-256color}"

_SHUTILS_QUIET="no"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
WHITE="$(tput bold)$(tput setaf 7)"
RESET="$(tput sgr0)"

function report_good()
{
	[ "${_SHUTILS_QUIET}" != "no" ] || echo -e "${GREEN}" "$*" "${RESET}"
}

function report_bad()
{
	[ "${_SHUTILS_QUIET}" != "no" ] || echo -e "${RED}" "$*" "${RESET}"
}

function report_cmd()
{
	[ "${_SHUTILS_QUIET}" != "no" ] || echo -e "${WHITE}" "$*" "${RESET}"
	"$@"
}


_SHUTILS_LOCK_DIR=
function _shutils_cleanup()
{
	[ -z "${_SHUTILS_LOCK_DIR}" ] || rm -rf "${_SHUTILS_LOCK_DIR}" >/dev/null 2>/dev/null
}

function reentrance_check()
{
	local name="${1:-$(basename -- "$0" .sh)}"
	_SHUTILS_LOCK_DIR="${TMPDIR:-${TMP:-${HOME}}}/.${name}.lock.d"
	report_good "Using lock directory: ${_SHUTILS_LOCK_DIR}"
	if ! mkdir "${_SHUTILS_LOCK_DIR}" 2>/dev/null; then
		## Lock dir already existed, look for running instance
		if [ -f "${_SHUTILS_LOCK_DIR}/${name}.pid" ] && kill -0 "$(command cat "${_SHUTILS_LOCK_DIR}/${name}.pid")" >/dev/null 2>/dev/null; then
			## An instance is already running, we re-entered
			report_bad "An instance of $(basename -- "$0") is still running, stopping to prevent re-entrance..."
			exit 1
		else
			## An instance crashed?
			report_bad "The $(basename -- "$0") lock directory exists but I can't find the running process, suspected crash.  Cleaning lock directory and exiting..."
			_shutils_cleanup
			exit 1
		fi
	fi
	## Lock dir was created, no existing instance running
	echo $$ >"${_SHUTILS_LOCK_DIR}/${name}.pid"
	trap -n "shutils_lock" _shutils_cleanup EXIT
}
