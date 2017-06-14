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

LOCAL_FILES="$(git ls-files)"

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

function git()
{
	#echo '$' git "$@"
	echo -n '$' git
	for a in "$@"; do
		if [ "$a" == "--" ]; then
			break
		fi
		echo -n " $a"
	done
	echo " -- ..."
	command git "$@"
	#echo
	#command git status
	#echo
}
git merge ${ALLOW_UNRELATED_HISTORIES} --no-ff --no-commit FETCH_HEAD || true

command git resolve-ours "${IGNORE_LIST}"
IGNORED_FILES="$(while read -r; do ( echo "${LOCAL_FILES}" | command grep -E '^'"$REPLY/" 2>/dev/null ) || echo "$REPLY"; done <"${IGNORE_LIST}" | sort -u)"

echo
echo "Restoring ignored files..."
if [ -n "${IGNORED_FILES}" ]; then
	# Reset files that should not be synced...
	git reset -- ${IGNORED_FILES}

	IGNORED_LOCAL="$( ( echo "${IGNORED_FILES}"; echo "${LOCAL_FILES}" ) | sort | uniq -d )"
	if [ -n "${IGNORED_LOCAL}" ]; then
		# Check-out any local files removed by the merge...
		git checkout --ours --ignore-skip-worktree-bits -- ${IGNORED_LOCAL}
	fi

	if [ -n "${IGNORED_LOCAL}" ]; then
		IGNORED_REMOTE="$(echo "${IGNORED_FILES}" | command grep -vwE "$(echo "${IGNORED_LOCAL}" | sed -re 's/^/^/;s/$/$/' | paste -sd'|')")"
	else
		IGNORED_REMOTE="${IGNORED_FILES}"
	fi

	if [ -n "${IGNORED_REMOTE}" ]; then
		# Remove any ignored files added by the merge...
		echo '$ rm --verbose -rf --dir --one-file-system -- ...'
		rm --verbose -rf --dir --one-file-system -- ${IGNORED_REMOTE}
	fi
fi

unset -f git

echo
echo "Done.  Sync-ed ${OTHER_REMOTE}/${BRANCH}"
echo
git status
echo
git lg

if [ -n "$(git status -s)" ] || [ -e "$(git home)/.git/MERGE_HEAD" ]; then
	echo "Autocommit: sync-other-remote from ${OTHER_REMOTE}/${BRANCH} at $(date) by $(whoami)" >"$(git home)/.git/COMMIT_EDITMSG"
	git status -s >>"$(git home)/.git/COMMIT_EDITMSG"

	if [ -z "$(git status -s | command grep -E '^.[^ ]')" ]; then
		echo
		echo "Committing merge..."
		git commit -F "$(git home)/.git/COMMIT_EDITMSG"
	else
		echo
		echo "Conflicts detected; Resolve them and then run \`git commit' to save the merge..."
	fi
fi
