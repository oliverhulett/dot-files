#!/bin/bash

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)"
GIT_BIN="${HERE}/git-bin"

PATH="${GIT_BIN}:${PATH}" command git "$@"
