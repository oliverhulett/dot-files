#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

BASH_ALIASES="$(cd "$(dirname "$0")/../bash_aliases" && pwd -P)"
source "${BASH_ALIASES}/28-completion-docker.sh"
source "${BASH_ALIASES}/29-completion-docker_custom.sh"

__docker_images "$@"
