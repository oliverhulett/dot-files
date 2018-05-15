# shellcheck shell=bash
# Aliases and function for finding top of project
unalias get-project-root 2>/dev/null
function get-project-root()
{
	if [ $# -eq 0 ]; then
		set -- .git "$(pwd)"
	elif [ $# -eq 1 ]; then
		if [ -d "$1" ]; then
			set -- .git "$1"
		else
			set -- "$1" "$(pwd)"
		fi
	fi
	marker="$1"
	dir="$2"
	__startdir="${__startdir:-$dir}"
	if [ "$dir" == "/" ]; then
		echo 1>&2 "At slash: $marker not found.  ${__startdir} is not a project."
		unset __startdir
		return
	fi
	if [ -d "$dir/$marker" ]; then
		echo "$dir"
		unset __startdir
		return
	fi
	get-project-root "$marker" "$(dirname "$dir")"
}

unalias repo 2>/dev/null
function repo()
{
	dir="$(get-repo-dir.sh "$@" | head -n1)"
	if [ -d "${dir}/master" ]; then
		dir="${dir}/master"
	fi
	echo "$dir"
	cd "$dir"
}
alias get-repo-dir=get-repo-dir.sh
alias repo-dir=get-repo-dir.sh

function _repo_completion()
{
	local cur
	cur=${COMP_WORDS[COMP_CWORD]}
	COMPREPLY=()
	if [ ${COMP_CWORD} -le 1 ]; then
		COMPREPLY=( $(compgen -W "$(printf "%s\n" ${HOME}/{repo,src}/* ${HOME}/{repo,src}/*/* | xargs -n1 basename)" -- ${cur}) )
	elif [ ${COMP_CWORD} -eq 2 ] && [ -d "${HOME}/repo/${COMP_WORDS[1]}" -o -d "${HOME}/src/${COMP_WORDS[1]}" ]; then
		COMPREPLY=( $(cd "${HOME}/repo/${COMP_WORDS[1]}" 2>/dev/null && compgen -o dirnames -- "${cur}") $(cd "${HOME}/src/${COMP_WORDS[1]}" 2>/dev/null && compgen -o dirnames -- "${cur}") )
	else
		IFS=$'\n'
		for i in $(get-repo-dir.sh "${COMP_WORDS[@]:1:$((COMP_CWORD - 1))}"); do
			COMPREPLY=( "${COMPREPLY[@]}" $(cd "$i" && compgen -o dirnames -- "${cur}") )
		done
		unset IFS
	fi
}
complete -F _repo_completion get-repo-dir.sh get-repo-dir repo-dir repo

unalias clone 2>/dev/null
function clone()
{
	LINE="$(clone.sh "$@" | tee /dev/tty 2>/dev/null | tail -1)"
	cd "${LINE}" 2>/dev/null
}
