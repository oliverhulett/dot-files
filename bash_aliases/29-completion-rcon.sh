function expand_rcon_job()
{
	RCON_CONF="/apps/centralConfig/rcon.conf"
	if [ -e "${RCON_CONF}" ]; then
		prefix="${COMP_WORDS[COMP_CWORD]}"
		if [ ${COMP_CWORD} == 1 ]; then
			rcon_jobs=`cut -d: -f2 "${RCON_CONF}" | command grep -v ^#`
			COMPREPLY=($(compgen -W "${rcon_jobs} all" -- $prefix ))
		else
			if [ ${COMP_CWORD} == 2 ]; then
				COMPREPLY=($(compgen -W "start stop restart status batchstart tail version blackout get set list get_affinity set_affinity" -- $prefix ))
			fi
		fi
	fi
}
complete -F expand_rcon_job rcon

function expand_swd_job()
{
	PROD_REPO="/home/`whoami`/StagingCentralizedRepo"
	if [ -e ${PROD_REPO} ]; then
		prefix="${COMP_WORDS[COMP_CWORD]}"
		colos=`command ls ${PROD_REPO} | command grep -v -E '(bin|conf|test)'`
		COMPREPLY=( $(compgen -W "${colos}" -- ${prefix}) )
	fi
}
complete -F expand_swd_job swd
