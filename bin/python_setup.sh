#!/bin/bash
# Set-up python virtual env

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/.bash_aliases/09-profile.d-pyvenv.sh"

venv_setup

## Install the things
pip install -U pip
pip install -U wheel setuptools

pip install -U -r "${DOTFILES}/python_setup.txt"
