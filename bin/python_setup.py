#!/bin/bash
# Set-up python virtual env

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

## Install the things
pip -q install -U pip
pip -q install -U wheel setuptools
pip -q install -U -r "${DOTFILES}/python_setup.txt"
