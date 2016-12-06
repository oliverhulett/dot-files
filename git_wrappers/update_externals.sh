#!/bin/bash

## Until v2.5 git would pre-pend /usr/bin to path, which means the wrong python is found.
source "$(dirname "$(readlink -f "$0")")/../bash_aliases/09-profile.d-pyvenv.sh" || true

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

