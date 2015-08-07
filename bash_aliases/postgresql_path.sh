##  Set LD_LIBRARY_PATH for the default PostgreSQL v9.2 installation.
##  If this is different for your system, set LD_LIBRARY_PATH yourself, we add, we don't clobber.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/pgsql-9.2/lib/"
export PATH="$(echo "$PATH" | sed -re 's!:?/usr/pgsql-9.2/bin/?!!'):/usr/pgsql-9.2/bin"

