#!/bin/bash
#
#	Pull logs from the log_archive.
#

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

BASE_DIR="${HOME}/logs/"

function usage()
{
	echo -e "$0 [<FILTER_PATTERN>] [<HOST>:] <FILES>..."
	echo -e "\tFILTER_PATTERN: Use 'bzgrep' instead of 'bzcat' to extract log files and use this pattern as the filter."
	echo -e "\t              : 'egrep' is used, so any PCRE is valid."
	echo -e "\tHOST: The host on which the files live.  To differentiate HOST from FILTER_PATTERN the last character must be a literal ':' (colon)."
	echo -e "\tFILES: The log files to unzip and extract.  Use find-prod-logs.sh to help you find the right files."
	echo -e "\t     : Log files will be extracted to '${BASE_DIR}/<PROD_MACHINE_NAME>/'"
	echo
	echo -e "FILTER_PATTERN must be before the first FILES argument.  Its presence is inferred by the fact that it is not the name of an existing file and is not a HOST."
}

if [ "$1" == "-?" -o "$1" == "-h" -o "$1" == "--help" ]; then
	usage
	exit 1
fi

function checkprocs()
{
	( cd /proc >/dev/null 2>/dev/null && command ls -1d "$@" 2>/dev/null )
}

function is_ssh()
{
	test "${1: -1}" == ":"
}

function file_exists()
{
	"${ssh_cmd[@]}" "$(echo test -f "'""$1""'")"
}

GREP="egrep"
FILTERED="n"
BZCMD=( bzcat )
HOST="localhost"
ssh_cmd=( bash -c )
cnt=0
for arg in "$@"; do
	if is_ssh "$arg"; then
		HOST="${arg%%:}"
		ssh_cmd=( ssh -Cqtt "${HOST}" )
		set -- "${@:1:$cnt}" "${@:$cnt + 2}"
		break
	fi
	cnt=$((cnt + 1))
done
unset cnt
if ! file_exists "$1"; then
	echo "'$1' is not a file, using it as a pattern..."
	FILTERED="y"
	BZCMD=( bzgrep -e "'""$1""'" )
	shift
fi

if [ $# -lt 1 ]; then
	echo "Need a file to copy..."
	usage
	exit 1
fi

cnt=0
proclst=
for log in "$@"; do
	srvdir="$(basename -- "$(dirname "$(readlink -m "$log")")" | sed -re 's/([^.]+)\..+/\1/')"
	out="${BASE_DIR}/${srvdir}/$(basename -- "$log" .bz2)"
	if [ "${FILTERED}" == "y" ]; then
		out="${out}.filtered.00.txt"
		while [ -e "$out" ]; do
			idx="$(basename -- "$out" .txt)"
			idx="${idx##*.}"
			idx=$(( $idx + 1 ))
			out="$(basename -- "$out" .txt)"
			out="${out%.*}.$(printf '%02d' ${idx}).txt"
			out="${BASE_DIR}/${srvdir}/${out}"
		done
	fi
	if ! file_exists "$log"; then
		echo "'${HOST}:${log}' does not exist, skipping..."
		continue
	fi
	if [ ! -e "$out" ]; then
		mkdir -pv "${BASE_DIR}/${srvdir}" 2>/dev/null
		if [ "${FILTERED}" == "y" ]; then
			echo "Copying '${HOST}:${log}' to '$out' using cmd: ${BZCMD[@]}"
			echo "'${HOST}:${log}' filtered using: ${BZCMD[@]}" >$out
		else
			echo "Copying '${HOST}:${log}' to '$out' using cmd: ${BZCMD[@]}"
		fi
		( trap "kill 0" EXIT; "${ssh_cmd[@]}" "$(echo export GREP="${GREP}" '&&' "${BZCMD[@]}" "$log")" >>"$out"; trap - EXIT; echo "Finished copying '${HOST}:${log}' to '$out'" ) &
		proclst="${proclst} $!"
		cnt=$((cnt + 1))
	else
		echo "'$out' already exists, not clobbering..."
	fi
done
if [ $cnt -eq 0 ]; then
	exit 0
fi

echo
echo "Waiting for $cnt bzip/copies to complete..."
echo "Press 'k' to kill bzip/copies, press 'c' to continue with your life"

shopt -qs nullglob
while [ -n "$(checkprocs ${proclst})" ]; do
	REPLY=
	read -t1 -n1 -s
	case "$REPLY" in
		k | K )
			kill ${proclst} 2>/dev/null
			cnt=$(checkprocs ${proclst} | wc -l)
			if [ $cnt -ne 0 ]; then
				echo
				echo "Waiting for $cnt bzip/copies to complete..."
				echo "Press 'k' to kill bzip/copies, press 'c' to continue with your life"
			fi
			;;
		c | C )
			break
			;;
	esac
done

cnt=$(checkprocs ${proclst} | wc -l)
if [ $cnt -ne 0 ]; then
	echo
	echo "Waiting for $cnt bzip/copies to complete..."
fi
