#!/bin/bash
## Called from the top level of the git repository.
set -e

GITDIR=".git"
if [ ! -d "${GITDIR}" ]; then
	GITDIR="$(sed -nre 's/^gitdir: (.+)$/\1/p' .git)"
fi
test -d "${GITDIR}" || ( echo "GITDIR not found: $GITDIR"; file .git; exit 1 )
GITDIR="$(cd "${GITDIR}" && pwd -P)"

shopt -s nullglob
HEADS="${GITDIR}/refs/heads"
test -d "${HEADS}"
(
	cd "${HEADS}" && \
	find ./ -type f | while read -r; do
		b="${REPLY#./}"
		set -- "${GITDIR}"/refs/remotes/*/"${b}"
		if [ $# -eq 0 ] && [ "$(basename -- "$b")" != "master" ]; then
			git branch -d "$b"
		fi
	done
)
