#!/usr/bin/env bash
## Make a new branch, optionally in a new working directory.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "$(dirname "${HERE}")")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [-n|--new-worktree] [-p|--prefix=<PREFIX>] <TICKET> <DESCRIPTION>"
	echo "$(basename -- "$0") [-n|--new-worktree] <BRANCH_NAME>"
	echo "    Make a new branch, optionally in a new working directory."
	echo "    -n : Create the new branch in a new worktree as a sibling of this worktree."
	echo "    -p : Prefix to put infront of the branch name.  Defaults to your username."
}

OPTS=$(getopt -o "hnp::" --long "help,new-worktree,prefix::" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

eval set -- "${OPTS}"
NEW_WORKTREE="false"
PREFIX="$(git config user.username)"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help
			exit 0
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
	NEW_DIR="$(basename -- "$(dirname -- "$1")")"
	if [ -z "${NEW_DIR}" ]; then
		NEW_DIR="$(basename -- "$1")"
	fi
	NEW_BRANCH="${PREFIX}$1"
else
	NEW_DIR="$1"
	NEW_BRANCH="${PREFIX}$1/$(echo "${@:2}" | sed -re 's/ /-/g')"
fi

NEW_TICKET="$(git ticket "${NEW_BRANCH}")"
if [ -n "${NEW_TICKET}" ]; then
	NEW_DIR="$NEW_TICKET"
fi

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

echo "Creating branch ${NEW_BRANCH} from ${CURR_BRANCH} in ${NEW_DIR}"
sleep 1

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

git pullme --force
git fetch origin "${CURR_BRANCH}"
if [ "${NEW_WORKTREE}" == "true" ]; then
	if git rev-parse --quiet --verify "${NEW_BRANCH}" || git rev-parse --quiet --verify "origin/${NEW_BRANCH}"; then
		git worktree add "../${NEW_DIR}" "${NEW_BRANCH}"
	else
		git worktree add "../${NEW_DIR}" -b "${NEW_BRANCH}"
	fi
	( cd "../${NEW_DIR}" && git update && setup_new_worktree )
else
	if git rev-parse --quiet --verify "${NEW_BRANCH}" || git rev-parse --quiet --verify "origin/${NEW_BRANCH}"; then
		echo "Requested branch already exists.  Run 'git checkout ${NEW_BRANCH}' like everyone else"
		print_help
		exit 1
	else
		git checkout -b "${NEW_BRANCH}"
	fi
fi
