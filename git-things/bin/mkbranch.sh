#!/usr/bin/env bash
## Make a new branch, optionally in a new working directory.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-d|--dry-run] [-n|--new-worktree] [-p|--prefix=<PREFIX>] <TICKET> <DESCRIPTION>"
	echo "$(basename -- "$0") [-d|--dry-run] [-n|--new-worktree] [-p|--prefix=<PREFIX>] <BRANCH_NAME>"
	echo "    Make a new branch, optionally in a new working directory."
	echo "    -d : Dry run.  Don't actually create the branch, just print what you would do."
	echo "    -n : Create the new branch in a new worktree as a sibling of this worktree."
	echo "    -p : Prefix to put infront of the branch name.  Defaults to your username."
}

OPTS=$(getopt -o "hdnp:" --long "help,dry-run,new-worktree,prefix:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

eval set -- "${OPTS}"
DRY_RUN="false"
NEW_WORKTREE="false"
## Set prefix in reverse order of priority (so later ones override earlier ones, ending with the command line argument in case the user wants to not have a prefix)
PREFIX="$(git config user.username)"
if [ -n "$(git config branch.prefix)" ]; then
	PREFIX="$(git config branch.prefix)"
fi
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help
			exit 0
			;;
		-d | --dry-run )
			DRY_RUN="true"
			shift
			;;
		-n | --new-worktree )
			NEW_WORKTREE="true"
			shift
			;;
		-p | --prefix )
			shift
			PREFIX="$1"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done
if [ -n "${PREFIX}" ]; then
	PREFIX="${PREFIX%%/}/"
fi

CURR_BRANCH="$(git this)"
CURR_DIR="$(basename -- "$(pwd)")"
if [ $# -lt 1 ]; then
	print_help
	exit 1
elif [ $# -eq 1 ]; then
	## One argument given, assume it is the branch name (possibly without the prefix)
	NEW_BRANCH="${PREFIX}${1#${PREFIX}}"
else
	NEW_BRANCH="${PREFIX}${1#${PREFIX}}/$(echo "${@:2}" | sed -re 's![^A-Za-z0-9_.-]+!-!g')"
fi

NEW_TICKET="$(git ticket "${NEW_BRANCH}")"
NEW_BRANCH="${NEW_BRANCH/${NEW_TICKET}/${NEW_TICKET^^}}"
NEW_TICKET="${NEW_TICKET^^}"
if [ -n "${NEW_TICKET}" ]; then
	NEW_DIR="$NEW_TICKET"
else
	NEW_DIR="$(basename -- "$(dirname -- "${NEW_BRANCH}")")"
	if [ -z "${NEW_DIR}" ]; then
		NEW_DIR="$(basename -- "${NEW_BRANCH}")"
	fi
fi
NEW_DIR="$(echo "${NEW_DIR}" | sed -re 's/[^A-Za-z0-9_.-]+//g')"

if [ "${NEW_WORKTREE}" == "true" ]; then
	## This script is designed to be called as a git alias, so we should be in the root of the checkout from which we want to branch.
	if [ -e "../$NEW_DIR" ]; then
		echo "New branch directory already exists.  CD into it and run 'git checkout -b $NEW_BRANCH' like everyone else"
		print_help
		exit 1
	fi
else
	NEW_DIR="${CURR_DIR}"
fi

NOT=
if [ "${DRY_RUN}" == "true" ]; then
	NOT="(Not) "
fi
if [ -n "${NEW_TICKET}" ]; then
	echo "${NOT}Creating branch ${NEW_BRANCH} from ${CURR_BRANCH} in ${NEW_DIR} for ${NEW_TICKET}"
else
	echo "${NOT}Creating branch ${NEW_BRANCH} from ${CURR_BRANCH} in ${NEW_DIR}"
fi
sleep 1

function run()
{
	if [ "${DRY_RUN}" == "true" ]; then
		echo "> $*"
	else
		"$@"
	fi
}

function setup_new_worktree()
{
	shopt -s nullglob
	set -- ../.[a-z]*
	if [ "$#" -gt 0 ]; then
		ln -sv ../.[a-z]* ./ 2>/dev/null
	fi
	rm .project .name 2>/dev/null
	if [ -f ../.project ] || [ -f ../master/.project ]; then
		cp ../.project ./ 2>/dev/null || cp ../master/.project ./ 2>/dev/null
	fi
	if [ -f .project ]; then
		sed -re 's!@master</name>!@'"${NEW_TICKET}_${NEW_DESCR}"'</name>!' .project -i
	fi
	if [ -f ../.name ] || [ -f ../master/.name ]; then
		cp ../.name ./ 2>/dev/null || cp ../master/.name ./ 2>/dev/null
	fi
	if [ -f .name ] && [ -d .idea ]; then
		echo "${NEW_TICKET}_${NEW_DESCR}" >.name
		ln -s ../.name .idea/.name
	fi
}

run git pullme --force
run git fetch origin "${CURR_BRANCH}"
if [ "${NEW_WORKTREE}" == "true" ]; then
	if git rev-parse --quiet --verify "${NEW_BRANCH}" || git rev-parse --quiet --verify "origin/${NEW_BRANCH}"; then
		run git worktree add "../${NEW_DIR}" "${NEW_BRANCH}"
	else
		run git worktree add "../${NEW_DIR}" -b "${NEW_BRANCH}"
	fi
	( run cd "../${NEW_DIR}" && run git update && run setup_new_worktree && run git pushme )
else
	if git rev-parse --quiet --verify "${NEW_BRANCH}" || git rev-parse --quiet --verify "origin/${NEW_BRANCH}"; then
		echo "Requested branch already exists.  Run 'git checkout ${NEW_BRANCH}' like everyone else"
		print_help
		exit 1
	else
		run git checkout -b "${NEW_BRANCH}"
		run git pushme
	fi
fi
