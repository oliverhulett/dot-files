#!/bin/bash
## Called from the top level of the git repository.
set -e

test -d .git

shopt -s nullglob
HEADS=".git/refs/heads"
find "${HEADS}" -type f | while read -r; do
	set -- .git/refs/remotes/*/"${REPLY#${HEADS}/}"
	b="$(basename "${REPLY}")"
	if [ $# -eq 0 ] && [ "$b" != "master" ]; then
		git branch -d "$b"
	fi
done
