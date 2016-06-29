## Process management related aliases

function killtermprocs()
{
	ps | while read PID TTY TIME CMD; do
		if [ "${CMD}" == "CMD" ]; then
			continue
		elif [ "${CMD}" == "bash" ]; then
			continue
		elif [ "${CMD}" == "ps" ]; then
			continue
		else
			kill "$@" ${PID}
		fi
	done
}

