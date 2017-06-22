SWD_REPO="${HOME}/StagingCentralizedRepo"
function expand_rcon_job()
{
	if [ -e "${SWD_REPO}" ]; then
		prefix="${COMP_WORDS[COMP_CWORD]}"
		if [ ${COMP_CWORD} == 1 ]; then
			shopt -s nullglob
			for RCON_CONF in "${SWD_REPO}"/*/rcon.conf; do
				rcon_jobs="${rcon_jobs} $(command grep -vE '^\s*(#|$)' "${RCON_CONF}" | cut -d: -f2 | xargs)"
			done
			COMPREPLY=( $(compgen -W "${rcon_jobs} all" -- $prefix) )
		else
			if [ ${COMP_CWORD} == 2 ]; then
				COMPREPLY=( $(compgen -W "start stop restart status batchstart tail version blackout get set list get_affinity set_affinity" -- $prefix) )
			fi
		fi
	fi
}
complete -F expand_rcon_job rcon

function expand_swd_job()
{
	if [ -e ${SWD_REPO} ]; then
		prefix="${COMP_WORDS[COMP_CWORD]}"
		colos="$(command ls ${SWD_REPO} | command grep -v -E '(bin|conf|test)' | xargs)"
		COMPREPLY=( $(compgen -W "${colos}" -- ${prefix}) )
	fi
}
complete -F expand_swd_job swd
