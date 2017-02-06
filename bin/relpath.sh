#!/bin/bash

if [ $# -eq 1 ]; then
	SRC="$(pwd)"
else
	SRC="$1"
	shift
fi
if [ -f "$SRC" ]; then
	SRC="$(dirname "$SRC")"
fi
SRC="$(cd "$SRC" && pwd)"

DEST="$1"
FILEPART=
if [ -f "$DEST" ]; then
	FILEPART="$(basename "$DEST")"
	DEST="$(dirname "$DEST")"
fi
DEST="$(cd "$DEST" && pwd)"

crs="$(echo $SRC | rev)"
tsed="$(echo $DEST | rev)"

while [ "$(basename "$crs")" == "$(basename "$tsed")" ]; do
	crs="$(dirname "$crs")"
	tsed="$(dirname "$tsed")"
done

depth=$(echo $crs | sed -re 's!/!\n!g' | wc -l)
DEPTHPART="$(for (( i=0; i < $depth; i++ )); do echo -n '../'; done)"
DIRPART="$(echo -n $tsed | rev)"
echo "${DEPTHPART}${DIRPART}/${FILEPART}"
