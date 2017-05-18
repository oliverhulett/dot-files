#!/bin/bash -x
set -e

cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(git home)" || exit 1

#trap 'git reset --hard HEAD' EXIT

OTHER_REMOTE="$(git remote | command grep -v origin)"
BRANCH="$(git this)"
git fetch "$OTHER_REMOTE"
git diff -R "$OTHER_REMOTE/$BRANCH" -- $(cat sync2home.txt) | git apply --index
#git commit --allow-empty -m"Autocommit diff from $OTHER_REMOTE/$BRANCH on $(date -R)\n$(git status --short)"
