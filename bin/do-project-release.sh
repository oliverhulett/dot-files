#!/bin/bash

BAMBOO_USER="_bamboo_trd"
WIKI_SPACE="LIMITS"
AUTH_FILE="${HOME}/etc/release.auth"

if [ $# -ne 4 -a $# -ne 5 ]; then
	echo "Bad command line.  Usage:"
	echo "$(basename "$0") <JIRA_PROJECT_KEY> <PROJECT_NAME> <TAG_VERSION> <WIKI_PARENT_PAGE> [<PROJECT_ROOT_DIR>]"
	echo "  JIRA_PROJECT_KEY - The project key corresponding to the Jira project containing tickets for this project."
	echo "  PROJECT_NAME     - The name of the project to be prefixed to the version."
	echo "  TAG_VERSION      - The SemVer version number to be released.  A tag with this version should have been made already."
	echo "  WIKI_PARENT_PAGE - The title of the Wiki page to be used as the parent for generated release notes."
	echo "  PROJECT_ROOT_DIR - The top of a git checkout of the project to be released.  Defaults to the CWD."
	exit 1
fi

JIRA_PROJECT_KEY="$1"
shift
PROJECT_NAME="$1"
shift
TAG_VERSION="$1"
shift
WIKI_PARENT_PAGE="$1"
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

if ! command which release_notes_generator >/dev/null 2>/dev/null; then
	echo "release_notes_generator not found.  Attempting to pip install..."
	pip install release_notes_generator
	if ! command which release_notes_generator >/dev/null 2>/dev/null; then
		echo "release_notes_generator not found"
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

echo "Generating release notes from JIRA tickets and git commit messages."
run release_notes_generator -a "${AUTH_FILE}" --verbose --username "${BAMBOO_USER}" \
	--jira-project "${JIRA_PROJECT_KEY}" --wiki-space "${WIKI_SPACE}" --parent-wiki "${WIKI_PARENT_PAGE}" \
	--git-url "${GIT_URL}" --jira-version-prefix "${PROJECT_NAME}" --version "${TAG_VERSION}"

