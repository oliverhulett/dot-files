# shellcheck shell=bash

## Originally created by `run --complete` from https://github.com/pawelgalazka/runjs.  $ npm install -g runjs-cli
function _run_completion()
{
	local cur prev nb_colon
	_get_comp_words_by_ref -n : cur prev
	nb_colon=$(grep -o ":" <<< "$COMP_LINE" | wc -l)

	RUN_CMD="run"
	if [ -x "./node_modules/.bin/run" ]; then
		RUN_CMD="./node_modules/.bin/run"
	fi
	COMPREPLY=( $(compgen -W '$(${RUN_CMD} --compbash --compgen "$((COMP_CWORD - (nb_colon * 2)))" "$prev" "${COMP_LINE}")' -- "$cur") )

	__ltrim_colon_completions "$cur"
}
complete -F _run_completion run runjs runjs.sh
