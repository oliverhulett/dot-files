#!/bin/bash
## Backup local files to another local directory that'll be synced to the cloud.
## Version 1 will just use rsync to copy stuff as diffs with https://github.com/laurent22/rsync-time-backup
## Version 2 will compress and/or encrypt the backup directory.  I have to work a few things out before I can do that.
## e.g. How does Google drive sync deal with the hard-links?  How does rsync deal with linking diffs on compressed and encrypted file systems.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${HERE}/lib/script_utils.sh"

reentrance_check

BACKUP_DEST="${HOME}/etc/backups"

# Get backup sources from files
HOSTNAME="$(hostname -s | tr '[:upper:]' '[:lower:]')"
FILES_FROM="${HERE}/backups.${HOSTNAME}"
EXCLUDE_FROM="${HERE}/backups.${HOSTNAME}.exclude"

RSYNC_ARGS=( -vrpAXogthR --links --delete --delete-excluded --stats )

# Do backup
export LC_ALL=C
THIS_BACKUP="${BACKUP_DEST}/$(date '+%Y-%m/%d-%a/%H%M')"
mkdir --parents "${THIS_BACKUP}"
LATEST_BACKUP="${BACKUP_DEST}/$(cd "${BACKUP_DEST}" && find . -maxdepth 3 -mindepth 3 | sort | tail -n1)"
# Get latest backup

if [ -z "${LATEST_BACKUP}" ]; then
	report_bad "No previous backup exists, creating new backup..."
	report_cmd rsync "${RSYNC_ARGS[@]}" --exclude-from="${EXCLUDE_FROM}" $(command cat ${FILES_FROM}) "${THIS_BACKUP}"
else
	report_good "Creating new backup based on latest: ${LATEST_BACKUP}"
	report_cmd rsync "${RSYNC_ARGS[@]}" --exclude-from="${EXCLUDE_FROM}" --link-dest="${LATEST_BACKUP}" $(command cat ${FILES_FROM}) "${THIS_BACKUP}"
fi

# Delete expired backups

# Stats and validate backups (hanging links and that sort of thing...)
