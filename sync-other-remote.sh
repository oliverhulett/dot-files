#!/bin/bash

HERE="$(dirname "${BASH_SOURCE[0]}")"
cd "${HERE}" || ( echo "Failed to enter run directory"; exit 1 )

OTHER_REMOTE="$(git remote | command grep -v origin)"
if [ -z "${OTHER_REMOTE}" ]; then
	echo "Can't merge; there is no other remote..."
	exit 1
fi
if [ 1 -ne "$(echo "${OTHER_REMOTE}" | wc -l)" ]; then
	echo "Can't merge; there is more than one other remote..."
	exit 1
fi

if [ -n "$(git status -s)" ]; then
	echo "Can't merge; working tree is not clean, commit or stash local changes..."
	exit 1
fi

set -e

BRANCH="$(git this)"
IGNORE_LIST="${HERE}/sync-other-remote.ignore.txt"

echo "Synchronising branch ${BRANCH} from remote ${OTHER_REMOTE} ($(git config --get "remote.${OTHER_REMOTE}.url")) to origin ($(git config --get remote.origin.url))"

set -x

echo
echo "Fetching latest from remotes..."
git fetch "${OTHER_REMOTE}" "${BRANCH}"

echo
echo "Merging from ${OTHER_REMOTE}/${BRANCH}..."
if [ "$( ( git --version | cut -d' ' -f3; echo "2.9" ) | sort -V | head -n1)" == "2.9" ]; then
	ALLOW_UNRELATED_HISTORIES="--allow-unrelated-histories"
else
	ALLOW_UNRELATED_HISTORIES=
fi
git merge ${ALLOW_UNRELATED_HISTORIES} --no-ff --no-commit FETCH_HEAD || true

echo
echo "Restoring ignored files..."
if [ -s "${IGNORE_LIST}" ]; then
	git reset -- $(command cat "${IGNORE_LIST}")
	LOCAL_FILES="$( ( command cat "${IGNORE_LIST}"; git ls-files ) | sort | uniq -d )"
	if [ -n "${LOCAL_FILES}" ]; then
		git checkout --ours --ignore-skip-worktree-bits -- ${LOCAL_FILES}
	fi
	if [ -n "${LOCAL_FILES}" ]; then
		REMOTE_FILES="$(command cat "${IGNORE_LIST}" | grep -vF "${LOCAL_FILES}")"
	else
		REMOTE_FILES="$(command cat "${IGNORE_LIST}")"
	fi
	if [ -n "${REMOTE_FILES}" ]; then
		rm --verbose -f --dir --one-file-system -- ${REMOTE_FILES}
	fi
fi
echo "Skipping \`git clean -fd'; run manually to clean superfluous files"

echo
echo "Committing changes..."
git status
git commit -a -m"Autocommit: sync-other-remote from ${OTHER_REMOTE}/${BRANCH}: $(git status -s)" --allow-empty

echo
echo "Done.  Sync-ed ${OTHER_REMOTE}/${BRANCH}"
git lg
