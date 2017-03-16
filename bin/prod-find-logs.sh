#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

LOG_ARCHIVE_DIR="/media/log-archive/"
if [ ! -d "${LOG_ARCHIVE_DIR}" ] || [ -z "$(command ls "${LOG_ARCHIVE_DIR}")" ]; then
	## In case we're on central-archive...
	LOG_ARCHIVE_DIR="/u01/archive_sync/"
	if [ ! -d "${LOG_ARCHIVE_DIR}" ] || [ -z "$(command ls "${LOG_ARCHIVE_DIR}")" ]; then
		LOG_ARCHIVE_DIR="central-archive:/u01/archive_sync/"
	fi
fi

function usage()
{
	echo -e "$0 [ARCHIVE_DIR] [[-d] <DATE_PATTERN>...] [[-a] <APP_PATTERN>...]"
	echo -e "\tARCHIVE_DIR: The directory to search for log files.  Can be a local directory or a host:/path/ pattern."
	echo -e "\tDATE_PATTERN: Narrow the date range searched with this pattern."
	echo -e "\t            : Dates are specified as YYYYmmdd.  You can use any valid glob pattern."
	echo -e "\tAPP_PATTERN: Look for applications who's name matches this pattern."
	echo -e "\t           : Application names tend to be underscore separated sections of alphabet characters, ending with an underscore and (usually 3) numbers."
	echo
	echo -e "The type of each argument (DATE_PATTERN or APP_PATTERN) will be inferred if possible, but you can override the inference logic with the -d or -a flags."
	echo -e "By default, log files are looked for in: '${LOG_ARCHIVE_DIR}'"
}

function is_ssh()
{
	test "${1#*:}" != "$1"
}

cnt=0
explicit_date_or_app="n"
for arg in "$@"; do
	if [ "$explicit_date_or_app" == "y" ]; then
		explicit_date_or_app="n"
		cnt=$((cnt + 1))
		continue
	fi
	if [ "$arg" == "-d" -o "$arg" == "-a" ]; then
		explicit_date_or_app="y"
		cnt=$((cnt + 1))
		continue
	fi
	if [ "$arg" == "-?" -o "$arg" == "-h" -o "$arg" == "--help" ]; then
		usage
		exit 0
	fi
	if [ -d "$arg" ] || is_ssh "$arg"; then
		LOG_ARCHIVE_DIR="$arg"
		set -- "${@:1:$cnt}" "${@:$cnt + 2}"
		break
	fi
	cnt=$((cnt + 1))
done
unset cnt
if ! is_ssh "${LOG_ARCHIVE_DIR}" && [ ! -d "${LOG_ARCHIVE_DIR}" ]; then
	echo "Specified log archive mount point does not exist: ${LOG_ARCHIVE_DIR}"
	usage
	exit 1
fi
if ! is_ssh "${LOG_ARCHIVE_DIR}" && [ -z "$(command ls "${LOG_ARCHIVE_DIR}")" ]; then
	echo "Specified log archive directory is empty: ${LOG_ARCHIVE_DIR}"
	echo "Perhaps you need to mount it?"
	usage
	exit 1
fi

declare -a DATES
declare -a APPS

while [ $# -gt 0 ]; do
	type=
	arg="$1"
	shift
	if [ "$arg" == "-d" ]; then
		type="date"
		arg="$1"
		shift
	elif [ "$arg" == "-a" ]; then
		type="app"
		arg="$1"
		shift
	else
		if echo $arg | grep -qwE '^[^a-zA-Z_]+$' 2>/dev/null; then
			type="date"
		else
			type="app"
		fi
	fi

	if [ "$type" == "date" ]; then
		if [ ${#DATES[@]} -ne 0 ]; then
			DATES[${#DATES[@]}]="-or"
		fi
		DATES[${#DATES[@]}]="-iname"
		DATES[${#DATES[@]}]="${arg}-\\*"
	elif [ "$type" == "app" ]; then
		if [ ${#APPS[@]} -ne 0 ]; then
			APPS[${#APPS[@]}]="-or"
		fi
		APPS[${#APPS[@]}]="-iname"
		APPS[${#APPS[@]}]="*-${arg}.\\*"
	fi
done

if [ ${#DATES[@]} -eq 0 -a ${#APPS[@]} -eq 0 ]; then
	echo "No dates or applications specified.  This is going to find everything, you don't want that."
	usage
	exit 1
fi

if [ ${#DATES[@]} -eq 0 ]; then
	DATES[0]="-true"
fi
if [ ${#APPS[@]} -eq 0 ]; then
	APPS[0]="-true"
fi

function do_find()
{
	echo find "$@" 1>&2
	DEST="$1"
	shift
	ssh_cmd=( bash -xc )
	if [ "${DEST#*:}" != "${DEST}" ]; then
		HOST="${DEST%%:*}"
		echo "${HOST}:"
		ssh_cmd=( ssh "${HOST}" )
		DEST="${DEST#*:}"
	fi
	"${ssh_cmd[@]}" "$(echo '(' test -d "${DEST}" '&&' find "${DEST}" "$@" '2>/dev/null' '); (' test ! -d "${DEST}" '&&' echo "Specified log archive mount point does not exist: ${DEST}" ')')"
}

do_find "${LOG_ARCHIVE_DIR}" -type f -iname '\*.log.bz2' '\(' "${DATES[@]}" '\)' '\(' "${APPS[@]}" '\)'

