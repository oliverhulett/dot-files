#!/usr/bin/env bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

set -x

function print_help()
{
	echo "git mkbranch <NEW_BRANCH_NAME>"
	exit 1
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-?" ]; then
	print_help
fi

if [ $# -ne 1 ]; then
	print_help
fi

CURR_BRANCH="$(git this)"
#CURR_DIR="$(basename -- "$(pwd)")"
NEW_BRANCH="$1"
NEW_TICKET="$(git ticket "${NEW_BRANCH}")"
if [ -n "${NEW_TICKET}" ]; then
	NEW_DIR="$NEW_TICKET"
else
	NEW_DIR="$(basename -- "${NEW_BRANCH}")"
fi

## This script is designed to be called as a git alias, so we should be in the root of the checkout from which we want to branch.
if [ -e "../$NEW_DIR" ]; then
	echo "New branch directory already exists.  CD into it and run 'git checkout -b $NEW_BRANCH' like everyone else"
	print_help
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
if git rev-parse --quiet --verify "${NEW_BRANCH}" || git rev-parse --quiet --verify "origin/${NEW_BRANCH}"; then
	git worktree add "../${NEW_DIR}" "${NEW_BRANCH}"
else
	git worktree add "../${NEW_DIR}" -b "${NEW_BRANCH}"
fi
( cd "../${NEW_DIR}" && git update && setup_new_worktree )
