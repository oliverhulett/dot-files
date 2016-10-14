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
	proj="$1"
	repo="$2"
	branch="${3:-master}"
	if [ ! -d "${HOME}/repo/${proj}" ]; then
		branch="${repo:-master}"
		repo="${proj}"
		proj='*'
	fi
	echo ${HOME}/repo/${proj}/${repo}/${branch}
}
