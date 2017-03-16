#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

set -- $(echo "$@" | tr '/' ' ')
if [ $# -lt 1 ]; then
	exit 1
fi
if [ -d "${HOME}/repo/$1" ]; then
	proj="$1"
	repo="$2"
	shift 2
else
	proj='*'
	repo="$1"
	shift
fi
branch="${1:-master}"
shift
shopt -s nullglob
for d in ${HOME}/repo/${proj}/${repo}/${branch}/"$(echo $* | tr ' ' '/')"; do
	echo "$d"
done
