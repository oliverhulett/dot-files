#!/bin/bash -x
set -e

cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(git home)" || exit 1

OTHER_REMOTE="$(git remote | command grep -v origin)"
if [ -z "${OTHER_REMOTE}" ]; then
	echo "Can't merge; there's no other remote..."
	exit 0
fi
BRANCH="$(git this)"

#trap 'git reset --hard HEAD' EXIT
git fetch "$OTHER_REMOTE"
git diff -R "$OTHER_REMOTE/$BRANCH" -- $(cat sync2home.txt) | git apply --index
#git commit --allow-empty -m"Autocommit diff from $OTHER_REMOTE/$BRANCH on $(date -R)\n$(git status --short)"
