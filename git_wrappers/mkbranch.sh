#!/bin/bash

CURR_BRANCH="$(git branch --no-color | sed -nre 's/^\* //p')"
CURR_DIR="$(basename "$(pwd)")"
NEW_BRANCH="$1"
NEW_DIR="$(echo ${NEW_BRANCH} | cut -d_ -f1)"
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

## This script is designed to be called as a bash alias, so there we should be in the root of the checkout from which we want to branch.
git pull

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
	sed -re 's!@master</name>!@'"${NEW_BRANCH}"'</name>!' .project -i 2>/dev/null
fi

