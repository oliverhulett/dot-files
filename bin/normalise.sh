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

##	normalise
##	@author		Oliver Hulett	<oliver.hulett@gmail.com>
##	@version	0.1		2012/02/29	File created
##
##	Normalise OGG and MP3 files using tag information and folder hierarchy to guess at albums.

function usage
{
	echo "Usage:  `basename $0` DIRS..."
	echo "        DIRS  Directories containing audio files."
	if [ -n "$*" ]; then
		echo -e "$*"
	fi
}

##	Map common names to ID3v2 names.
declare -A TAGNAMES
TAGNAMES["COMPILATION"]="COMPILATION"
TAGNAMES["GENRE"]="TCON"
TAGNAMES["COMPOSER"]="TCOM"
TAGNAMES["ARTIST"]="TPE1"
TAGNAMES["DATE"]="TDAT"
TAGNAMES["YEAR"]="TYER"
TAGNAMES["ALBUM"]="TALB"
TAGNAMES["DISCNUMBER"]="TPOS"
TAGNAMES["TRACKNUMBER"]="TRCK"
TAGNAMES["TITLE"]="TIT2"

function do_files
{
	CMD=$1
	shift
# 	ARGS="-v"
	ARGS=
	AS_BATCH=
	if [ "$1" = "-b" ]; then
		ARGS="$ARGS -b"
		AS_BATCH=" as a batch"
		shift
	elif [ "$1" = "-m" ]; then
		ARGS="$ARGS -m"
		AS_BATCH=" as a mix"
		shift
	fi
	if [ $# -ne 0 ] && [ -n "$CMD" ]; then
		DIR="$(dirname "$1")"
		if echo $(basename "$DIR") | grep -E 'Disc_[0-9]+$' >/dev/null 2>&1; then
			if [ -e "$DIR/.normalised" ]; then
				rm -v "$DIR/.normalised"
			fi
			DIR="$(dirname "$DIR")"
		fi
		FILE="$(mktemp --tmpdir=/tmp normalise.XXXXXXXXX)"
		echo "$DIR"
		echo "Normalising files$AS_BATCH:" "$@" | sed -re 's!'"$DIR"'/*! !g' | tee "$FILE"
		if diff -NiqwB --strip-trailing-cr "$FILE" "$DIR/.normalised" >/dev/null 2>&1; then
			echo "Files already normalised."
			rm "$FILE"
			return
		fi
		$CMD $ARGS -- "$@" &&  mv "$FILE" "$DIR/.normalised"
		rm /tmp/*.wav 2>/dev/null
	fi
}

function do_mp3s
{
	CMD="normalize-mp3 --mp3 --tmpdir /tmp"
	BATCH="-b"

	local LAST_ALBUM LAST_ARTIST COMPILATION
	for f in "$@"; do
		local -A FILETAGS
		eval $(id3v2 -R "$f" | {
			while read; do
				if echo $REPLY | grep -P "^[A-Z0-9]{4}:" 2>&1 >/dev/null; then
					tag=$(echo ${REPLY/:*/} | tr '[a-z]' '[A-Z]')
					##	Special case for user defined tags, input and output formats differ.
					if [ "$tag" = "TXXX" ]; then
						tag="TXXX=$(echo ${REPLY} | sed -re 's/TXXX: \((.+)\):.+/\1/')"
					fi
					val=$(echo ${REPLY/*:/})
					FILETAGS[$tag]="$val"
				fi
			done; declare -p FILETAGS
			}
		)
		ARTIST="${FILETAGS[${TAGNAMES["ARTIST"]}]}"
		ALBUM="${FILETAGS[${TAGNAMES["ALBUM"]}]}"
		COMPILATION="${FILETAGS[${TAGNAMES["COMPILATION"]}]}"
		if [ -z "$LAST_ALBUM" ]; then
			LAST_ALBUM="$ALBUM"
		fi
		if [ -z "$LAST_ARTIST" ]; then
			LAST_ARTIST="$ARTIST"
		fi

		##	Rules for batching.
		##		If set has a common artist and album, batch.
		##		If set has a common album and compilation flag set, batch.
		##		If set has a common artist but unknown album, mix.
		if [ "$ALBUM" != "$LAST_ALBUM" ]; then
			BATCH=
			break
		fi
		if [ "$ARTIST" != "$LAST_ARTIST" ]; then
			if [ "$COMPILATION" != "1" ]; then
				BATCH=
				break
			fi
		fi
	done
	if [ "$LAST_ALBUM" = "" ]; then
		BATCH="-m"
	fi
	if [ $# -le 1 ]; then
		BATCH=
	fi

	do_files "$CMD" $BATCH "$@"
}

function do_oggs
{
	CMD="normalize-ogg --ogg --tmpdir /tmp"
	BATCH="-b"

	local LAST_ALBUM LAST_ARTIST COMPILATION
	for f in "$@"; do
		local -A FILETAGS
		eval $(vorbiscomment "$f" | {
				while read; do
						if echo $REPLY | grep "=" 2>&1 >/dev/null; then
								tag=$(echo ${REPLY/=*/} | tr '[a-z]' '[A-Z]')
								val=${REPLY/*=/}
								FILETAGS[$tag]="$val"
						fi
				done; declare -p FILETAGS
				}
		)

		ARTIST="${FILETAGS["ARTIST"]}"
		ALBUM="${FILETAGS["ALBUM"]}"
		COMPILATION="${FILETAGS["COMPILATION"]}"
		if [ -z "$LAST_ALBUM" ]; then
			LAST_ALBUM="$ALBUM"
		fi
		if [ -z "$LAST_ARTIST" ]; then
			LAST_ARTIST="$ARTIST"
		fi

		##	Rules for batching.
		##		If set has a common artist and album, batch.
		##		If set has a common album and compilation flag set, batch.
		##		If set has a common artist but unknown album, mix.
		if [ "$ALBUM" != "$LAST_ALBUM" ]; then
			BATCH=
			break
		fi
		if [ "$ARTIST" != "$LAST_ARTIST" ]; then
			if [ "$COMPILATION" != "1" ]; then
				BATCH=
				break
			fi
		fi
	done
	if [ "$LAST_ALBUM" = "" ]; then
		BATCH="-m"
	fi
	if [ $# -le 1 ]; then
		BATCH=
	fi

	do_files "$CMD" $BATCH "$@"
}

function do_wavs
{
	CMD="normalize-audio"

	do_files "$CMD" "$@"
}

function do_dir
{
	local -a MP3S OGGS WAVS DISC
	for f in "$@"; do
		if [ -d "$f" ]; then
			if echo $f | grep -E 'Disc_[0-9]+$' >/dev/null 2>&1; then
				for d in "$f"/*; do
					DISC[${#DISC[@]}]="$d"
				done
			else
				do_dir "$f"/*
			fi
		elif [ -f "$f" ]; then
			if echo $f | grep -E '\.mp3$' >/dev/null 2>&1; then
				MP3S[${#MP3S[@]}]="$f"
			elif echo $f | grep -E '\.ogg$' >/dev/null 2>&1; then
				OGGS[${#OGGS[@]}]="$f"
			elif echo $f | grep -E '\.wav$' >/dev/null 2>&1; then
				WAVS[${#WAVS[@]}]="$f"
			else
				echo "Unknown file type is unknown:  $f"
				continue
			fi
		else
			echo "What in the hell is this?  $f"
			continue
		fi
	done
	if [ ${#DISC[@]} -gt 0 ]; then
		do_dir "${DISC[@]}"
	fi
	if [ ${#MP3S[@]} -gt 0 ]; then
		do_mp3s "${MP3S[@]}"
	fi
	if [ ${#OGGS[@]} -gt 0 ]; then
		do_oggs "${OGGS[@]}"
	fi
	if [ ${#WAVS[@]} -gt 0 ]; then
		do_wavs "${WAVS[@]}"
	fi
}

declare -a MP3S OGGS WAVS
for arg in "$@"; do
	if [ -d "$arg" ]; then
		do_dir "$arg"/*
	elif [ -f "$arg" ]; then
		if echo $arg | grep -E '\.mp3$' >/dev/null 2>&1; then
			MP3S[${#MP3S[@]}]="$arg"
		elif echo $arg | grep -E '\.ogg$' >/dev/null 2>&1; then
			OGGS[${#OGGS[@]}]="$arg"
		elif echo $arg | grep -E '\.wav$' >/dev/null 2>&1; then
			WAVS[${#WAVS[@]}]="$arg"
		else
			echo "Unknown file type is unknown:  $arg"
		fi
	else
		echo "What in the hell is this?  $arg"
	fi
	do_mp3s "${MP3S[@]}"
	do_oggs "${OGGS[@]}"
	do_wavs "${WAVS[@]}"
done
