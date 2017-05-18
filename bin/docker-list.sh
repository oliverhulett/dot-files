#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

BASH_ALIASES="$(cd "$(dirname "$0")/../bash_aliases" && pwd -P)"
source "${BASH_ALIASES}/28-completion-docker.sh"
source "${BASH_ALIASES}/29-completion-docker_custom.sh"

__docker_images "$@"
