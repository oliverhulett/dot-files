#!/bin/bash
## The git alias will call from the directory in which the alias was called ($GIT_PREFIX).
set -e

cp -nv "$@"

declare -a toadd
for arg in "${@:1:$# - 1}"; do
	if [ "${arg:0:1}" != "-" ]; then
		toadd[${#toadd[@]}]="${@:$#}/$(basename -- $arg)"
	fi
done

if [ ${#toadd[@]} -eq 1 ] && [ ! -d "${toadd[0]}" ]; then
	toadd=( "${@:$#}" )
fi

git add -v --ignore-removal --ignore-errors "${toadd[@]}"
