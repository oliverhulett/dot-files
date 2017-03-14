#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

for f in "$@"; do
	if [ -f "$f" ]; then
		vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$f"
	fi
done

