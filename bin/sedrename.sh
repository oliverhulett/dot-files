#!/bin/bash
# Renaming things for fun and profit.

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

pat=
width=0
declare -a args dirs
pat=$1
shift
dirs=( "$@" )
if [ $# -eq 0 ]; then
	dirs=( . )
fi
for dir in "${dirs[@]}"; do
	for i in "${dir:-.}"/*; do
		f="${dir:-.}/$(basename "$i" | sed -re "$pat")"
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
		f="${dir:-.}/$(basename "$i" | sed -re "$pat")"
		mkdir -p "$(dirname "$f")"
		mv -v "$i" "$f" 2>/dev/null
	done
done

