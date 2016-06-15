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
echo
python <<EOF
import os
import json

def do_file(name):
    global files
    with open(name) as f:
        xternals = json.load(f)
    if '@import' in xternals:
        print xternals['@import']
        files += [os.path.join(n, 'externals.json') for n in xternals['@import']]
    for key in xternals.iterkeys():
        if 'rev' in xternals[key]:
            del xternals[key]['rev']
    with open(name, 'w') as f:
        json.dump(xternals, f, indent=4)

files = ['externals.json']
while len(files) > 0:
    print files
    do_file(files.pop(0))
EOF

if [ -x ./git_setup.py ]; then
	./git_setup.py -kq
else
	getdep
fi

./.git/git_utils/git_utils/pin_externals.py
python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json"

