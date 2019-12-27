#!/usr/bin/env bash
## Clean git checkouts and ignored files.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/.bash-aliases/35-aliases-sort_unique.sh"
source "${HOME}/.bash-aliases/36-aliases-ignore_dirs.sh"

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "Clean the checkout of ignored files"
	echo "$(basename -- "$0") [-a|--all]"
	echo "    --all : Clean all the things"
}

OPTS=$(getopt -o "ha" --long "help,all" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

eval set -- "${OPTS}"
ALL="false"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		-a | --all )
			ALL="true"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

function cleanbuild()
{
	if [ -x ./jmake ]; then
		echo "Cleaning Jira."
		./jmake clean
	elif [ -x ./gradlew ]; then
		echo "Cleaning build."
		./gradlew clean
	elif [ -e ./pom.xml ]; then
		echo "Cleaning build."
		mvn clean
	fi
}

function cleanignored()
{
	echo "Saving known ignored files."
	tmp="$(mktemp -d)"
	NAMES=()
	local first="true"
	for i in \
		'*.iml' \
		'*.ipr' \
		'*.iws' \
		.classpath \
		.cproject \
		.idea \
		.project \
		.pydevproject \
		.settings \
	; do
		if [ "$first" == "true" ]; then
			first="false"
		else
			NAMES[${#NAMES[@]}]="-or"
		fi
		NAMES[${#NAMES[@]}]="-name"
		NAMES[${#NAMES[@]}]="$i"
	done
	findme -I ./ -xdev \( "${NAMES[@]}" \) -print0 | xargs -0 cp --parents -xPr --target-directory="${tmp}/" 2>/dev/null

	echo
	echo "Cleaning ignored files."
	git clean -f -X -d

	echo
	echo "Restoring known ignored files."
	rsync -zvPAXrogthlm "${tmp}/" ./ && rm -rf "${tmp}"
}

function cleanempty()
{
	echo "Removing broken symlinks and empty directories."
	findme -L ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type l -depth -delete -print
	findme ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read -r; do
		if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

function updatecheckout()
{
	echo "Updating repo and externals from upstream."
	stashes=$(git stash list | wc -l)
	git stash --include-untracked
	git pullme --force
	if [ "$stashes" -ne "$(git stash list | wc -l)" ]; then
		git stash pop "stash@{$stashes}"
	fi
}

if [ "${ALL}" == "true" ]; then
	cleanbuild
	git update --clean
fi

cleanignored
cleanempty

if [ "${ALL}" == "true" ]; then
	updatecheckout
fi

git status
