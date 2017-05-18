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

##	oggedit
##	@author		Oliver Hulett	<oliver.hulett@gmail.com>
##	@version	0.1		2011/07/03	File created
##				1.0		2011/07/10	Version 1
##
##	Edit tags for vorbis files.  Tags to write (to all files) followed by a dash '-' followed by
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

declare -A NEWTAGS
declare -a NEWTAGS_KEYS
MODE="tags"
for tok in "$@"; do
	if [ "$tok" = "-" ]; then
		##	Enough tags, lets edit some files.
		MODE="edits"
		continue
	elif [ "$MODE" = "tags" ]; then
		##	parse tags from standard input.
		if echo $tok | grep "=" 2>&1 >/dev/null; then
			tag=$(echo ${tok/=*/} | tr '[a-z]' '[A-Z]')
			val=${tok/*=/}
			NEWTAGS_KEYS[${#NEWTAGS_KEYS[@]}]="$tag"
			NEWTAGS[$tag]="$val"
		else
			usage "'Tis a fine argument to be sure, but 'tis no tag english.\nIt's so good, it's got no equals, and there in lies the problem."
			exit 1
		fi
	elif [ "$MODE" = "edits" ]; then
		##	Write tags to file.
		if [ -f "$tok" ] && [ -r "$tok" ] && [ -s "$tok" ]; then
			##  File exists, is regular file, is readable and has size greater than zero.
			echo "FILE = '$tok'"
		else
			usage "That's not a file:  '$tok'"
			continue
		fi
		unset FILETAGS
		unset FILETAGS_KEYS
		declare -A FILETAGS
		declare -a FILETAGS_KEYS
		eval $(vorbiscomment "$tok" | {
			while read; do
				if echo $REPLY | grep "=" >/dev/null 2>&1; then
					tag=$(echo ${REPLY/=*/} | tr '[a-z]' '[A-Z]')
					val=${REPLY/*=/}
					FILETAGS_KEYS[${#FILETAGS_KEYS[@]}]="$tag"
					FILETAGS[$tag]="$val"
				else
					FILETAGS[$tag]="
$REPLY"
				fi
			done; declare -p FILETAGS 2>/dev/null; echo -n ';'; declare -p FILETAGS_KEYS 2>/dev/null
			}
		) 2>/dev/null
		## Hackity hack?
		FILETAGS_KEYS=( "${FILETAGS_KEYS[@]}" )
		for i in $(printf -- '%s\n' "${NEWTAGS_KEYS[@]}" | sort -u); do
			FILETAGS_KEYS[${#FILETAGS_KEYS[@]}]="$i"
			FILETAGS[$i]="${NEWTAGS[$i]}"
		done
		##	Build command line.
		cnt=0
		unset ARGS
		declare -a ARGS
		for i in $(printf -- '%s\n' "${FILETAGS_KEYS[@]}" | sort -u); do
			if [ -n "`echo ${FILETAGS[$i]}`" ]; then
				ARGS[$cnt]="-t"
				cnt=$((cnt + 1))
				ARGS[$cnt]="$i=${FILETAGS[$i]}"
				cnt=$((cnt + 1))
			fi
		done
		if [ -n "${ARGS[*]}" ]; then
			##	Write new tag set to file.
			vorbiscomment -w "$tok" "${ARGS[@]}"
		fi
		##	Print new tag set.
		vorbiscomment "$tok"
	fi
done

