#!/bin/bash

function cleanempty()
{
	echo "Removing broken symlinks and empty directories."
	find -L ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type l -delete -print
	find ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read; do
		if [ -z "$(/bin/ls "$REPLY")" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

if [ -x ./build.py ]; then
	echo "Cleaning build."
	./build.py -c
fi

echo "Removing '.git/externals/' and likely external directories 'x_*'."
rm -rf .git/externals x_*

cleanempty

git cleanignored

cleanempty

echo "Updating repo and externals from upstream."
set -x
stashes=$(git stash list | wc -l)
git stash --include-untracked
git pull
if [ $stashes -ne $(git stash list | wc -l) ]; then
	git stash pop stash@{$stashes}
fi
set +x

git update

git status

