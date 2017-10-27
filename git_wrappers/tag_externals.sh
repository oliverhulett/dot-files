#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

## Old versions of git play with the path.  Old versions of git are correlated with old versions of Centos, which means old versions of python.
## If we need a python venv in out bash setup, assume we need it here too.
if [ -e "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh" ]; then
	source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"
fi

EXTERNALS="$(git ls-files '*externals.json' '*deps.json')"

git pull --all
git update 2>&${log_fd} >&${log_fd}

echo
echo "Tagging externals..."
echo
python - "$@" ${EXTERNALS} <<EOF
import os
import sys
import json
import subprocess
import argparse

parser = argparse.ArgumentParser(description="Tag and pin externals to latest versions")
parser.add_argument('-k', '--keep', action='store_true', help="Keep existing versions of already tagged externals")
parser.add_argument('-m', '--keep-master', action='store_true', help="Keep master for externals currently pointing at master")
parser.add_argument('-p', '--pin', action='store_true', help="Add revision pins to all tags")
parser.add_argument('--pin-all', action='store_true', help="Add revision pins to all externals")
parser.add_argument('-u', '--unpin', action='store_true', help="Remove revision pins from all externals")
parser.add_argument('files', nargs=argparse.REMAINDER, help="externals.json files to use")
args = parser.parse_args(sys.argv[1:])
files = args.files

def do_file(name):
	global files
	with open(name) as f:
		xternals = json.load(f)
	if '@import' in xternals:
		files += [os.path.join(n, 'externals.json') for n in xternals['@import']]
	for key in xternals.iterkeys():
		d = os.path.join(os.path.dirname(name), key)

		p = subprocess.Popen(['git', 'tags', '1'], stdout=subprocess.PIPE, cwd=d)
		out, _ = p.communicate()
		try:
			tag = out.strip().split()[6]
		except:
			tag = None

		if tag is not None:
			p = subprocess.Popen(['git', 'show-ref', '-d', tag], stdout=subprocess.PIPE, cwd=d)
		else:
			p = subprocess.Popen(['git', 'show-ref', 'HEAD'], stdout=subprocess.PIPE, cwd=d)
		out, _ = p.communicate()
		try:
			rev = None
			for line in out.strip.split('\n'):
				if line.strip().endswith('^{}'):
					rev = line.strip().split()[0]
		except:
			rev = None

		keep = False
		if not args.unpin and not args.pin and not args.pin_all and rev is not None:
			keep = True
		is_master = False
		if ('ref' not in xternals[key]) or (xternals[key]['ref'] == 'master'):
			is_master = True
		if (tag is not None) and (not keep or not args.keep or (is_master and not args.keep_master)):
			xternals[key]['ref'] = tag
		if args.unpin and ('rev' in xternals[key]):
			del xternals[key]['rev']
		if (rev is not None) and (args.pin_all or (args.pin and not is_master)):
			xternals[key]['rev'] = rev

	with open(name, 'w') as f:
		json.dump(xternals, f, indent=4, sort_keys=True)

while len(files) > 0:
	do_file(files.pop(0))
EOF

for d in $(git submodule foreach --quiet pwd); do
	if [ "$(cd $d && git rev-parse --abbrev-ref HEAD)" == "master" ]; then
		tag="$( cd $d && git tags 1 | cut -f7 -d' ')"
		if [ -n "$tag" ]; then
			( cd $d && git checkout "$tag" ) && git add $d
		fi
	fi
done

echo
echo "Updating new externals..."
echo
git update 2>&${log_fd} >&${log_fd}
