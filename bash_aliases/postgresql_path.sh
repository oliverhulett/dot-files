##  Set LD_LIBRARY_PATH for the default PostgreSQL v9.2 installation.
##  If this is different for your system, set LD_LIBRARY_PATH yourself, we add, we don't clobber.
export PATH="$(echo "$PATH" | sed -re 's!(^|:)/usr/pgsql-9.2/bin/?(:|$)!\2!'):/usr/pgsql-9.2/bin"
export LD_LIBRARY_PATH="$(echo "$LD_LIBRARY_PATH" | sed -re 's!(^|:)/usr/pgsql-9.2/lib/?(:|$)!\2!'):/usr/pgsql-9.2/lib"
