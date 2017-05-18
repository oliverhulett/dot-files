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

##	mp3edit
##	@author		Oliver Hulett	<oliver.hulett@gmail.com>
##	@version	0.1		2011/07/03	File created
##				1.0		2011/07/10	Version 1
##
##	Edit tags for mp3 files.  Tags to write (to all files) followed by a dash '-' followed by
##	the files to write.

function usage
{
	echo "Usage:  `basename $0` TAG=VALUE ... - FILES ..."
	echo "        TAGs are added or replaced from listed files."
	echo "        FILEs to be modified."
	if [ -n "$*" ]; then
		echo -e "$*"
	fi
}

##	Map common names to ID3v2 names.
declare -A TAGNAMES
TAGNAMES["COMPILATION"]="TXXX=COMPILATION"
TAGNAMES["LYRICS"]="USLT"
TAGNAMES["GENRE"]="TCON"
TAGNAMES["COMPOSER"]="TCOM"
TAGNAMES["ARTIST"]="TPE1"
TAGNAMES["ALBUMARTIST"]="TPE2"
TAGNAMES["DATE"]="TDAT"
TAGNAMES["YEAR"]="TYER"
TAGNAMES["ALBUM"]="TALB"
TAGNAMES["DISCNUMBER"]="TPOS"
TAGNAMES["TRACKNUMBER"]="TRCK"
TAGNAMES["TITLE"]="TIT2"

declare -a NEWTAGS_KEYS
declare -A NEWTAGS
MODE="tags"
for tok in "$@"; do
	if [ "$tok" = "-" ]; then
		##	Enough tags, lets edit some files.
		MODE="edits"
		continue
	elif [ "$MODE" = "tags" ]; then
		##	Parse input tags.
		if echo $tok | grep "=" 2>&1 >/dev/null; then
			tag=$(echo ${tok/=*/} | tr '[a-z]' '[A-Z]')
			val=${tok/*=/}
			##	Special case for ID3v2 tags with common names.
			if [ -n "$(echo ${TAGNAMES[$tag]})" ]; then
				tag=${TAGNAMES[$tag]}
			fi
			NEWTAGS_KEYS[${#NEWTAGS_KEYS[@]}]="$tag"
			NEWTAGS[$tag]="$val"
		else
			usage "'Tis a fine argument to be sure, but 'tis no tag, english.\nIt's so good, it's got no equals, and there in lies the problem."
			exit 1
		fi
	elif [ "$MODE" = "edits" ]; then
		##	Edit some files.
		if [ -f "$tok" ] && [ -r "$tok" ] && [ -s "$tok" ]; then
			##	File exists, is regular file, is readable and has size greater than zero.
#			echo "FILE = '$tok'"
			echo
		else
			usage "That's not a file:  '$tok'"
			continue
		fi
		##	Get existing tags on file.
		unset FILETAGS
		unset FILETAGS_KEYS
		declare -a FILETAGS_KEYS
		declare -A FILETAGS
		id3v2 -C "$tok" >/dev/null
		eval $(id3v2 -R "$tok" | {
			while read; do
				if echo $REPLY | grep -P "^[A-Z0-9]{4}:" 2>&1 >/dev/null; then
					tag=$(echo ${REPLY/:*/} | tr '[a-z]' '[A-Z]')
					##	Special case for user defined tags, input and output formats differ.
					if [ "$tag" = "TXXX" ]; then
						tag="TXXX=$(echo ${REPLY} | sed -re 's/TXXX: \((.+)\):.+/\1/')"
					fi
					val=$(echo ${REPLY/*:/})
					if [ "$val" != "$REPLY" ]; then
						FILETAGS_KEYS[${#FILETAGS_KEYS[@]}]="$tag"
						FILETAGS[$tag]="$val"
					else
						FILETAGS[$tag]="
$val"
					fi
				fi
			done; declare -p FILETAGS 2>/dev/null; echo -n ';'; declare -p FILETAGS_KEYS
			}
		) 2>/dev/null
		## Hackity hack
		FILETAGS_KEYS=( "${FILETAGS_KEYS[@]}" )
		##	Remember original tags incase of input error.
		##	Input error is not possible for vorbis comments.
		unset ORIGTAGS
		unset ORIGTAGS_KEYS
		declare -a ORIGTAGS_KEYS
#		declare -A ORIGTAGS
		ORIGTAGS_KEYS=( "${FILETAGS_KEYS[@]}" )
		ORIGTAGS=( "${FILETAGS[@]}" )
		##	Merge new tags with existing tags.
		for i in $(printf -- '%s\n' "${NEWTAGS_KEYS[@]}" | sort -u); do
			FILETAGS_KEYS[${#FILETAGS_KEYS[@]}]="$i"
			FILETAGS[$i]="${NEWTAGS[$i]}"
		done
		##	Build argument string.
		cnt=0
		unset ARGS
		declare -a ARGS
		for i in $(printf -- '%s\n' "${FILETAGS_KEYS[@]}" | sort -u); do
			if [ -n "`echo ${FILETAGS[$i]}`" ]; then
				##	Genre for ID3v2 is a number (stupid idea) so output format is name with number
				##	in brackets, lose the number in brackets.
				if [ "$i" = "TCON" ]; then
					FILETAGS[$i]="$(echo ${FILETAGS[$i]} | sed -re 's/ *\(.+\)$//')"
				fi
				ARGS[$cnt]="--$i=${FILETAGS[$i]}"
				##	Special case for user defined tags, input format differes from output format.
				if [ "$i" = "TXXX=COMPILATION" ]; then
					ARGS[$cnt]="--$i:${FILETAGS[$i]}"
				fi
				cnt=$((cnt + 1))
			fi
		done
		##	Write some tags.
		if [ -n "$(echo "${ARGS[@]}")" ]; then
			##	Delete existing tags.
			id3v2 -D "$tok"
			##	Replace with new tags.
			id3v2 "${ARGS[@]}" "$tok"
			if [ "$?" -ne "0" ]; then
				##	Tag write failed, restore original set.
				cnt=0
				unset ARGS
				declare -a ARGS
				for i in $(printf -- '%s\n' "${ORIGTAGS_KEYS[@]}" | sort -u); do
					if [ -n "`echo ${ORIGTAGS[$i]}`" ]; then
						##	Genre for ID3v2 is a number (stupid idea) so output format is name with number
						##	in brackets, lose the number in brackets.
						if [ "$i" = "TCON" ]; then
							ORIGTAGS[$i]="$(echo ${ORIGTAGS[$i]} | sed -re 's/ *\(.+\)$//')"
						fi
						ARGS[$cnt]="--$i=${ORIGTAGS[$i]}"
						##	Special case for user defined tags, input format differes from output format.
						if [ "$i" = "TXXX=COMPILATION" ]; then
							ARGS[$cnt]="--$i:${ORIGTAGS[$i]}"
						fi
						cnt=$((cnt + 1))
					fi
				done
				id3v2 "${ARGS[@]}" "$tok"
			fi
		fi
		##	Print tag set.
		id3v2 -R "$tok" | grep -v 'No ID3v1 tag'
	fi
done
