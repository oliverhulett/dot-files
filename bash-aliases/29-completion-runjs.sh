# shellcheck shell=bash

## Originally created by `run --complete` from https://github.com/pawelgalazka/runjs.  $ npm install -g runjs-cli
function _run_completion()
{
	local cur prev nb_colon
	_get_comp_words_by_ref -n : cur prev
	nb_colon=$(grep -o ":" <<< "$COMP_LINE" | wc -l)

	COMPREPLY=( $(compgen -W '$(run --compbash --compgen "$((COMP_CWORD - (nb_colon * 2)))" "$prev" "${COMP_LINE}")' -- "$cur") )

	__ltrim_colon_completions "$cur"
}
complete -F _run_completion run runjs runjs.sh
