# Aliases and function for finding top of project
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

