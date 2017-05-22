#!/bin/bash
## Called from the top level of the git repository.
set -e

test -d .git

shopt -s nullglob
find .git/refs/heads -type f | while read -r; do
	set -- .git/refs/remotes/*/"${REPLY#./}"
	b="$(basename "${REPLY}")"
	if [ $# -eq 0 ] && [ "$b" != "master" ]; then
		git branch -d "$b"
	fi
done
