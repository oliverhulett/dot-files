#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

BASH_ALIASES="$(cd "${DOTFILES}/bash-aliases" && pwd -P)"
source "${BASH_ALIASES}/28-completion-docker.sh"
source "${BASH_ALIASES}/29-completion-docker_custom.sh"

__docker_images "$@"
