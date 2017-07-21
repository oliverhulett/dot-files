#!/bin/bash

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)"
GIT_BIN="${HERE}/git-bin"

declare -a ARGS
HELP=
GIT_CMD=
while [ $# -gt 0 ]; do
	case "$1" in
		-h | '-?' | --help )
			HELP="$1";
			ARGS[${#ARGS[@]}]="--help"
			shift
			;;
		--version | \
		--html-path | \
		--man-path | \
		--info-path | \
		-p | --paginate | --no-pager | \
		--no-replace-objects | \
		--bare | \
		--exec-path | --exec-path=* | \
		--git-dir=* | \
		--work-tree=* | \
		--namespace=* )
			ARGS[${#ARGS[@]}]="$1"
			shift
			;;
		-c | \
		--git-dir | \
		--work-tree | \
		--namespace )
			ARGS[${#ARGS[@]}]="$1"
			shift
			ARGS[${#ARGS[@]}]="$1"
			shift
			;;
		-- )
			shift
			;;
		* )
			GIT_CMD="$1"
			shift
			break
			;;
	esac
done
for c in "$@"; do
	case "$c" in
		-h | '-?' | --help )
			HELP="$c"
			break
			;;
	esac
done

PATH="${GIT_BIN}:${PATH}" command git "${ARGS[@]}" "${GIT_CMD}" "$@"
es=$?

if [ $es -ne 0 ]; then
	if [ -n "$HELP" ] && [ -n "$GIT_CMD" ] && [ -x "${GIT_BIN}/git-${GIT_CMD}" ]; then
		"${GIT_BIN}/git-${GIT_CMD}" "${HELP}"
		es=$?
	fi
fi

exit $es
