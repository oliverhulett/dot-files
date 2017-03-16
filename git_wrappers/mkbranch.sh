#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

CURR_BRANCH="$(git branch --no-color | sed -nre 's/^\* //p')"
CURR_DIR="$(basename "$(pwd)")"

function print_help()
{
	echo "git mkbranch <NEW_TICKET> [<NEW_DESCR>]"
	exit 1
}

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "-?" ]; then
	print_help
fi

NEW_TICKET="$(echo $1 | cut -d_ -f1)"
if [ "$NEW_TICKET" != "$1" ]; then
	NEW_DESCR="$(echo $1 | cut -d_ -f2-)"
else
	NEW_DESCR="$2"
	shift
fi
shift

NEW_BRANCH="$USER/$NEW_TICKET"
if [ -n "$NEW_DESCR" ]; then
	NEW_BRANCH="${NEW_BRANCH}_${NEW_DESCR}"
fi

## MASTER_DIR should be a sibling of each branch's directory, and called master.
MASTER_DIR="$(dirname "$(pwd)")/master"
if [ ! -d "$MASTER_DIR" ]; then
	## Or MASTER_DIR should be a sibling of each branch's directory, and with the same name as the repository.
	parent="$(dirname "$(pwd)")"
	MASTER_DIR="$(dirname "${parent}")/$(git remote show origin | grep 'Fetch URL:' | sed 's#^.*/\(.*\).git#\1#')"
fi
if [ ! -d "$MASTER_DIR" ]; then
	## Or MASTER_DIR should be a sibling of each branch's directory, and with the same name as the parent directory.
	parent="$(dirname "$(pwd)")"
	MASTER_DIR="$(dirname "${parent}")/$(basename "${parent}")"
fi
if [ ! -d "$MASTER_DIR" ]; then
	## Or MASTER_DIR falls back to being CURR_DIR.
	MASTER_DIR="${CURR_DIR}"
fi

## This script is designed to be called as a git alias, so we should be in the root of the checkout from which we want to branch.
NEW_DIR="$NEW_TICKET"
if [ "$1" != "" ]; then
	NEW_DIR="$1"
	shift
fi
if [ -e "../$NEW_DIR" ]; then
	echo "New branch directory already exists.  CD into it and run 'git checkout -b $NEW_BRANCH' like everyone else"
	print_help
fi

if [ $# -ne 0 ]; then
	print_help
else
	echo "Creating branch ${NEW_BRANCH} from ${CURR_BRANCH} in ${NEW_DIR}"
	sleep 1
fi

git pull --all
git fetch origin ${CURR_BRANCH}

( cd .. && git new-workdir "${MASTER_DIR}" "${NEW_DIR}" "${CURR_BRANCH}" )

function cleanup()
{
	popd
}
trap cleanup EXIT

pushd "../${NEW_DIR}" >/dev/null

git checkout -b "${NEW_BRANCH}" || git checkout "${NEW_BRANCH}"
git push --set-upstream origin "${NEW_BRANCH}"
git update

shopt -s nullglob
set -- ../.[a-z]*
if [ "$#" -gt 0 ]; then
	ln -sv ../.[a-z]* ./ 2>/dev/null
fi
rm .project 2>/dev/null
cp ../.project ./ 2>/dev/null || cp ../master/.project ./ 2>/dev/null
if [ -f .project ]; then
	sed -re 's!@master</name>!@'"${NEW_TICKET}_${NEW_DESCR}"'</name>!' .project -i 2>/dev/null
fi
