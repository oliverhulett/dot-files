#!/bin/bash
#
#	Push a list of files to the development servers.
#
source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

declare -a DEV_SRVS=

declare -a DIRS SPLITS
RSYNC_ARG=

function canonicalise()
{
	fpart=
	dpart="$1"
	if [ -f "$1" -o -L "$1" ]; then
		fpart="$(basename "$1")"
		dpart="$(dirname "$1")"
	fi
	if [ -d "$dpart" ]; then
		pushd "$dpart" >/dev/null 2>/dev/null
		dpart="$(pwd -P)"
		popd >/dev/null 2>/dev/null
	fi
	echo "${dpart}/${fpart}"
}

for filename in "$@"; do
	if [ "${filename: -1}" == ":" ]; then
		DEV_SRVS[${#DEV_SRVS[@]}]="${filename:0:${#filename} - 1}"
		continue
	fi
	if [ "${filename:0:1}" == "-" ]; then
		RSYNC_ARG="${RSYNC_ARG} $filename"
		continue
	fi
	filename="$(canonicalise "$filename")"
	if [ "${filename: -1}" == "/" ]; then
		dirname="${filename%/}"
	else
		dirname="$(dirname "$filename")"
	fi
	if [ -e "$filename" ]; then
		for i in "${!DIRS[@]}"; do
			if [ "${dirname}" == "${DIRS[$i]}" ]; then
				SPLITS[$i]="${SPLITS[$i]} $filename"
				break
			fi
		done
		if [ "${dirname}" != "${DIRS[$i]}" ]; then
			DIRS[${#DIRS[@]}]="$dirname"
			SPLITS[${#SPLITS[@]}]="$filename"
		fi
	fi
done

if [ ${#DEV_SRVS[@]} -eq 0 ]; then
	DEV_SRVS=( $(ssh-ping.sh 2>/dev/null | sort -u) )
fi

# echo DEV_SRVS = "${DEV_SRVS[@]}"
# echo DIRS = "${DIRS[@]}"
# echo SPLITS = "${SPLITS[@]}"

function run()
{
	echo "$@"
	"$@"
}

function do_svr()
{
	srv="$1"
	echo "Server: $srv  ============================================================================"
	run ssh ${USER}@${srv} "rm -v $(printf "'%s' " "${DIRS[@]}") 2>/dev/null; mkdir -pv $(printf "'%s' " "${DIRS[@]}")" 2>&${log_fd}
	for i in ${!DIRS[@]}; do
		echo
		run rsync -zpPXrogthlcm ${RSYNC_ARG} ${SPLITS[$i]} ${USER}@${srv}:"'${DIRS[$i]}/'" || echo -e "\n\nFailed to push files to ${USER}@${srv}" >&2
	done
	echo
}

for srv in "${DEV_SRVS[@]}"; do
	if [ -z "$srv" ]; then
		continue
	fi
	if [ "$srv" = "$(hostname)" ]; then
		continue
	fi
	if [ "$srv" = "localhost" ]; then
		continue
	fi
	do_svr "$srv"
done
