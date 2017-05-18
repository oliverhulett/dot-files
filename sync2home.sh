#!/bin/bash -x
set -e

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

trap 'git reset --hard HEAD' EXIT

git fetch optiver
git diff -R optiver/master -- $(cat sync2home.txt) | git apply --index
git commit --allow-empty -m"Autocommit diff from optiver/master on $(date -R)\n$(git status --short)"
