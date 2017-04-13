#!/bin/bash
# Set-up python virtual env

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"

venv_setup

PYSETUP_MARKER="${PYVENV_HOME}/.setup"
if [ ! -e "${PYSETUP_MARKER}" ]; then
	touch "${PYSETUP_MARKER}"
	trap 'rm "${PYSETUP_MARKER}"' EXIT
	## Install the things
	pip -q install -U pip
	pip -q install -U wheel setuptools
	pip -q install -U -r "${DOTFILES}/python_setup.txt"
fi
