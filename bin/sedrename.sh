#!/bin/bash
# Renaming things for fun and profit.

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-fg] [--force] [--git] [-p|--pattern=]<PATTERN> <DIRS...>"
	echo "    -g --git:      Use git-move, otherwise just use mv"
	echo "    -f --force:    Use the --force flag with the move command"
	echo "    -p --pattern:  The sed pattern to use.  If this flag is omitted the first argument is used as the sed pattern"
	echo "    <DIRS...>:     The directores in which to look for files to rename"
}

OPTS=$(getopt -o "fhgp:" --long "force,help,git,pattern:" -n "$(basename -- "$0")" -- "$@")
if [ $? != 0 ]; then
	print_help
	exit $?
fi

GIT=
FORCE=
PATTERN=
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-f | --force )
			FORCE="-f"
			shift
			;;
		-g | --git )
			GIT="git"
			shift
			;;
		-p | --pattern )
			PATTERN="$2"
			shift 2
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done
if [ -z "$PATTERN" ]; then
	PATTERN="$1"
	shift
fi

declare -a args dirs
dirs=( "$@" )
if [ $# -eq 0 ]; then
	dirs=( . )
fi
width=0
for dir in "${dirs[@]}"; do
	for i in "${dir:-.}"/*; do
		f="${dir:-.}/$(basename -- "$i" | sed -re "$PATTERN")"
		args[${#args[*]}]="$i"
		args[${#args[*]}]="$f"
		if [ "`echo -n $i | wc -c`" -gt "$width" ]; then
			width=$(echo -n $i | wc -c)
		fi
	done
done
printf "'%-${width}s' => '%s'\n" "${args[@]}"

read -p "Stand Back!  It's OK, I know Regular Expressions. [y|N]: " -n1
case $REPLY in
	y*|Y*)
	;;
	*)
		exit 0
	;;
esac
echo

for dir in "${dirs[@]}"; do
	for i in "${dir:-.}"/*; do
		f="${dir:-.}/$(basename -- "$i" | sed -re "$PATTERN")"
		mkdir -p "$(dirname "$f")"
		$GIT mv -v $FORCE "$i" "$f" 2>&${log_fd}
	done
done
