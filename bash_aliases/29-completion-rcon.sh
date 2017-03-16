expand_rcon_job () 
{ 
    unalias grep 2> /dev/null
    RCON_CONF="/apps/centralConfig/rcon.conf"
    if [ -e "${RCON_CONF}" ]; then
        prefix="${COMP_WORDS[COMP_CWORD]}"
        if [ ${COMP_CWORD} == 1 ]; then
            rcon_jobs=`cut -d: -f2 "${RCON_CONF}" | grep -v ^#`
            COMPREPLY=($(compgen -W "${rcon_jobs} all" -- $prefix ))
        else
            if [ ${COMP_CWORD} == 2 ]; then
                COMPREPLY=($(compgen -W "start stop restart status batchstart tail version blackout get set list get_affinity set_affinity" -- $prefix ))
            fi
        fi
    fi
}

complete -F expand_rcon_job rcon
