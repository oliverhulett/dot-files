#!/bin/bash
# Set-up python virtual env

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"

venv_setup

function pip_version()
{
	${PYVENV_HOME}/bin/pip --version 2>&1
}

PYSETUP_MARKER="${PYVENV_HOME}/.setup"
if [ ! -e "${PYSETUP_MARKER}" ] || [ "$(command cat "${PYSETUP_MARKER}" 2>/dev/null)" != "$(pip_version)" ]; then
	touch "${PYSETUP_MARKER}"
	## Install the things
	pip -q install -U pip
	pip -q install -U wheel setuptools
	pip -q install -U -r "${DOTFILES}/python_setup.txt"

	pip_version >"${PYSETUP_MARKER}"
fi
