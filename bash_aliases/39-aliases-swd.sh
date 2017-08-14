# SWD (and other SVN) helpers
function swd()
{
	OPTS=$(getopt -o "hdl:m:j:va" --long "version,help,config:,dry-run,update,level:,logfile:,message:,concurrency:,verbose,all" -n "$(basename -- "$0")" -- "$@")
	local es=$?
	if [ $es != 0 ]; then
		command swd -h
		exit $es
	fi

	eval set -- "${OPTS}"
	local ALL="no"
	local ARGS=()

	while true; do
		case "$1" in
			-a | --all )
				ALL="yes"
				ARGS[${#ARGS[@]}]="$1"
				shift
				;;
			-- )
				shift
				break
				;;
			* )
				ARGS[${#ARGS[@]}]="$1"
				shift
				;;
		esac
	done

	local root here
	here="$(pwd -P)"
	while [ "${here}" != "/" ]; do
		if [ -d "${here}/.svn" ]; then
			root="${here}"
		fi
		here="$(dirname "${here}")"
	done

	if [ "$ALL" == "yes" ]; then
		if [ -n "${root}" ]; then
			set -- "$@" $(find "${root}" -maxdepth 1 -type d -not -name '.*' | xargs -n1 basename --)
		fi
	fi

	for a in "$@"; do
		if [ -x "${root}/$a/common_scripts/management/flatten_xml.sh" ]; then
			"${root}/$a/common_scripts/management/flatten_xml.sh"
		fi
	done
	command swd "$@"
}
