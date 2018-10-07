# shellcheck shell=bash
# Paths for MacPorts
source "${HOME}/dot-files/bash-common.sh"

PATH="$(append_path "${PATH}" "/opt/local/bin" "/opt/local/sbin")"
export PATH
