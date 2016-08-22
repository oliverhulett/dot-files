#!/bin/bash -xe
#
#	Wrapper for the alterlimitsdb python module.
#

if [ -z "$ALTERLIMITSDB_DIR" ]; then
	export ALTERLIMITSDB_DIR="${HOME}/limits_system/limits_server/alterlimitsdb"
fi
if [ -z "$DB_URI" ]; then
	export DB_URI='postgresql://operat@devenv002:6002/limitsdb_ml'
fi

cd "${ALTERLIMITSDB_DIR}" || exit 1
python26 -m Server.DataModel.alterlimitsdb --db="$DB_URI" "$@"

