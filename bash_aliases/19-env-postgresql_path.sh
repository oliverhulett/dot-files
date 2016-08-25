##  Set LD_LIBRARY_PATH for the default PostgreSQL v9.2 installation.
##  If this is different for your system, set LD_LIBRARY_PATH yourself, we add, we don't clobber.
source "${HOME}/etc/dot-files/bash_common.sh"
PSQL_DIR="/usr/pgsql-9.2"
if [ -e ${PSQL_DIR} ]; then
	export PATH="$(append_path "${PSQL_DIR}/bin")"
	export LD_LIBRARY_PATH="$(echo "$LD_LIBRARY_PATH" | sed -re 's!(^|:)'"${PSQL_DIR}/lib"'/?(:|$)!\2!'):${PSQL_DIR}/lib"
fi

export DB_HOST=localhost
export DB_PORT=5432

