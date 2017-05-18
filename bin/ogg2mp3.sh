#!/bin/bash

for SRC in "$@"; do
	MP3="${SRC/%ogg/mp3}"
	echo -n "Converting '$SRC' => '$MP3'"
	if [ ! -e "$MP3" ]; then
		echo
		sox "$SRC" "$MP3"
	else
		echo " Exists"
	fi
	echo
done
