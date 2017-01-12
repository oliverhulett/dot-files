## Process management related aliases

function killprocs()
{
	PROCS="$(pgrep -d, -U `whoami` "$@")"
	if [ -n "${PROCS}" ]; then
		ps -fp "${PROCS}"
		echo
		read -n1 -p "Kill listed processes? [y/N] "
		echo
		if [ "$(echo ${REPLY} | tr '[a-z]' '[A-Z]')" == "Y" ]; then
			pkill -U `whoami` "$@"
			echo
			ps -fp "${PROCS}"
		fi
	else
		echo "None Found"
	fi
}

