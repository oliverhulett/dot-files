
unalias ff 2>/dev/null
function ff
{
	declare -a DIRS
	declare -a EXTS
	declare -a PATS
	for arg in "$@"; do
		if [ -d "$arg" ]; then
			DIRS[${#DIRS[@]}]="$arg"
		elif echo $arg | ngrep -qE '^\.[a-zA-Z0-9\*]{1,7}$' >/dev/null 2>&1; then
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
	if [ -z "$EXTS" ]; then
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

	echo "Looking for ${PATS[@]} in ${DIRS[@]} (-iname 'Makefile' -or -iname 'Jamfile' ${EXTS[@]})"
	find "${DIRS[@]}" -not \( -name '.git' -prune -or -name '.svn' -prune \) -type f -not -name '*~' \( -iname 'Makefile' -or -iname Jamfile "${EXTS[@]}" \) -print0 | xargs -0 grep -n --color=always -E "${PATS[@]}"
}

