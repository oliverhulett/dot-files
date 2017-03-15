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
	echo "$dir"
	cd "$dir"
}
unalias clone 2>/dev/null
function clone()
{
	clone.sh "$@"
	repo "${@##\~}"
}
alias get-repo-dir=get-repo-dir.sh
alias repo-dir=get-repo-dir.sh

function depo()
{
	REPO_DIR=
	if [ $# -ge 3 -a -z "$REPO_DIR" ]; then
		REPO_DIR="$(repo-dir "$1" "$2" "$3")"
		if [ -d "$REPO_DIR" ]; then
			shift 3
		else
			REPO_DIR=
		fi
	fi
	if [ $# -ge 2 -a -z "$REPO_DIR" ]; then
		REPO_DIR="$(repo-dir "$1" "$2")"
		if [ -d "$REPO_DIR" ]; then
			shift 2
		else
			REPO_DIR=
		fi
	fi
	if [ $# -ge 1 -a -z "$REPO_DIR" ]; then
		REPO_DIR="$(repo-dir "$1")"
		if [ -d "$REPO_DIR" ]; then
			shift
		else
			REPO_DIR=
		fi
	fi
	if [ -z "$REPO_DIR" ]; then
		REPO_DIR="$(get-project-root)"
	fi
	IMG_DIR="$(dirname "$REPO_DIR" | sed -re "s!${HOME}/!${HOME}/dot-files/images/!")"
	IMG_NAME="$(cd "$IMG_DIR" && make name)"
	if [ -z "$(docker images -q $IMG_NAME)" ]; then
		( cd "$IMG_DIR" && make build )
	fi
	if ! grep -qw "$REPO_DIR" <(pwd -P) 2>/dev/null; then
		echo "Changing directory: $REPO_DIR"
		cd "$REPO_DIR"
	fi
	echo "Running docker image: $IMG_NAME -- $@"
	docker-run.sh -v '/u01:/u01' $IMG_NAME "$@"
}
