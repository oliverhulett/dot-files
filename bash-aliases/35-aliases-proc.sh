# shellcheck shell=bash
## Process management related aliases

function killprocs()
{
	PROCS="$(for i in "$@"; do pgrep -U `whoami` $i; done | xargs | sed -re 's/ /,/g')"
	if [ -n "${PROCS}" ]; then
		echo ps -fp "${PROCS}"
		ps -fp "${PROCS}"
		echo
		read -n1 -p "Kill listed processes? [y/N] "
		echo
		if [ "$(echo ${REPLY} | tr '[a-z]' '[A-Z]')" == "Y" ]; then
			echo killing $(echo ${PROCS} | sed -re 's/,/ /g')
			kill $(echo ${PROCS} | sed -re 's/,/ /g')
			for _ in `seq 1 4`; do
				echo
				if [ -z "$(ps --no-headers -fp "${PROCS}")" ]; then
					break
				fi
				ps -fp "${PROCS}"
				sleep 1
			done
		fi
	else
		echo "No processes found matching patterns: $*"
	fi
}
