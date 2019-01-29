#!/bin/bash
## Print the path to a repository.

## One argumeent may be a repository name, a branch name or a project name
## Two arguments may be a project and a repository, or a repository and a branch name
## Three arguments must be a project, repository and branch

function echo_clean_path()
{
	echo "$*/" | sed -re 's!//+!/!g'
}

roots=( "repo" "src" )
function generate_options()
{
	#echo >&2 "Generating options from: $*"
	for r in "${roots[@]}"; do
		for d in "${HOME}"/${r}/$(printf "%s" "${@/#//}" | tr '[:upper:]' '[:lower:]'); do
			if [ -d "$d" ]; then
				echo_clean_path "$d"
			fi
		done
	done
}

if [ "$1" == "repo" ] || [ "$1" == "src" ]; then
	roots=( "$1" )
	shift
fi

if [ $# -eq 0 ]; then
	echo >&2 "$(basename -- "$0") [project] [repository] [branch]"
	echo >&2 "  Find checkout directory of a repository and branch."
	exit 1
elif [ $# -eq 1 ]; then
	# Try for repository name first...
	generate_options '*' "$1" "master" | xargs -rn1 dirname

	# Or a project only...
	generate_options "$1" '*' "master" | xargs -rn1 dirname

	# Maybe they gave us a branch name...
	generate_options '*' '*' "$1"
elif [ $# -eq 2 ]; then
	# Try for a project and a repository first...
	generate_options "$1" "$2" "master" | xargs -rn1 dirname

	# Try for a repository and a branch second...
	generate_options '*' "$1" "$2"
else
	# We have at least three args
	# Try for project, repo, branch first...
	generate_options "$@"

	# Try for a repo, branch, directory list second...
	generate_options '*' "$@"
fi
