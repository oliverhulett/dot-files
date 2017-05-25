#!/bin/bash
#
#	Report on the system usage for each development server.
#	Useful for getting the least loaded dev server.
#
HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ $# -eq 0 ]; then
	DEV_SRVS=( $(ssh-list.sh 2>/dev/null | sort -u) )
else
	DEV_SRVS=( "$@" )
fi
declare -a PIDS TMPS

CMDS="sh -c 'mpstat 5 1; echo; free -m; echo; ps -eo pcpu,pid,user,args | sort -k1 -r | head -n3; echo; df -h; echo; echo -n Num Users:\ ; who | cut -d' ' -f1 | sort -u | wc -l;'"

for srv in "${DEV_SRVS[@]}"; do
	filename=`mktemp`
	TMPS[${#TMPS[@]}]="$filename"
	echo "==========================================================================================" >"$filename"
	ssh ${USER}@${srv} "${CMDS}" >>"$filename" 2>/dev/null &
	PIDS[${#PIDS[@]}]=$!
done

echo -n "Waiting..."
wait "${PIDS[@]}"
echo "  Done!"
echo

for filename in "${TMPS[@]}"; do
	cat "$filename"
done

rm "${TMPS[@]}"
