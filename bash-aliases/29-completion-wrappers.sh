# shellcheck shell=bash
# Set up command completion for commands that wrap other commands...

function _wrapped_completion()
{
	if [ ${COMP_CWORD} -le 1 ]; then
		_command
	else
		fn="$(complete -p "${COMP_WORDS[1]}" | sed -nre 's/.+-F ([^ ]+).+/\1/p')"
		if [ -n "$fn" ]; then
			COMP_WORDS=( "${COMP_WORDS[@]:1}" )
			COMP_CWORD=$((COMP_CWORD - 1))
			"$fn"
		fi
	fi
}

complete -F _wrapped_completion chronic chronic.sh
complete -F _wrapped_completion step step.sh
complete -F _wrapped_completion tt tt.sh
