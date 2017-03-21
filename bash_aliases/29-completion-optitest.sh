# Command line completion for optitest
expand_optitest_job ()
{
	source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	unalias grep 2>/dev/null >/dev/null
	cmd="${COMP_WORDS[@]:0:$COMP_CWORD}"
	last="${COMP_WORDS[$(($COMP_CWORD - 1))]}"
	if [ "${last}" == "--" ]; then
		cmd="${COMP_WORDS[@]:0:$COMP_CWORD - 1}"
	fi
	prefix="${COMP_WORDS[$COMP_CWORD]}"
	if [ "${last}" == "--junitdir" -o "${last}" == "--config" ]; then
		return	## Fall back to default
	elif [ "${last:0:1}" == "-" -a "${last: -1}" == "c" ]; then
		return ## Fall back to default
	elif [ "${prefix:0:1}" == "-" ]; then
		COMPREPLY=($(compgen -W "-h --help --junit --junitdir -l --list -v --verbose -c --config -j --jobs --version" -- "$prefix"))
	else
		tests="$($(echo $cmd | sed -e 's/ = /=/g') --list 2>&${log_fd} | sed -nre '/^Will run .+ tests.$/,$p' | sed '1d' | sort)"
		COMPREPLY=($(compgen -W "$tests" -- "$prefix"))
		if [ ${#COMPREPLY[@]} -eq 0 ]; then
			COMPREPLY=($(compgen -W "$(echo "$tests" | grep "$prefix" 2>&${log_fd})"))
		fi
	fi
}

complete -o default -F expand_optitest_job optitest
