#!/usr/bin/env bash

OPTS=$(getopt -o "ac:" --long "all,count:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	exit $es
fi

COUNT="--max-count=10"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-c | --count )
			COUNT="--max-count=$2"
			shift 2
			;;
		-a | --all )
			COUNT=
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

if echo "$1" | grep -qwE '[0-9]+'; then
	COUNT="--max-count=$1"
	shift
fi
git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd)%C(bold blue)<%an>%Creset' --abbrev-commit $COUNT "$@"
