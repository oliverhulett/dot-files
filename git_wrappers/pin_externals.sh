#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh" || true

getdep -s

echo
echo "Pinning externals"
for d in $(find . -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -name 'externals.json'); do
	( cd $(dirname $d) && python -m getdep.pin_externals )
	( cd $(dirname $d) && python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json" )
done
echo

getdep -s

