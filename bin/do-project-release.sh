#!/bin/bash

BAMBOO_USER="_bamboo_trd"
WIKI_SPACE="LIMITS"

if [ $# -ne 3 -a $# -ne 4 ]; then
	echo "Bad command line.  Usage:"
	echo "$(basename "$0") <JIRA_PROJECT_KEY> <WIKI_PARENT_PAGE> <TAG_VERSION> [<PROJECT_ROOT_DIR>]"
	echo "  JIRA_PROJECT_KEY - The project key corresponding to the Jira project containing tickets for this project."
	echo "  WIKI_PARENT_PAGE - The title of the Wiki page to be used as the parent for generated release notes."
	echo "  TAG_VERSION      - The SemVer version number to be released.  A tag with this version should have been made already."
	echo "  PROJECT_ROOT_DIR - The top of a git checkout of the project to be released.  Defaults to the CWD."
	exit 1
fi

JIRA_PROJECT_KEY="$1"
shift
WIKI_PARENT_PAGE="$1"
shift
TAG_VERSION="$1"
shift
PROJECT_ROOT_DIR="$(pwd -P)"
if [ $# -ne 0 ]; then
	if ! pushd "$1" >/dev/null 2>/dev/null; then
		echo "Could not change into requested project root directory.  '$1' does not exist"
		exit 1
	fi
	PROJECT_ROOT_DIR="$(pwd -P)"
	popd >/dev/null 2>/dev/null
fi

if ! pushd "${PROJECT_ROOT_DIR}" >/dev/null 2>/dev/null; then
	echo "Could not change into project root directory.  '${PROJECT_ROOT_DIR}' does not exist"
	exit 1
fi
function cleanup()
{
	popd >/dev/null 2>/dev/null
}
trap cleanup EXIT

GIT_URL="$(git config --get remote.origin.url 2>/dev/null)"
if [ -z "${GIT_URL}" ]; then
	echo "Could not find git URL for project.  'git config --get remote.origin.url' failed."
	echo "Either '${PROJECT_ROOT_DIR}' is not a valid git project or 'git remote' is not setup correctly."
	exit 1
fi

if ! git rev-parse -q --verify "refs/tags/${TAG_VERSION}" >/dev/null 2>/dev/null; then
	echo "Tag version does not exist.  Project must be tagged first."
	echo "Try:"
	echo "  ./tagme.sh ${TAG_VERSION} <MESSAGE>"
	echo "or"
	echo "  git tag ${TAG_VERSION} -m '<MESSAGE>' && git push --tags"
	exit 1
fi

if ! /usr/bin/which set_release_version >/dev/null 2>/dev/null; then
	echo "set_release_version not found.  Attempting to pip install..."
	pip install trdb_release_manager
	if ! /usr/bin/which set_release_version >/dev/null 2>/dev/null; then
		echo "set_release_version not found"
		exit 1
	fi
fi

function run()
{
	for cmd in 'echo $ ' ''; do
		$cmd "$@"
	done
}

set -e

echo "Setting release version on JIRA tickets from git commit messages."
run set_release_version -a "${HOME}/etc/release.auth" --verbose --username "${BAMBOO_USER}" \
	--jira-project "${JIRA_PROJECT_KEY}" --git-ssh-url "${GIT_URL}" \
	--fix-version "${TAG_VERSION}"

echo
echo "Creating release notes wiki page."
run docker run -u `whoami` -w `pwd` -v `pwd`:`pwd` -v ~/.ssh:/home/`whoami`/.ssh -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group \
	--rm docker-registry.aus.optiver.com/optiver/release_manager:0.1.0 \
	--verbose --username "${BAMBOO_USER}" --jira-project "${JIRA_PROJECT_KEY}" --wiki-space "${WIKI_SPACE}" --parent-page "${WIKI_PARENT_PAGE}" --git-url "${GIT_URL}" --git-tag "${TAG_VERSION}" -f "${TAG_VERSION}"

