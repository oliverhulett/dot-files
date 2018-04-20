#!/bin/bash
## Backup local files to another local directory that'll be synced to the cloud.
## Version 1 will just use rsync to copy stuff as diffs/hard-link
## Version 2 will compress and/or encrypt the backup directory.  I have to work a few things out before I can do that.
## e.g. How does Google drive sync deal with the hard-links?  How does rsync deal with linking diffs on compressed and encrypted file systems.
## TODO:  Links, soft and hard...

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${HERE}/lib/script_utils.sh"

reentrance_check

export LC_ALL=C
RSYNC_ARGS=( -rpAXogthR --one-file-system --links --delete --delete-excluded --stats )
BACKUP_ARCHIVE="${HOME}/etc/backups.tar.gz"
BACKUP_DEST="${TMPDIR:-${TMP:-${HOME}/tmp}}/backups"
BACKUP_DEST="${HOME}/etc/backups"

# Get backup sources from files
HOSTNAME="$(hostname -s | tr '[:upper:]' '[:lower:]')"
FILES_FROM="${HERE}/backups.${HOSTNAME}"
EXCLUDE_FROM="${HERE}/backups.${HOSTNAME}.exclude"

function _archive_is_mounted()
{
	test -d "${BACKUP_DEST}" && test "$(stat -fc%t:%T "${BACKUP_DEST}")" != "$(stat -fc%t:%T "${BACKUP_DEST}/..")"
}
function do_unmount()
{
	if ! _archive_is_mounted; then
		return
	fi

	#report_cmd umount "${BACKUP_DEST}"
}
function do_mount()
{
	if _archive_is_mounted; then
		return
	fi

	#touch "${BACKUP_ARCHIVE}"
	mkdir --parents "${BACKUP_DEST}" 2>/dev/null
	#report_cmd archivemount -o nobackup "${BACKUP_ARCHIVE}" "${BACKUP_DEST}" || exit 1
	#trap -n "mounting" do_unmount EXIT
}

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
	if [ -d "$(_get_this_backup)" ]; then
		_list_backups | sort | tail -n2 | head -n1
	else
		_list_backups | sort | tail -n1
	fi
}

function do_list()
{
	do_mount

	_list_backups | sed -re 's!^'"${BACKUP_DEST}"'/!!' | sort
}

function do_backup()
{
	do_mount

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

function check_for_expired_backup()
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
	do_mount

	CNT=0
	KEEPING="hours"
	INNER_THIS=
	OUTER_THIS=
	_list_backups | sort -r | while read -r BACKUP; do
		# Keep last 3 hours, last 5 days, last 2 months, last 1 year.
		if [ "${KEEPING}" == "hours" ]; then
			check_for_expired_backup "${BACKUP}" "hourly" 3 \
				"$(basename -- "${BACKUP}" | sed -nre 's/([0-9]{2})[0-9]{2}$/\1/p')" "$(dirname "${BACKUP}")" "days"
		fi
		if [ "${KEEPING}" == "days" ]; then
			check_for_expired_backup "${BACKUP}" "daily" 5 \
				"$(dirname "${BACKUP}")" "$(dirname "$(dirname "${BACKUP}")")" "months"
		fi
		if [ "${KEEPING}" == "months" ]; then
			check_for_expired_backup "${BACKUP}" "monthly" 6 \
				"$(dirname "$(dirname "${BACKUP}")")" "$(dirname "$(dirname "${BACKUP}")" | sed -nre 's/([0-9]{2})-[0-9]{2}$/\1/p')" "years"
		fi
		if [ "${KEEPING}" == "years" ]; then
			check_for_expired_backup "${BACKUP}" "yearly" 1 \
				"$(dirname "$(dirname "${BACKUP}")" | sed -nre 's/([0-9]{2})-[0-9]{2}$/\1/p')" "$(dirname "$(dirname "$(dirname "${BACKUP}")")")" ""
		fi
	done
}

# Stats and validate backups (hanging links and that sort of thing...)
function do_validate()
{
	do_mount

	local _this_backup="$(_get_this_backup)"

	LINKS="$(find -L "${_this_backup}" -type l -exec ls -hdl --color=always "{}" \;)"
	if [ -n "${LINKS}" ]; then
		report_bad "Found hanging links..."
		echo "${LINKS}"
		echo
	fi
	DIRS="$(
		find "${_this_backup}" -type d | while read -r; do
			if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
				ls -d "$REPLY" 2>/dev/null
			fi
		done
	)"
	if [ -n "${DIRS}" ]; then
		report_bad "Found empty directories..."
		echo "${DIRS}"
		echo
	fi
}

function do_stats()
{
	do_mount

	report_cmd du -hscx $(_list_backups)
	report_cmd du -hscx "${BACKUP_ARCHIVE}"
}

if [ $# -eq 0 ]; then
	## By default, do mount, backup, rotate, unmount
	do_mount
	do_backup
	expire_backups
	do_validate
	do_stats
	do_unmount
else
	# Do the requested actions.
	for i in "$@"; do
		case "$i" in
			mount )
				do_mount
				trap -n "mounting" "" EXIT
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
			unmount | umount )
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
				report_bad "  $(basename -- "$0") [mount] [backup] [expire] [validate] [stats] [list] [unmount]"
				exit 1
				;;
		esac
	done
fi
