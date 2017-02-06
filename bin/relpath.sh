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
if [ ! -e "$SRC" ]; then
	echo >&2 "$SRC does not exist"
	exit 1
fi
SRC="$(cd "$SRC" 2>/dev/null && pwd)"

DEST="$1"
FILEPART=
if [ -f "$DEST" ]; then
	FILEPART="$(basename "$DEST")"
	DEST="$(dirname "$DEST")"
fi
if [ ! -e "$DEST" ]; then
	echo >&2 "$DEST does not exist"
	exit 1
fi
DEST="$(cd "$DEST" 2>/dev/null && pwd)"

crs="$(echo $SRC | rev)"
tsed="$(echo $DEST | rev)"

while [ "$(basename "$crs")" == "$(basename "$tsed")" ]; do
	crs="$(dirname "$crs")"
	tsed="$(dirname "$tsed")"
done

depth=$(echo -n $crs | grep -o / | wc -l)
if [ "$crs" != "." ]; then
	depth=$((depth + 1))
fi
DEPTHPART="$(for (( i=0; i < $depth; i++ )); do echo -n '../'; done)"
DIRPART="$(echo -n $tsed | rev)"
echo "${DEPTHPART}${DIRPART}/${FILEPART}"
