#!/bin/bash
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

##	oggfs
##	@author		Oliver Hulett	<oliver.hulett@gmail.com>
##	@version	0.1		2011/07/03	File created
##
##	File Ogg Vorbis music files by ARTIST/YEAR-ALBUM/disc_DISCNUMBER/TRACKNUMBER-TITLE.ogg.
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

find "$SRC/" -type f -iname '*.ogg' | while read -r FILE; do
	if [ -n "${FILE#$SRC}" ]; then
		##	Get tags from file.
		TAG=
		COMPILATION=
		ARTIST=
		DATE=
		YEAR=
		ALBUM=
		DISCNUMBER=
		TRACKNUMBER=
		TITLE=
		OGGINFO="$(ogginfo "$FILE")"
		for TAG in COMPILATION ARTIST DATE YEAR ALBUM DISCNUMBER TRACKNUMBER TITLE; do
			eval "$TAG=$(echo -e "$OGGINFO" | grep -iE '^[[:space:]]*'"${TAG}=" | sed -re 's/.*'"$TAG"'=(.+)/\1/i' | sed -re 's/[^0-9a-zA-Z]+/_/g')"
		done

		if [ -z "$TITLE" ]; then
			continue
		fi

		if [ -n "$YEAR" ]; then
			DATE="$YEAR"
		fi

		##	For artist name, move leading 'The' to the back.
		ARTIST=$(echo $ARTIST | sed -re 's/^The_(.+)_?$/\1_The/i')

		ALBUM_PART=
		if [ -n "$DATE" ]; then
			ALBUM_PART="${ALBUM_PART}${DATE:0:4}-"
		fi
		if [ -n "$ALBUM" ]; then
			ALBUM_PART="${ALBUM_PART}${ALBUM}/"
		fi
		if [ -n "$DISCNUMBER" ]; then
			DISC_TOTAL=$(echo $DISCNUMBER | sed -nre 's/([0-9]+)[^0-9]([0-9]+)/\2/p')
			if [ -n "$DISC_TOTAL" ]; then
				DISCNUMBER=$(echo $DISCNUMBER | sed -nre 's/([0-9]+)[^0-9][0-9]+/\1/p')
				if [ "$DISC_TOTAL" = "1" ] || [ "$DISC_TOTAL" = "0" ]; then
					DISCNUMBER="0"
				fi
			fi
			if [ "$DISCNUMBER" != "0" ]; then
				ALBUM_PART="${ALBUM_PART}Disc_${DISCNUMBER}/"
			fi
		fi

		TRACK_PART=
		if [ -n "$TRACKNUMBER" ]; then
			##	Force track number to two digits.
			TRACK_PART="$(echo $TRACKNUMBER | awk '{printf "%02d", $1}')-"
		fi

		NAME=
		if [ "$FORCE_COMPILATION" == "true" ] || [ "$COMPILATION" = "1" ]; then
			NAME="${ALBUM_PART}${TRACK_PART}"
			if [ -n "$ARTIST" ]; then
				NAME="${NAME}${ARTIST}-"
			fi
			NAME="${NAME}${TITLE}.ogg"
		else
			if [ -n "$ARTIST" ]; then
				NAME="${ARTIST}/"
			fi
			NAME="${NAME}${ALBUM_PART}${TRACK_PART}"
			NAME="${NAME}${TITLE}.ogg"
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
