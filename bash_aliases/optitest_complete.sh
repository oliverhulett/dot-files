
expand_optitest_job () 
{ 
	unalias grep 2>/dev/null >/dev/null
	cmd="${COMP_WORDS[@]:0:$COMP_CWORD}"
	last="${COMP_WORDS[$(($COMP_CWORD - 1))]}"
	prefix="${COMP_WORDS[$COMP_CWORD]}"
	if [ "${last}" == "--junitdir" -o "${last}" == "--config" ]; then
		return	## Fall back to default
	elif [ "${last:0:1}" == "-" -a "${last: -1}" == "c" ]; then
		return ## Fall back to default
	else
		tests="$($cmd --list 2>/dev/null | grep -v "Will run" | sort)"
		COMPREPLY=($(compgen -W "$tests" -- "$prefix"))
		if [ ${#COMPREPLY[@]} -eq 0 ]; then
			COMPREPLY=($(compgen -W "$(echo "$tests" | grep "$prefix")"))
		fi
	fi
}

complete -o default -F expand_optitest_job optitest

