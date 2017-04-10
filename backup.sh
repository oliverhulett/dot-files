#!/bin/bash
HOME="$(dirname "$(cd "$(dirname "$0")" && pwd -P)")"

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

${HOME}/dot-files/autocommit.sh

## Backup a small number of key system-wide configuration files.
rsync -zPAXrogthlm --delete --files-from=${HOME}/dot-files/backups.txt / ${HOME}/etc/backups
## Push local configuration and backups to another box.
rsync -zPAXrogthlm --delete --delete-excluded --exclude=opt/pyvenv ${HOME}/.ssh ${HOME}/etc ${HOME}/opt /H_DRIVE/
