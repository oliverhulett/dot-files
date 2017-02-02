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
unalias clone 2>/dev/null
function clone()
{
	clone.sh "$@"
	repo "${@##\~}"
}
unalias get-repo-dir 2>/dev/null
function get-repo-dir()
{
	set -- $(echo "$@" | tr '/' ' ')
	if [ $# -lt 1 ]; then
		return
	fi
	if [ -d "${HOME}/repo/$1" ]; then
		proj="$1"
		repo="$2"
		shift 2
	else
		proj='*'
		repo="$1"
		shift
	fi
	branch="${1:-master}"
	shift
	echo ${HOME}/repo/${proj}/${repo}/${branch}/"$(echo $* | tr ' ' '/')"
}
alias repo-dir=get-repo-dir

function _compgen_repo_dirs()
{
	compgen -d -X '.*' "$@" | command grep -v RemoteSystemsTempFiles
}

function _repo_completions()
{
	COMPREPLY=($(cd "${HOME}/repo/$1" 2>/dev/null && _compgen_repo_dirs -- "${COMP_WORDS[$COMP_CWORD]}"))
	if [ -z "$1" ]; then
		for d in ${HOME}/repo/*; do
			COMPREPLY=("${COMPREPLY[@]}" $(cd "$d" && _compgen_repo_dirs -- "${COMP_WORDS[$COMP_CWORD]}"))
		done
	fi
}

function _complete_repo_dirs()
{
	if [ $COMP_CWORD -eq 1 ]; then
		_repo_completions
		return
	elif [ $COMP_CWORD -eq 2 ]; then
		if [ -d "${HOME}/repo/${COMP_WORDS[1]}" ]; then
			_repo_completions "${COMP_WORDS[1]}"
			return
		fi
	fi
	dirpart="$(echo "${COMP_WORDS[@]:1:$(($COMP_CWORD - 1))}" | tr ' ' '/')"
	if [ ! -d "${HOME}/repo/${dirpart}" ]; then
		new_dirpart="$(cd "${HOME}/repo" && echo */${dirpart})"
		if [ -d "${HOME}/repo/${new_dirpart}" ]; then
			dirpart="${new_dirpart}"
		fi
	fi
	COMPREPLY=($(cd "${HOME}/repo/${dirpart}/" 2>/dev/null && _compgen_repo_dirs -- "${COMP_WORDS[$COMP_CWORD]}"))
}
complete -F _complete_repo_dirs repo repo-dir get-repo-dir

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

function _complete_depo()
{
	if [ $COMP_CWORD -eq 1 ]; then
		_repo_completions
		return
	elif [ $COMP_CWORD -eq 2 ]; then
		REPO_DIR="$(repo-dir "${COMP_WORDS[1]}")"
		if [ ! -d "${REPO_DIR}" ]; then
			_repo_completions "${COMP_WORDS[1]}"
			return
		else
			_command_offset 2
			return
		fi
	else
		_command_offset 3
	fi
}
complete -F _complete_depo depo
