#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

for f in "$@"; do
	if [ -f "$f" ]; then
		vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$f" >"${_orig_stdout}" 2>"${_orig_stderr}"
	fi
done
