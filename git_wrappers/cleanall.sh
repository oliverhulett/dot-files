#!/bin/bash

function cleanempty()
{
	find -L ./ -xdev -not -wholename '*.git*' -type l -delete
	find ./ -xdev -not -wholename '*.git*' -not -wholename '*.svn*' -type d | while read; do
		if [ -z "$(/bin/ls "$REPLY")" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

rm -rf .git/externals x_*
cleanempty

tmp="$(mktemp -d)"
find ./ -xdev -not -wholename '*.git*' \( -name .project -or -name .pydevproject -or -name .cproject -or -name .settings \) -print0 | xargs -0 cp --parents -xPr --target-directory="${tmp}/" 2>/dev/null

git cleanignored

rsync -zvpPAXrogthlm "${tmp}/" ./ && rm -rf "${tmp}"

cleanempty

git stash
git pull
git stash pop

if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
fi
if [ -f ./deps.json ]; then
	courier
fi

