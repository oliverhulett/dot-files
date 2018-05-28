#!/bin/bash
# Tee Totaler.
# Designed to be prefixed to an executable, it will fork the output and save it to a file next to the executable or in the current directory if the executable is on the path.

if [ "${1:0:1}" == "-" ]; then
	echo "tt.sh does not take any arguments"
	exit 1
fi

_LOGFILE="$1.log"
function _tee_totaler()
{
	KEYS=
	for k in "$@"; do
		KEYS="${KEYS} "'['"$k"']'
	done
	tee -i >(awk --assign T="%Y-%m-%d %H:%M:%S${KEYS} " '{ print strftime(T) $0 ; fflush(stdout) }' >>"${_LOGFILE}")
}
## Calling exec without a program to execute (like this) will redirect stdout (next line) and stderr (line after) for this process and any sub-processes.
## In this case, we're redirecting to the input of a sub-shell, that is running the `tee` command.  The `tee` command will write its input to stdout (so
## we continue to see output on the console as we would expect,) and the given file.  In this case, the "given file" is another sub-shell that writes each
## line to ${_LOGFILE}, prefixed by the time the line was written and the stream it was written by (stdout or stderr).
echo "$(date '+%Y-%m-%d %H:%M:%S') \$ $*" >"${_LOGFILE}"
exec > >(_tee_totaler STDOUT 2>/dev/null)
exec 2> >(_tee_totaler STDERR >&2)
"$@"
