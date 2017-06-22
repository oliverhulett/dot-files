#!/bin/bash
HOME="$(dirname "$(cd "$(dirname "$0")" && pwd -P)")"

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

[ -e "${HOME}/.bash_aliases/49-setup-proxy.sh" ] && source "${HOME}/.bash_aliases/49-setup-proxy.sh" 2>/dev/null

## Crontabs live in /var/spool/, so take a backup of my crontab on a separate partition.
crontab -l >${HOME}/dot-files/crontab.$(hostname -s) && echo -e "\n## Backed up at `date` by `whoami`" >>${HOME}/dot-files/crontab.$(hostname -s)
## Save list of installed software.
( rpm -qa | sort; pip freeze | sort ) >${HOME}/dot-files/installed-software.txt
## Commit dot-files to git for extra backups.
( cd ${HOME}/dot-files && git commit --allow-empty -aqm "Autocommit: $(date -R)\n$(git status --short)" && git pullb && git push --quiet --all )
## Backup a small number of key system-wide configuration files.
rsync -zPAXrogthlm --delete --files-from=${HOME}/dot-files/backups.txt / ${HOME}/etc/backups
