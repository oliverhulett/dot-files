#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh" || true

EXTERNALS="$(git ls-files '*externals.json')"

git update 2>/dev/null >/dev/null

echo
echo "Pinning externals"
export PYTHONPATH="${HOME}/repo/pyu/git_utils/master"
for d in "${EXTERNALS}"; do
	( cd $(dirname $d) && python -m git_utils.pin_externals )
    python -m json.tool $d > /dev/null && echo "$(python -m json.tool $d)" > $d
done
echo

git update 2>/dev/null >/dev/null

