#!/bin/bash -xe
#
#	Give me limits permissions on prodcopy.
#
alterlimitsdb.sh --op=add_user --username=OPTIVER\\$(whoami) --role=RISK
alterlimitsdb.sh --op=list_users
