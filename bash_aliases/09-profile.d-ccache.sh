# CCACHE exports.
source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true

export CCACHE_BASEDIR="${HOME}/repo"
export CCACHE_PREFIX=distcc
export CCACHE_COMPRESS=yes
ccache -M 100G >&${log_fd} 2>&${log_fd}
