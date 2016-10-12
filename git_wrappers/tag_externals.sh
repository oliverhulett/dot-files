#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh"
if [ ! -x .git/git_utils/git_utils/pin_externals.py ]; then
	echo "Cannot tag externals.  git_utils is not installed."
	exit 1
fi
if [ ! -f ./externals.json ]; then
	echo "Cannot tag externals.  No externals.json found."
	exit 1
fi

git pull --all
if [ -x ./git_setup.py ]; then
	python ./git_setup.py -kq
else
	getdep
fi

echo
python <<EOF
import os
import json
import subprocess

def do_file(name):
    global files
    with open(name) as f:
        xternals = json.load(f)
    if '@import' in xternals:
        files += [os.path.join(n, 'externals.json') for n in xternals['@import']]
    for key in xternals.iterkeys():
        d = os.path.join(os.path.dirname(name), key)
        if 'ref' in xternals[key] and (xternals[key]['ref'] == 'master'):
            p = subprocess.Popen(['git', 'for-each-ref', '--count=1', '--sort=-taggerdate', '--format=%(tag)', 'refs/tags'], stdout=subprocess.PIPE, cwd=d)
            out, _ = p.communicate()
            tag = out.strip()
            if tag != '':
                print 'Tagging external {0} @ {1}'.format(key, tag)
                if 'rev' in xternals[key]:
                    del xternals[key]['rev']
                xternals[key]['ref'] = tag
    with open(name, 'w') as f:
        json.dump(xternals, f, indent=4)

files = ['externals.json']
while len(files) > 0:
    do_file(files.pop(0))
EOF

## Update...
if [ -x ./git_setup.py ]; then
	python ./git_setup.py -kq
else
	getdep
fi

## Pin...
python ./.git/git_utils/git_utils/pin_externals.py
echo
## Unpin non-tags...
"$(dirname "$(readlink -f "$0")")/unpin_externals.sh"
python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json"

