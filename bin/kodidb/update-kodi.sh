#!/usr/bin/env bash

for i in "$@"; do
	KD=
	if [ "$(basename "$i")" == ".kodi-data" ]; then
		KD="$i"
	else
		KD="$i/.kodi-data"
	fi
	if [ ! -e "$KD" ]; then
		continue
	fi
	strPath="$(dirname "$KD" | sed -re "s/'/''/g")/"
	unset columns
	unset values
	declare -a columns
	declare -a values
	eval $(cat "$KD" | {
		while read; do
			columns[${#columns[@]}]="$(echo $(echo $REPLY | cut -d'=' -f1))"
			values[${#values[@]}]="$(echo $(echo $REPLY | cut -d'=' -f2-))"
		done; declare -p columns; echo -n ';'; declare -p values;
	})
	columns=( "${columns[@]}" )
	values=( "${values[@]}" )
	
#	echo "strPath = $strPath"
#	for i in `seq 1 ${#columns[@]}`; do
#		echo "${columns[$((i - 1))]} = ${values[$((i - 1))]}"
#	done
#
#	echo

	updateStr="update path set"
	for i in `seq 1 ${#columns[@]}`; do
		updateStr="${updateStr} ${columns[$((i - 1))]} = ${values[$((i - 1))]},"
	done
	updateStr="${updateStr%,} where strPath = '${strPath}';"

	echo $updateStr

	insertStr="insert into path (strPath"
	for i in `seq 1 ${#columns[@]}`; do
		insertStr="${insertStr}, ${columns[$((i - 1))]}"
	done
	insertStr="${insertStr}) select '${strPath}'"
	for i in `seq 1 ${#values[@]}`; do
		insertStr="${insertStr}, ${values[$((i - 1))]}"
	done
	insertStr="${insertStr} where not exists (select changes() as change from path where change <> 0);"

	echo $insertStr
	echo
done

