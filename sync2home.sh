#!/bin/bash
set -e

HERE="$(dirname "${BASH_SOURCE[0]}")"
cd "${HERE}" || ( echo "Failed to enter run directory"; exit 1 )

OTHER_REMOTE="$(git remote | command grep -v origin)"
if [ -z "${OTHER_REMOTE}" ]; then
	echo "Can't merge; there's no other remote..."
	exit 0
fi
BRANCH="$(git this)"
IGNORE_LIST="${HERE}/sync2home.ignore.txt"

echo "Pulling and fetching latest from remotes..."
git push
git pull --all
git fetch "$OTHER_REMOTE" "$BRANCH"
echo "Merging from $OTHER_REMOTE/$BRANCH..."
git merge --no-commit FETCH_HEAD
git reset -- $(cat "$IGNORE_LIST")
echo "Committing changes..."
git status
git commit -a -m"Sync2Home autocommit from $OTHER_REMOTE/$BRANCH: $(git status -s)" --allow-empty
echo
echo "Done.  Sync-ed $OTHER_REMOTE/$BRANCH"
