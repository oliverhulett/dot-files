# Completions for function and aliases found in bash_aliases/39-aliases-project_path.sh
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
	dirpart="$(echo "${COMP_WORDS[@]:1:$((COMP_CWORD - 1))}" | tr ' ' '/')"
	if [ ! -d "${HOME}/repo/${dirpart}" ]; then
		new_dirpart="$(cd "${HOME}/repo" && echo ./*/${dirpart})"
		if [ -d "${HOME}/repo/${new_dirpart}" ]; then
			dirpart="${new_dirpart}"
		fi
	fi
	COMPREPLY=($(cd "${HOME}/repo/${dirpart}/" 2>/dev/null && _compgen_repo_dirs -- "${COMP_WORDS[$COMP_CWORD]}"))
}
complete -F _complete_repo_dirs repo repo-dir get-repo-dir get-repo-dir.sh

function _complete_stash()
{
	local prefix
	declare -a words
	prefix="${COMP_WORDS[COMP_CWORD]}"
	if [ $COMP_CWORD -eq 1 ]; then
		words=( $(stasher.py -q) )
	elif [ $COMP_CWORD -eq 2 ]; then
		words=( $(stasher.py -q "${COMP_WORDS[1]^^}" | cut -d' ' -f2-) )
	fi
	COMPREPLY=( $(compgen -W "${words[*],,}" -- $prefix ) )
}
complete -F _complete_stash clone clone.sh stasher.py

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
