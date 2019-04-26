#!/usr/bin/env bash
####################################################################################################
#	Copyright (C) 2008 Oliver Slocombe Hulett <oliver.hulett@gmail.com>
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
####################################################################################################

##	mp3fs
##	@author		Oliver Hulett	<oliver.hulett@gmail.com>
##	@version	0.1		2011/07/03	File created
##
##	File mp3 music files by TPE1/TYER-TALB/disc_TPOS/TRCK-TIT2.mp3.
##	Additionally replace non alphanum characters with underscores.

function usage
{
	echo "Usage:  $(basename -- "$0") [-c|--compilation] <src_root> [<dest_root>]"
	echo "		-c|--compilation  Force compilation format."
	echo "		<src_root> is used as <dest_root> if the latter is omitted."
	if [ -n "$*" ]; then
		echo "$*"
	fi
}

if [ $# -lt 1 ]; then
	usage "Incorrect number of arguments."
	exit 1
fi

FORCE_COMPILATION="false"
if [ "$1" == "-c" ] || [ "$1" == "--compilation" ]; then
	FORCE_COMPILATION="true"
	shift
fi

if [ $# -gt 2 ]; then
	usage "Incorrect number of arguments."
	exit 1
fi

if [ -d "$1" ]; then
	SRC="${1%/}"
else
	usage "<src_root> must be a directory."
	exit 1
fi

if [ $# -eq 2 ]; then
	if [ -d "$2" ]; then
		DEST="${2%/}"
	else
		usage "<dest_root> must be a directory."
		exit 1
	fi
else
	DEST=$SRC
fi

export LC_ALL=C

find "$SRC/" -type f -iname '*.mp3' | while read -r FILE; do
	if [ -f "${FILE}" ]; then
		##	Get tags from file.
		TAG=
		TPE1=
		#TDAT=
		TYER=
		TALB=
		TPOS=
		TRCK=
		TIT2=
		id3v2 -C "$FILE" >/dev/null
		MP3INFO="$(id3v2 -R "$FILE")"
		for TAG in TPOS TPE1 TYER TALB TPOS TRCK TIT2; do
			eval "$TAG=$(echo -e "$MP3INFO" | grep -iE '^[[:space:]]*'"${TAG}:" | sed -re 's/.*'"$TAG"': *(.+)/\1/i' | sed -re 's/[^0-9a-zA-Z]+/_/g')"
		done
		##	Special case for COMPILATION, ID3v2 doesn't have a compilation tag, so use a user defined tag.
		COMPILATION=$(echo -e "$MP3INFO" | grep -i "TXXX: (COMPILATION):" | sed -re 's/.*TXXX: \(COMPILATION\): *(.+)/\1/i')

		if [ -z "$TIT2" ]; then
			continue
		fi

		##	Prefer YEAR (TYER) to DATE (TDAT)
#		if [ -n "$TYER" ]; then
#			TDAT="$TYER"
#		fi

		##	For ARTIST, move leading 'The' to end of name.
		TPE1=$(echo $TPE1 | sed -re 's/^The_(.+)_?$/\1_The/i')

		TALB_PART=
		if [ -n "$TYER" ]; then
			TALB_PART="${TALB_PART}${TYER:0:4}-"
		fi
		if [ -n "$TALB" ]; then
			TALB_PART="${TALB_PART}${TALB}/"
		fi

		if [ -n "$TPOS" ]; then
			DISC_TOTAL=$(echo $TPOS | sed -nre 's/([0-9]+)[^0-9]([0-9]+)/\2/p')
			if [ -n "$DISC_TOTAL" ]; then
				TPOS=$(echo $TPOS | sed -nre 's/([0-9]+)[^0-9][0-9]+/\1/p')
				if [ "$DISC_TOTAL" = "1" ] || [ "$DISC_TOTAL" = "0" ]; then
					TPOS="0"
				fi
			else
				if [ "$TPOS" = "1" ]; then
					TPOS="0"
				fi
			fi
			if [ "$TPOS" != "0" ]; then
				TALB_PART="${TALB_PART}Disc_${TPOS}/"
			fi
		fi

		TRACK_PART=
		if [ -n "$TRCK" ]; then
			##	Force two digits for track number.
			TRACK_PART="$(echo $TRCK | awk '{printf "%02d", $1}')-"
		fi

		NAME=
		if [ "$FORCE_COMPILATION" == "true" ] || [ "$COMPILATION" = "1" ]; then
			NAME="${TALB_PART}${TRACK_PART}"
			if [ -n "$TPE1" ]; then
				NAME="${NAME}${TPE1}-"
			fi
			NAME="${NAME}${TIT2}.mp3"
		else
			if [ -n "$TPE1" ]; then
				NAME="${TPE1}/"
			fi
			NAME="${NAME}${TALB_PART}${TRACK_PART}"
			NAME="${NAME}${TIT2}.mp3"
		fi

		mkdir -p "$(dirname "${DEST}/${NAME}")"
		FILE="$(readlink -f "$FILE")"
		DEST_FILE="$(readlink -f "${DEST}/${NAME}")"
		if [ "$FILE" == "${DEST_FILE}" ]; then
			echo "$FILE"
		else
			mv -fv "$FILE" "${DEST_FILE}"
		fi
	fi
done
