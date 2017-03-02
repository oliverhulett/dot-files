#!/bin/bash

## Crontabs live in /var/spool/, so take a backup of this crontab on a separate partition.
crontab -l >${HOME}/dot-files/crontab.$(hostname -s) && echo -e "\n## Backed up at `date`" >>${HOME}/dot-files/crontab.$(hostname -s)
## Save list of installed software.
rpm -qa | sort >${HOME}/dot-files/installed-software.txt
## Commit dot-files to git for extra backups.
cd ${HOME}/dot-files && git commit --allow-empty -aqm "Autocommit: $(date -R)\n$(git status --short)" && git pullb && git push -q >/dev/null 2>/dev/null && ${HOME}/dot-files/bin/dock.sh --bootstrap-docker-force-push >/dev/null
## Backup a small number of key system-wide configuration files.
rsync -PAXrogthlm --files-from=${HOME}/dot-files/backups.txt / ${HOME}/etc/backups >/dev/null
## Push local configuration and backups to another box.
rsync -PAXrogthlm --delete ${HOME}/.ssh ${HOME}/etc ${HOME}/opt /H_DRIVE/ >/dev/null
