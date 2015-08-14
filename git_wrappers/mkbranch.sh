#!/bin/bash

CURR_BRANCH="$(git branch --no-color | sed -nre 's/^\* //p')"
CURR_DIR="$(basename "$(pwd)")"
NEW_BRANCH="$1"
NEW_DIR="$(echo ${NEW_BRANCH} | cut -d_ -f1)"

## This script is designed to be called as a bash alias, so there we should be in the root of the checkout from which we want to branch.
git pull

( cd .. && git new-workdir "${CURR_DIR}" "${NEW_DIR}" )

function cleanup()
{
	popd >/dev/null
}
trap cleanup EXIT

pushd "../${NEW_DIR}" >/dev/null

git checkout -b "${NEW_BRANCH}" || git checkout "${NEW_BRANCH}"
git push --set-upstream origin "${NEW_BRANCH}"
if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
fi
if [ -f ./deps.json ]; then
	courier
fi

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

## Stay in new branch directory
trap EXIT

