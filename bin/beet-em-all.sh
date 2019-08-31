#!/usr/bin/env bash

set -e

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-a] [--all] [-y | -n] [--yes | --no]"
	echo "    -a --all: Run all the subcommands, can be specified more than once to run more subcommands"
	echo "    -y --yes: Answer yes to the confirmation prompts"
	echo "    -n --no:  Answer no to the confirmation prompts"
}

OPTS=$(getopt -o "ayn" --long "all,yes,no" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

ALL=0
YES="false"
NO="false"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-a | --all )
			ALL=$((ALL + 1))
			shift
			;;
		-y | --yes)
			YES="true"
			shift
			;;
		-n | --no)
			NO="true"
			shift
			;;
		-- ) shift; break ;;
		* )
			print_help
			exit 1
			;;
	esac
done

function ask()
{
	read -r -p"Run command? [Y/n] " -n1
	echo
	[ "${REPLY,,}" != "n" ]
}

CMDS=( "fingerprint" "replaygain" "acousticbrainz" "mbsync" "scrub" "update" "move" )
CMDS_EXTRA=( "lyrics" "fetchart" )
CMDS_EXTRA_EXTRA=( "absubmit" "submit" )
for c in "${CMDS[@]}"; do
	echo beet "$c"
	if [ "${NO}" == "false" ]; then
		if [ "${YES}" == "true" ] || ask; then
			beet "$c"
		fi
	fi
done
if [ ${ALL} -eq 1 ]; then
	for c in "${CMDS_EXTRA[@]}"; do
		echo beet "$c"
		if [ "${NO}" == "false" ]; then
			if [ "${YES}" == "true" ] || ask; then
				beet "$c"
			fi
		fi
	done
#	wait -f
fi
if [ ${ALL} -gt 1 ]; then
	for c in "${CMDS_EXTRA_EXTRA[@]}"; do
		echo beet "$c"
		if [ "${NO}" == "false" ]; then
			if [ "${YES}" == "true" ] || ask; then
				beet "$c"
			fi
		fi
	done
#	wait -f
fi
