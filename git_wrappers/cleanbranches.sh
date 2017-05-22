#!/bin/bash
## Called from the top level of the git repository.
set -e

shopt -s nullglob
test -d .git

find .git/refs/heads -type f | while read -r; do
	set -- .git/refs/remotes/*/"${REPLY#./}"
	if [ $# -eq 0 ] && [ "${REPLY#./}" != "master" ]; then
		git branch -d "${REPLY#./}"
	fi
done
