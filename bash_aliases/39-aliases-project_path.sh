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
	dir="$(get-repo-dir "$@")"
	echo "$dir"
	cd "$dir"
}
unalias get-repo-dir 2>/dev/null
function get-repo-dir()
{
	set -- $(echo "$@" | tr '/' ' ')
	proj="$1"
	shift
	repo="$1"
	shift
	branch="${1:-master}"
	shift
	if [ ! -d "${HOME}/repo/${proj}" ]; then
		branch="${repo:-master}"
		repo="${proj}"
		proj='*'
	fi
	echo ${HOME}/repo/${proj}/${repo}/${branch}/"$(echo $* | tr ' ' '/')"
}
alias repo-dir=get-repo-dir

function complete_repo()
{
	compgen_cmd="compgen -d -X '.*' -X 'RemoteSystemsTempFiles'"
	if [ $COMP_CWORD -gt 3 ]; then
		compgen_cmd="$compgen_cmd -S '/'"
	fi
	dir_part="$(echo ${COMP_WORDS[@]:1:$((COMP_CWORD - 1))} | tr ' ' '/')"
	if [ ! -d "${HOME}/repo/${dir_part}" ]; then
		new_dir_part="$(cd "${HOME}/repo" && echo */${dir_part})"
		if [ -d "${HOME}/repo/${new_dir_part}" ]; then
			dir_part="${new_dir_part}"
		fi
	fi
	COMPREPLY=($(cd "${HOME}/repo/${dir_part}/" && $compgen_cmd -- "${COMP_WORDS[$COMP_CWORD]}"))
	if [ $COMP_CWORD == 1 ]; then
		# Special case, first word can be project or repo
		for d in ${HOME}/repo/*; do
			COMPREPLY=("${COMPREPLY[@]}" $(cd "$d" && $compgen_cmd -- "${COMP_WORDS[$COMP_CWORD]}"))
		done
	fi
}
complete -F complete_repo repo repo-dir get-repo-dir

