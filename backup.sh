#!/bin/bash
## Backup local files to another local directory that'll be synced to the cloud.
## Version 1 will just use rsync to copy stuff as diffs/hard-link
## Version 2 will compress and/or encrypt the backup directory.  I have to work a few things out before I can do that.
## e.g. How does Google drive sync deal with the hard-links?  How does rsync deal with linking diffs on compressed and encrypted file systems.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${HERE}/lib/script_utils.sh"

reentrance_check

export LC_ALL=C
RSYNC_ARGS=( -rpAXogthR --one-file-system --links --delete --delete-excluded --stats )
BACKUP_DEST="${HOME}/etc/backups"

# Get backup sources from files
HOSTNAME="$(hostname -s | tr '[:upper:]' '[:lower:]')"
FILES_FROM="${HERE}/backups.${HOSTNAME}"
EXCLUDE_FROM="${HERE}/backups.${HOSTNAME}.exclude"

# State Variables.  This won't work if mount and unmount are called in different runs, we need a better mechanism (like actually checking the mount table)
MOUNTED="no"
function do_mount()
{
	if [ "${MOUNTED}" == "yes" ]; then
		return
	fi

	MOUNTED="yes"
}
function do_unmount()
{
	if [ "${MOUNTED}" == "no" ]; then
		return
	fi

	MOUNTED="no"
}
trap -n "mounting" do_unmount EXIT

_THIS_BACKUP=
function _get_this_backup()
{
	echo "${_THIS_BACKUP:-${BACKUP_DEST}/$(date '+%Y-%m/%d-%a/%H%M')}"
}

function _list_backups()
{
	find "${BACKUP_DEST}" -maxdepth 3 -mindepth 3
}

function _get_latest_backup()
{
	_list_backups | sort | tail -n1
}

function do_list()
{
	if [ "${MOUNTED}" == "no" ]; then
		do_mount
	fi

	_list_backups | sed -re 's!^'"${BACKUP_DEST}"'/!!' | sort
}

function do_backup()
{
	if [ "${MOUNTED}" == "no" ]; then
		do_mount
	fi

	mkdir --parents "$(_get_this_backup)"
	LATEST_BACKUP="$(_get_latest_backup)"

	if [ -z "${LATEST_BACKUP}" ]; then
		report_bad "No previous backup exists, creating new backup..."
		report_cmd rsync "${RSYNC_ARGS[@]}" --exclude-from="${EXCLUDE_FROM}" $(command cat ${FILES_FROM}) "$(_get_this_backup)" || true  # Expect some failures due to not being root...
	else
		report_good "Creating new backup based on latest: ${LATEST_BACKUP}"
		report_cmd rsync "${RSYNC_ARGS[@]}" --exclude-from="${EXCLUDE_FROM}" --link-dest="${LATEST_BACKUP}" $(command cat ${FILES_FROM}) "$(_get_this_backup)" || true  # Expect some failures due to not being root...
	fi
}

function _check_backup()
{
	BACKUP="$1"
	TYPE="$2"
	NUM2KEEP=$3
	INNER_KEY="$4"
	OUTER_KEY="$5"
	NEXT="$6"
	if [ -z "${OUTER_THIS}" ] || [ "${OUTER_THIS}" != "${OUTER_KEY}" ]; then
		OUTER_THIS="${OUTER_KEY}"
		if [ ${CNT} -ge ${NUM2KEEP} ]; then
			# Change of day/month/year, and we already have enough hourly/daily/monthly backups kept, change to keeping daily/monthly/yearly backups.
			CNT=0
			KEEPING="${NEXT}"
		else
			INNER_THIS="${INNER_KEY}"
			CNT=$((CNT + 1))
			report_good "Keeping ${TYPE} backup (${CNT} of ${NUM2KEEP}): ${BACKUP}"
		fi
	else
		if [ ${CNT} -ge ${NUM2KEEP} ]; then
			# We're in the same day/month/year as the last backup, but now we've seen at least ${NUM2KEEP} hourly/daily/monthly backups, so delete the rest of the hourly/daily/monthly backups.
			report_good "Removing ${TYPE} backup (${CNT} of ${NUM2KEEP}): ${BACKUP} (Sufficient ${TYPE} backups already kept)"
			report_cmd rm -rf "${BACKUP}"
		else
			if [ -z "${INNER_THIS}" ] || [ "${INNER_THIS}" != "${INNER_KEY}" ]; then
				INNER_THIS="${INNER_KEY}"
				CNT=$((CNT + 1))
				report_good "Keeping ${TYPE} backup (${CNT} of ${NUM2KEEP}): ${BACKUP}"
			else
				report_good "Removing ${TYPE} backup (${CNT} of ${NUM2KEEP}): ${BACKUP} (Already kept a ${TYPE} backup in this period)"
				report_cmd rm -rf "${BACKUP}"
			fi
		fi
	fi
}
function expire_backups()
{
	if [ "${MOUNTED}" == "no" ]; then
		do_mount
	fi

	CNT=0
	KEEPING="hours"
	INNER_THIS=
	OUTER_THIS=
	_list_backups | sort -r | while read -r BACKUP; do
		# Keep last 3 hours, last 5 days, last 2 months, last 1 year.
		if [ "${KEEPING}" == "hours" ]; then
			_check_backup "${BACKUP}" "hourly" 3 \
				"$(basename -- "${BACKUP}" | sed -nre 's/([0-9]{2})[0-9]{2}$/\1/p')" "$(dirname "${BACKUP}")" "days"
		fi
		if [ "${KEEPING}" == "days" ]; then
			_check_backup "${BACKUP}" "daily" 5 \
				"$(dirname "${BACKUP}")" "$(dirname "$(dirname "${BACKUP}")")" "months"
		fi
		if [ "${KEEPING}" == "months" ]; then
			_check_backup "${BACKUP}" "monthly" 6 \
				"$(dirname "$(dirname "${BACKUP}")")" "$(dirname "$(dirname "${BACKUP}")" | sed -nre 's/([0-9]{2})-[0-9]{2}$/\1/p')" "years"
		fi
		if [ "${KEEPING}" == "years" ]; then
			_check_backup "${BACKUP}" "yearly" 1 \
				"$(dirname "$(dirname "${BACKUP}")" | sed -nre 's/([0-9]{2})-[0-9]{2}$/\1/p')" "$(dirname "$(dirname "$(dirname "${BACKUP}")")")" ""
		fi
	done
}

# Stats and validate backups (hanging links and that sort of thing...)
function do_validate()
{
	if [ "${MOUNTED}" == "no" ]; then
		do_mount
	fi

	find -L "$(_get_this_backup)" -type l -exec ls -hdl --color=always "{}" \;
	find "$(_get_this_backup)" -type d | while read -r; do
		if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
			ls -d "$REPLY" 2>/dev/null
		fi
	done
}

function do_stats()
{
	if [ "${MOUNTED}" == "no" ]; then
		do_mount
	fi

	du -hscx $(_list_backups)
}

if [ $# -eq 0 ]; then
	## By default, do mount, backup, rotate, unmount
	do_mount
	do_backup
	expire_backups
	do_validate
	do_unmount
	do_stats
else
	# Do the requested actions.
	for i in "$@"; do
		case "$i" in
			mount )
				do_mount
				;;
			backup )
				do_backup
				;;
			expire )
				expire_backups
				;;
			validate )
				do_validate
				;;
			unmount )
				do_unmount
				;;
			stats )
				do_stats
				;;
			list | -l )
				do_list
				;;
			* )
				report_bad "Usage:"
				report_bad "  $(basename -- "$0") [mount] [backup] [expire] [validate] [unmount] [stats] [list]"
				exit 1
				;;
		esac
	done
fi
