#!/bin/bash

GIT_URL_BASE="ssh://git@git.comp.optiver.com:7999"
REPO_DIR="C:\\Repo"

if [ $# -eq 2 ]; then
	PROJ="$(echo $1 | tr '[A-Z]' '[a-z]')"
	REPO="$(echo $2 | tr '[A-Z]' '[a-z]')"
else
	echo 2>/dev/null "Clone a repo into the repo heirarchy"
	echo 2>/dev/null "$(basename "$0") <PROJECT> <REPOSITORY>"
	exit 1
fi

GIT_URL="${GIT_URL_BASE}/${PROJ}/${REPO}.git"
DEST_DIR="${REPO_DIR}\\${PROJ##\~}\\${REPO}"

mkdir --parents "${DEST_DIR}"
pushd "${DEST_DIR}" 2>/dev/null >/dev/null

function cleanup()
{
	popd 2>/dev/null >/dev/null
	rmdir --parents "${DEST_DIR}\\master" 2>/dev/null || true
	rmdir --parents "${DEST_DIR}" 2>/dev/null || true
}
trap cleanup EXIT
set -e

if [ ! -d "${DEST_DIR}\\master" ]; then
	git clone --recursive ${GIT_URL} master
	( cd master && git update )
else
	echo "${DEST_DIR}\\master already exists."
fi

