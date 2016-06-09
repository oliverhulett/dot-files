#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/profile.d-pyvenv.sh"
if [ ! -x .git/git_utils/git_utils/externals_updater.py ]; then
	echo "Cannot update externals.  git_utils is not installed."
	exit 1
fi
if [ ! -f ./externals.json ]; then
	echo "Cannot update externals.  No externals.json found."
	exit 1
fi

git pull --all
if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
else
	getdep
fi

echo
echo "updating externals"
./.git/git_utils/git_utils/externals_updater.py
python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json"
echo

if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
else
	getdep
fi

