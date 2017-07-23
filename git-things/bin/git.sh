#!/bin/bash
set -x

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)"
GIT_BIN="${HERE}/git-bin"

export PATH="${GIT_BIN}:${PATH}"

command git "$@"
es=$?

if [ $es -eq 16 ]; then
	GIT_CMD="$(command git "$@" 2>&1 | sed -nre '1s/No manual entry for (git-.+)/\1/p')"
	if [ -n "$GIT_CMD" ] && [ -x "${GIT_BIN}/${GIT_CMD}" ]; then
		"${GIT_BIN}/${GIT_CMD}" --help
		es=$?
	fi
fi

exit $es
