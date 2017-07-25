#!/bin/bash
#
#	Push a list of files to the development servers.
#
HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

declare -a DEV_SRVS DIRS SPLITS
RSYNC_ARG=

function canonicalise()
{
	fpart=
	dpart="$1"
	if [ -f "$1" -o -L "$1" ]; then
		fpart="$(basename -- "$1")"
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

if [ ${#DIRS[@]} -eq 0 ] || [ ${#SPLITS[@]} -eq 0 ]; then
	exit 0
fi
if [ ${#DEV_SRVS[@]} -eq 0 ]; then
	DEV_SRVS=( $(ssh-list.sh 2>/dev/null | sort -u) )
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
	shift
	relay_cmd=()
	rsync_relay_cmd=()
	if [ -n "$1" ]; then
		relay_cmd=( "-o" "ProxyCommand ssh -W %h:%p $1" )
		rsync_relay_cmd=( "-e" "ssh -o 'ProxyCommand ssh -W %h:%p $1'" )
	fi
	echo "Server: $srv  ============================================================================"
	run ssh "${relay_cmd[@]}" "${USER}@${srv}" "rm -v $(printf "'%s' " "${DIRS[@]}") 2>/dev/null; mkdir -pv $(printf "'%s' " "${DIRS[@]}")" 2>&${log_fd}
	for i in "${!DIRS[@]}"; do
		echo
		run rsync "${rsync_relay_cmd[@]}" -zpPXrogthlcm ${RSYNC_ARG} ${SPLITS[$i]} ${USER}@${srv}:"'${DIRS[$i]}/'" || echo -e "\n\nFailed to push files to ${USER}@${srv}" >&2
	done
	echo
}

for srv in "${DEV_SRVS[@]}"; do
	relay="${srv%%:*}"
	if [ "${relay}" == "${srv}" ]; then
		relay=
	else
		srv="${srv#*:}"
	fi
	srv="$(ssh-name.sh "$relay:$srv")"

	if [ -z "$srv" ]; then
		continue
	fi
	if [ "$srv" = "$(hostname)" ]; then
		continue
	fi
	if [ "$srv" = "localhost" ]; then
		continue
	fi
	do_svr "$srv" "${relay}"
done
