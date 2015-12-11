# CCACHE exports.

export CCACHE_BASEDIR="/home/olihul/repo"
export CCACHE_PREFIX=distcc
export CCACHE_COMPRESS=yes
ccache -M 50G >/dev/null 2>/dev/null

