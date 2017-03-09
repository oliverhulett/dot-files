#!/bin/bash
HOME="$(dirname "$(cd "$(dirname "$0")" && pwd -P)")"

source "${HOME}/dot-files/bash_common.sh"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup -q
fi

## Crontabs live in /var/spool/, so take a backup of this crontab on a separate partition.
crontab -l >${HOME}/dot-files/crontab.$(hostname -s) && echo -e "\n## Backed up at `date`" >>${HOME}/dot-files/crontab.$(hostname -s)
## Save list of installed software.
( rpm -qa; pip freeze ) | sort >${HOME}/dot-files/installed-software.txt
## Commit dot-files to git for extra backups.
( cd ${HOME}/dot-files && git commit --allow-empty -aqm "Autocommit: $(date -R)\n$(git status --short)" && git pullb && git push -q ) 2>&1 >>"$(setup_logs)"
## Backup a small number of key system-wide configuration files.
rsync -PAXrogthlm --files-from=${HOME}/dot-files/backups.txt / ${HOME}/etc/backups 2>&1 >>"$(setup_logs)"
## Push local configuration and backups to another box.
rsync -PAXrogthlm --delete ${HOME}/.ssh ${HOME}/etc ${HOME}/opt /H_DRIVE/ 2>&1 >>"$(setup_logs)"
