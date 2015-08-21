#!/bin/bash

for f in "$@"; do
	if [ -f "$f" ]; then
		vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$f"
	fi
done

