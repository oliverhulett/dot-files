# shellcheck shell=bash
unalias safefind 2>/dev/null
function safefind
{
	## From the find(1) man page...
	# The ‘-H’, ‘-L’ and ‘-P’ options control the treatment of symbolic links.  Command-line arguments following these are taken to be names of files or directo-
	# ries to be examined, up to the first argument that begins with ‘-’, ‘(’, ‘)’, ‘,’, or ‘!’.
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
	find $dashh $dashl $dashp "${DIRS[@]}" -nowarn -not \( -name '.git' -prune -or -name '.svn' -prune -or -name '.venv' -prune -or -name '.virtualenv' -prune -or -name 'node_modules' \) \( "$@" \)
}

unalias findin 2>/dev/null
function findin
{
	declare -a DIRS
	declare -a EXTS
	declare -a PATS
	for arg in "$@"; do
		if [ -d "$arg" ]; then
			DIRS[${#DIRS[@]}]="$arg"
		elif echo "$arg" | ngrep -qE '^\.[a-zA-Z0-9\*]{1,7}$' >/dev/null 2>&1; then
			EXTS[${#EXTS[@]}]="-or"
			EXTS[${#EXTS[@]}]="-iname"
			EXTS[${#EXTS[@]}]="*$arg"
		else
			PATS[${#PATS[@]}]="-e"
			PATS[${#PATS[@]}]="$arg"
		fi
	done
	if [ ${#DIRS[@]} -eq 0 ]; then
		DIRS[0]="./"
	fi
	if [ ${#PATS[@]} -eq 0 ]; then
		for arg in "$@"; do
			if [ ! -d "$arg" ]; then
				PATS[${#PATS[@]}]="-e"
				PATS[${#PATS[@]}]="$arg"
			fi
		done
		declare -a EXTS
	fi
	if [ -z "${EXTS[*]}" ]; then
		EXTS[${#EXTS[@]}]="-or"
		EXTS[${#EXTS[@]}]="-iname"
		EXTS[${#EXTS[@]}]='*.mak'
		EXTS[${#EXTS[@]}]="-or"
		EXTS[${#EXTS[@]}]="-iname"
		EXTS[${#EXTS[@]}]='*.*c*'
		EXTS[${#EXTS[@]}]="-or"
		EXTS[${#EXTS[@]}]="-iname"
		EXTS[${#EXTS[@]}]='*.h*'
	fi

	echo "Looking for ${PATS[*]} in ${DIRS[*]} (-iname 'Makefile' -or -iname 'Jamfile' ${EXTS[*]})"
	safefind "${DIRS[@]}" -type f -not -name '*~' \( -iname 'Makefile' -or -iname Jamfile "${EXTS[@]}" \) -print0 | xargs -0 grep -n --color=always -E "${PATS[@]}"
}
