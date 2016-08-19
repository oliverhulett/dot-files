#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh"
if [ ! -x .git/git_utils/git_utils/externals_updater.py ]; then
	echo "Cannot upgrade externals.  git_utils is not installed."
	exit 1
fi
if [ ! -x .git/git_utils/git_utils/pin_externals.py ]; then
	echo "Cannot upgrade externals.  git_utils is not installed."
	exit 1
fi
if [ ! -f ./externals.json ]; then
	echo "Cannot upgrade externals.  No externals.json found."
	exit 1
fi

## TODO:  Remove this when they've all been updated...
find . -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -name 'externals.json' | while read; do sed -re 's/git@git:7999/git@git.comp.optiver.com:7999/' "$REPLY" -i; done

git pull --all
if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
else
	getdep
fi

echo
echo "updating externals"
python ./.git/git_utils/git_utils/externals_updater.py
echo

## Update...
if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
else
	getdep
fi
echo

## Unpin non-tags...
"$(dirname "$(readlink -f "$0")")/unpin_externals.sh"
python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json"

