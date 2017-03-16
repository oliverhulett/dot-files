#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

## Old versions of git play with the path.  Old versions of git are correlated with old versions of Centos, which means old versions of python.
## If we need a python venv in out bash setup, assume we need it here too.
if [ -e "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh" ]; then
	source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"
fi

EXTERNALS="$(git ls-files '*externals.json')"

echo "Unpinning externals..."
python - ${EXTERNALS} <<EOF
import os
import sys
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

files = sys.argv[1:]
while len(files) > 0:
    do_file(files.pop(0))
EOF

for d in "${EXTERNALS}"; do
	python -m json.tool $d >&${log_fd} && echo "$(python -m json.tool $d)" > $d
done

git update 2>&${log_fd} >&${log_fd}
