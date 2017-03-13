# User specific environment and startup programs

function get_all_applications ( )
{
	local processes prefix
	prefix="${COMP_WORDS[COMP_CWORD]}"
	processes=( $($HOME/dot-files/bin/optic_application_expander.py) )
	COMPREPLY=( $(compgen -W "${processes[*]}" -- $prefix ) )
}

complete -F get_all_applications xless.sh xless
