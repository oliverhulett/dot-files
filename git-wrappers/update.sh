#!/usr/bin/env bash -e

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

## Old versions of git play with the path.  Old versions of git are correlated with old versions of Centos, which means old versions of python.
## If we need a python venv in out bash setup, assume we need it here too.
if [ -e "${HOME}/.bash-aliases/09-profile.d-pyvenv.sh" ]; then
	source "${HOME}/.bash-aliases/09-profile.d-pyvenv.sh"
fi

## `git updat e-c` is a common typo when fingers outpace brains.  Git will correctly guess that you meant `git update` but not that you meant `git update -c`.
if [ "$1" == "-c" -o "$1" == "--clean" -o "$1" == "e-c" -o "$1" == "ec-" -o "$1" == "-ec" -o "$1" == "-ce" ]; then
	git submodule deinit --force .
else
	git submodule init
	git submodule sync
	git submodule update
fi
