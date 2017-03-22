# Setup ccache
source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
ccache -M 100G >&${log_fd} 2>&${log_fd}
