# shellcheck shell=bash
# Setup ccache
source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
ccache -M 100G >&${log_fd} 2>&${log_fd}
