#!/bin/bash

DIR=( "/home/removables/external-3/Music.staging" )
if [ $# -gt 0 ]; then
	DIR=( "$@" )
fi

find "${DIR[@]}" -type f | while read; do
	mp3file=$(echo $REPLY | sed -re 's/(\.ogg)|(\.mp3)$/.mp3/')
	oggfile=$(echo $REPLY | sed -re 's/(\.ogg)|(\.mp3)$/.ogg/')

	if [ -f "$mp3file" -a ! -f "$oggfile" ]; then
		mp32ogg "$mp3file"
	elif [ -f "$oggfile" -a ! -f "$mp3file" ]; then
		ogg2mp3 "$oggfile"
	fi
done

LIST="$(find "${DIR[@]}" | sort)"

for d in "${DIR[@]}"; do
	mp3fs "$d"
	oggfs "$d"
	rmemptydir "$d"
done

if [ "$LIST" == "$(find "${DIR[@]}" | sort)" ]; then
	for d in "${DIR[@]}"; do
		mp3fs "$d"
		oggfs "$d"
		rmemptydir "$d"
	done
fi
