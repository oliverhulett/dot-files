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

OPTS=$(getopt -o "aynh" --long "all,yes,no,help" -n "$(basename -- "$0")" -- "$@")
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

function do_cmd()
{
	if [ ${ALL} -ge "$1" ]; then
		echo beet "$2"
		if [ "${NO}" == "false" ]; then
			if [ "${YES}" == "true" ] || ask; then
				beet "$2"
			fi
		fi
	fi
}

for lvl_cmd in \
	"2:fingerprint" \
	"2:replaygain" \
	"1:acousticbrainz" \
	"1:mbsync" \
	"0:scrub" \
	"0:update" \
	"0:move" \
	"3:lyrics" \
	"3:fetchart" \
	"4:absubmit" \
	"4:submit" \
; do
	lvl="${lvl_cmd%%:*}"
	cmd="${lvl_cmd#*:}"
	do_cmd "$lvl" "$cmd"
done
