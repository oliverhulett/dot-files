# shellcheck shell=bash

function _laas_bash_autocomplete()
{
	local cur opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	opts="$("${COMP_WORDS[0]}" --completion-bash "${COMP_WORDS[@]:1:$COMP_CWORD}")"
	read -r -a COMPREPLY <<< "$(compgen -W "${opts}" -- "${cur}")"
	return 0
}
complete -F _laas_bash_autocomplete laas
