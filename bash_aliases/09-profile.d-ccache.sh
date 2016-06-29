# CCACHE exports.

export CCACHE_BASEDIR="${HOME}/repo"
export CCACHE_PREFIX=distcc
export CCACHE_COMPRESS=yes
ccache -M 100G >/dev/null 2>/dev/null

