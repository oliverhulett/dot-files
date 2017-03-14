#!/bin/bash -xe
#
#	Give me limits permissions on prodcopy.
#
source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

alterlimitsdb.sh --op=add_user --username=OPTIVER\\$(whoami) --role=RISK
alterlimitsdb.sh --op=list_users
