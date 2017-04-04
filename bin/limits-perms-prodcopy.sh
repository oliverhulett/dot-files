#!/bin/bash -xe
#
#	Give me limits permissions on prodcopy.
#
HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

alterlimitsdb.sh --op=add_user --username=OPTIVER\\$(whoami) --role=RISK
alterlimitsdb.sh --op=list_users
