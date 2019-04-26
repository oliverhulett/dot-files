# shellcheck shell=bash
## By default, I always find myself wanting to ignore certain directories when looking for things recursively (e.g. `find` or `ack`)
# shellcheck disable=SC2086,SC2046 - Double quote to prevent globbing and word splitting.

function _generate_dirs_to_skip()
{
	INCLUDE_GIT_IGNORED="yes"
	if [ "$1" == "-I" ]; then
		INCLUDE_GIT_IGNORED="no"
		shift
	fi
	if [ $# -eq 0 ]; then
		set -- "$(pwd)"
	fi
	declare -a DIRS=(
		".Private"
		".git"
		".svn"
		".venv"
		".virtualenv"
		"__pycache__"
		"build"
		"debug"
		"node_modules"
		"target"
		"venv"
	)
	if [ "${INCLUDE_GIT_IGNORED}" == "yes" ]; then
		for i in "$@"; do
			while read -r _ path _; do
				DIRS[${#DIRS[@]}]="${path}"
			done < <(cd "$i" 2>/dev/null && git submodule status 2>/dev/null)
			while read -r status path; do
				if [ "${status}" == "!!" ]; then
					DIRS[${#DIRS[@]}]="${path}"
				fi
			done < <(cd "$i" 2>/dev/null && git status --ignored --porcelain 2>/dev/null)
		done
	fi
	echo "${DIRS[@]}"
}

function ackme()
{
	dashi=
	if [ "$1" == "-I" ]; then
		dashi="-I"
		shift
	fi
	command ack --ignore-dir=$(joinby " --ignore-dir=" $(_generate_dirs_to_skip "$dashi")) "$@"
}

function grepme()
{
	dashi=
	if [ "$1" == "-I" ]; then
		dashi="-I"
		shift
	fi
	GREP_ARGS="$(per_os -w "" -- "--exclude-dir=$(joinby " --exclude-dir=" $(_generate_dirs_to_skip "$dashi")) --color=always")"
	command grep ${GREP_ARGS} -nT "$@"
}
function ngrepme()
{
	dashi=
	if [ "$1" == "-I" ]; then
		dashi="-I"
		shift
	fi
	GREP_ARGS_NC="$(per_os -w "" -- "--exclude-dir=$(joinby " --exclude-dir=" $(_generate_dirs_to_skip "$dashi")) --color=never")"
	command grep ${GREP_ARGS_NC} "$@"
}

function findme()
{
	## From the find(1) man page...
	# The ‘-H’, ‘-L’ and ‘-P’ options control the treatment of symbolic links.
	# Command-line arguments following these are taken to be names of files or directories to be examined,
	# up to the first argument that begins with ‘-’, ‘(’, ‘)’, ‘,’, or ‘!’.
	dashh=
	if [ "$1" == "-H" ]; then
		dashh="-H"
		shift
	fi
	dashl=
	if [ "$1" == "-L" ]; then
		dashl="-L"
		shift
	fi
	dashp=
	if [ "$1" == "-P" ]; then
		dashp="-P"
		shift
	fi
	dashi=
	if [ "$1" == "-I" ]; then
		dashi="-I"
		shift
	fi
	declare -a DIRS
	while [ $# -gt 0 ]; do
		if [ -z "$(echo "${1:0:1}" | tr -d '()!,-')" ]; then
			break
		else
			DIRS[${#DIRS[@]}]="$1"
			shift
		fi
	done
	if [ ${#DIRS[@]} -eq 0 ]; then
		DIRS[0]="./"
	fi
	if [ $# -eq 0 ]; then
		set -- -true
	fi
	command find $dashh $dashl $dashp "${DIRS[@]}" -nowarn -not \( -name $(joinby " -prune -or -name " $(_generate_dirs_to_skip "$dashi")) -prune \) \( "$@" \)
}

function treeme()
{
	dashi=
	if [ "$1" == "-I" ]; then
		dashi="-I"
		shift
	fi
	command tree -I $(joinby " -I " $(_generate_dirs_to_skip "$dashi" | tr ' ' '\n' | xargs -n1 basename --)) "$@" | less
}
