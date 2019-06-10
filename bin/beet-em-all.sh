#!/usr/bin/env bash

set -x
set -e

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-a] [--all]"
	echo "    -a --all: Run all the subcommands"
}

OPTS=$(getopt -o "a" --long "all" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

ALL="false"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-a | --all )
			ALL="true"
			shift
			;;
		-- ) shift; break ;;
		* )
			print_help
			exit 1
			;;
	esac
done

CMDS=( "fingerprint" "replaygain" "acousticbrainz" "mbsync" "absubmit" "submit" "update" "move" )
CMDS_EXTRA=( "lyrics" "fetchart" )
for c in "${CMDS[@]}"; do
	beet "$c"
done
if [ "${ALL}" == "true" ]; then
	for c in "${CMDS_EXTRA[@]}"; do
		beet "$c" &
	done
	wait -f
fi
