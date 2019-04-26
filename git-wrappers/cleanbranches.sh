#!/usr/bin/env bash
## Called from the top level of the git repository.
set -e

GITDIR=".git"
if [ ! -d "${GITDIR}" ]; then
	GITDIR="$(sed -nre 's/^gitdir: (.+)$/\1/p' .git)"
fi
test -d "${GITDIR}" || ( echo "GITDIR not found: $GITDIR"; file .git; exit 1 )
GITDIR="$(cd "${GITDIR}" && pwd -P)"

inarray ()
{
	pat="$1";
	shift;
	printf '%s\n' "$@" | grep -qwE "^${pat}$"
}

shopt -s nullglob
HEAD_REFS=()
for r in "${GITDIR}"/refs/remotes/*/HEAD; do
	ref="$(sed -nre 's/^ref: (.+)$/\1/p' "$r")"
	if [ -n "${ref}" ]; then
		HEAD_REFS[${#HEAD_REFS[@]}]="$(basename -- "${ref}")"
	fi
done

HEADS="${GITDIR}/refs/heads"
test -d "${HEADS}"
(
	cd "${HEADS}" && \
	find ./ -type f | while read -r; do
		b="${REPLY#./}"
		set -- "${GITDIR}"/refs/remotes/*/"${b}"
		if [ $# -eq 0 ] && [ "$(basename -- "$b")" != "master" ] && ! inarray "$(basename -- "$b")" "${HEAD_REFS[@]}"; then
			git branch -d "$b"
		fi
	done
)
