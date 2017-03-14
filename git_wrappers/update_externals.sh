#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

## Old versions of git play with the path.  Old versions of git are correlated with old versions of Centos, which means old versions of python.
## If we need a python venv in out bash setup, assume we need it here too.
if [ -e "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh" ]; then
	source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"
fi

EXTERNALS="$(git ls-files '*externals.json' '*deps.json')"

## TODO:  Remove this when they've all been updated...
find . -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -name 'externals.json' | while read; do sed -re 's/git@git:7999/git@git.comp.optiver.com:7999/' "$REPLY" -i; done

git pull --all
git update 2>/dev/null >/dev/null

echo
echo "upgrading externals"
export PYTHONPATH="${HOME}/repo/pyu/git_utils/master"
for d in "${EXTERNALS}"; do
    ( cd $(dirname $d) && python -m git_utils.externals_updater )
done
for d in $(git submodule foreach --quiet pwd); do
    if [ -n  "$(cd $d && git describe --tags --exact-match 2>/dev/null)" ]; then
        tag="$( cd $d && git tags 1 | cut -f7 -d' ')"
        if [ -n "$tag" ]; then
            ( cd $d && git checkout "$tag" ) && git add $d
        fi
    fi
done
echo

## Unpin non-tags... (Will also update...)
git unpin
