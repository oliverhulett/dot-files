#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

function print_help()
{
	echo "git mkbranch <NEW_BRANCH_NAME>"
	exit 1
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-?" ]; then
	print_help
fi

if [ $# -ne 0 ]; then
	print_help
else
	echo "Creating branch ${NEW_BRANCH} from ${CURR_BRANCH} in ${NEW_DIR}"
	sleep 1
fi

CURR_BRANCH="$(git this)"
CURR_DIR="$(basename -- "$(pwd)")"
NEW_BRANCH="$1"
NEW_TICKET="$(git ticket "${NEW_BRANCH}")"
NEW_DIR="$NEW_TICKET"

## This script is designed to be called as a git alias, so we should be in the root of the checkout from which we want to branch.
if [ -e "../$NEW_DIR" ]; then
	echo "New branch directory already exists.  CD into it and run 'git checkout -b $NEW_BRANCH' like everyone else"
	print_help
fi

function setup_new_worktree()
{
	shopt -s nullglob
	set -- ../.[a-z]*
	if [ "$#" -gt 0 ]; then
		ln -sv ../.[a-z]* ./ 2>/dev/null
	fi
	rm .project 2>/dev/null
	if [ -f ../.project ] || [ -f ../master/.project ]; then
		cp ../.project ./ 2>/dev/null || cp ../master/.project ./ 2>/dev/null
	fi
	if [ -f .project ]; then
		sed -re 's!@master</name>!@'"${NEW_TICKET}_${NEW_DESCR}"'</name>!' .project -i
	fi
}

git pullme --force
git fetch origin "${CURR_BRANCH}"
git worktree add "../${NEW_DIR}" -b "${NEW_BRANCH}"
( cd "../${NEW_DIR}" && git update && setup_new_worktree )
