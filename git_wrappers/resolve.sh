#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

for f in "$@"; do
	if [ -f "$f" ]; then
		vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$f" >/dev/tty 2>/dev/tty
	fi
done
