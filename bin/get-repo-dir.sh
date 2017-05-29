#!/bin/bash
#
#	Get the directory in which a given repository is cloned.
#	$ get-repo-dir [<proj>] <repo> [<branch>] [<dirs...>]
#	If only one project contains a repository with the name <repo>, <proj> can be inferred.
#	<branch> defaults to "master"
#

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

set -- $(echo "$@" | tr '/' ' ')
if [ $# -lt 1 ]; then
	exit 1
fi
if [ -d "${HOME}/repo/$1" ]; then
	proj="$1"
	repo="$2"
	shift 2
else
	proj='*'
	repo="$1"
	shift
fi
shopt -s nullglob
branch="master"
if [ $# -gt 0 ] && [ -d "$(echo ${HOME}/repo/${proj}/${repo}/$1)" ]; then
	branch="$1"
	shift
fi
for d in ${HOME}/repo/${proj}/${repo}/${branch}/"$(echo $* | tr ' ' '/')"; do
	echo "${d%%/}"
done
