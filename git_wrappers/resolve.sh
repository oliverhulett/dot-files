#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

for f in "$@"; do
	if [ -f "$f" ]; then
		vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$f" >"${_orig_stdout}" 2>"${_orig_stderr}"
	fi
done
