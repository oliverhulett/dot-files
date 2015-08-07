
unalias sedrename 2>/dev/null
function sedrename
{
	dir=
	width=0
	declare -a args
	if [ $# -gt 1 ]; then
		dir=$1
		shift
	fi
	for i in ${dir:-.}/*; do
		f=$(echo -n $i | sed -re "$*")
		args[${#args[*]}]="$i"
		args[${#args[*]}]="$f"
		if [ "`echo -n $i | wc -c`" -gt "$width" ]; then
			width=$(echo -n $i | wc -c)
		fi
	done
	printf "'%-${width}s' => '%s'\n" "${args[@]}"

	read -p "Stand Back!  It's OK, I know Regular Expressions. [y|N]: " -n1
	case $REPLY in
		y*|Y*)
		;;
		*)
			return
		;;
	esac
	echo

	for i in ${dir:-.}/*; do
		f=$(echo -n $i | sed -re "$*")
		mkdir -p "$(dirname "$f")"
		mv -v "$i" "$f" 2>/dev/null
	done
}

