#!/usr/bin/env bash
# Renaming things for fun and profit.

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-cfg] --copy] [--force] [--git] [-p|--pattern=]<PATTERN> <DIRS...>"
	echo "    -c --cp --copy:  Copy instead of move, works with --git to use git-copy"
	echo "    -f --force:      Use the --force flag with the move command"
	echo "    -g --git:        Use git-move, otherwise just use mv"
	echo "    -p --pattern:    The sed pattern to use.  If this flag is omitted the first argument is used as the sed pattern"
	echo "    <DIRS...>:       The directores in which to look for files to rename"
}

OPTS=$(getopt -o "hcfgp:" --long "help,cp,copy,force,git,pattern:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

CMD="mv"
FORCE=
GIT=
PATTERN=
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-c | --cp | --copy )
			CMD="cp"
			shift
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
		if [ "$i" != "$f" ]; then
			args[${#args[*]}]="$i"
			args[${#args[*]}]="$f"
			if [ "$(echo -n "$i" | wc -c)" -gt "$width" ]; then
				width=$(echo -n "$i" | wc -c)
			fi
		fi
	done
done
printf "'%-${width}s' => '%s'\n" "${args[@]}"

read -rp "Stand Back!  It's OK, I know Regular Expressions. [y|N]: " -n1
echo
case $REPLY in
	y*|Y*)
	;;
	*)
		exit 0
	;;
esac

for dir in "${dirs[@]}"; do
	for i in "${dir:-.}"/*; do
		f="${dir:-.}/$(basename -- "$i" | sed -re "$PATTERN")"
		mkdir -p "$(dirname "$f")"
		$GIT $CMD -v $FORCE "$i" "$f" 2>&${log_fd}
	done
done
