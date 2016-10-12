#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh"
if [ ! -f ./externals.json ]; then
	echo "Cannot modify externals.  No externals.json found."
	exit 1
fi

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
        if 'ref' in xternals[key] and 'rev' in xternals[key]:
            p = subprocess.Popen(['git', 'rev-parse', '-q', '--verify', 'refs/tags/{0}'.format(xternals[key]['ref'])], stdout=subprocess.PIPE, cwd=d)
            p.communicate()
            if p.returncode != 0:
                print "Un-pinning non-tag: {0} @ {1}".format(key, xternals[key]['ref'])
                del xternals[key]['rev']
    with open(name, 'w') as f:
        json.dump(xternals, f, indent=4)

files = ['externals.json']
while len(files) > 0:
    do_file(files.pop(0))
EOF
python -m json.tool "externals.json" > /dev/null && echo "$(python -m json.tool "externals.json")" > "externals.json"

echo
if [ -x ./git_setup.py ]; then
	python ./git_setup.py -kq
else
	getdep
fi

