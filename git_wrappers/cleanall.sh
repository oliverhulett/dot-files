#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

function cleanempty()
{
	echo "Removing broken symlinks and empty directories."
	find -L ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type l -not -name 'build.py' -delete -print
	find ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read; do
		if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

if [ -x ./build.py ]; then
	echo "Cleaning build."
	./build.py -t all -c
fi

git update --clean

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
