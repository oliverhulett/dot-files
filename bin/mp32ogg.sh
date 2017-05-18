#!/bin/bash

for SRC in "$@"; do
	OGG="${SRC/%mp3/ogg}"
	echo -n "Converting '$SRC' => '$OGG'..."
	if [ ! -e "$OGG" ]; then
		echo
		sox "$SRC" "$OGG"
	else
		echo " Exists"
	fi
	echo
done
