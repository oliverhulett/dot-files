#!/bin/bash

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

