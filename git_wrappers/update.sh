#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh"
## If we're using dependencies.json, check that it is sane.
if [ -f ./dependencies.json ]; then
	python -m json.tool ./dependencies.json
fi
## If we're using externals.json, check that it is sane.
if [ -f ./externals.json ]; then
	python -m json.tool ./externals.json
elif [ -f ./deps.json ]; then
	python -m json.tool ./deps.json
fi

## `git updat e-c` is a common typo when fingers outpace brains.  Git will correctly guess that you meant `git update` but not that you meant `git update -c`.
if [ "$1" == "-c" -o "$1" == "--clean" -o "$1" == "e-c" -o "$1" == "ec-" -o "$1" == "-ec" -o "$1" == "-ce" ]; then
	if [ -f ./pins.json ]; then
		echo "Removing externals from: pins.json"
		sed -nre 's/^[ \t]+"(.+)": \{/\1/p' ./pins.json | tee >(xargs rm -rf) | xargs
	fi
	find ./ -not \( -name .git -prune -or -name .svn -prune \) -name externals.json | while read; do
		echo "Removing externals from: $REPLY"
		sed -nre 's/^[ \t]+"(.+)": \{/\1/p' "$REPLY" | tee >(xargs rm -rf) | xargs
	done
	echo "Removing '.git/externals/' and likely external directories: " x_*
	rm -rf .git/externals x_* 2>/dev/null
fi

if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
elif [ -f ./.gitsvnextmodules -o -f ./externals.json ]; then
	getdep
fi
if [ -f ./deps.json ]; then
	courier
fi

git submodule init
git submodule update

