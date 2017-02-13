# Use GCC 4.7.2 from /opt/optiver/gcc and try to manipulate the PATH variable so that it is the
# default but also so that ccache also works if it is available.
source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"

# We want a slightly more subtle equivalent of PATH=$CCACHE_PATH:$GCC_PATH:$PATH
# prepend_path() will prepend in reverse order
if [ -d /opt/optiver/gcc/4.7.2 ]; then
	CCACHE_PATH=/usr/lib64/ccache
	GCC47_PATH=/opt/optiver/gcc/4.7.2/bin
	GCC47_LD_PATH=/opt/optiver/gcc/4.7.2/lib64:/opt/optiver/gcc/4.7.2/lib

	if [ "$(/usr/bin/gcc --version | head -n1 | cut -d' ' -f3 | cut -d. -f1,2)" == "4.8" ]; then
		export PATH="$(prepend_path "$GCC47_PATH" "/usr/bin" "$CCACHE_PATH")"
	else
		export PATH="$(prepend_path "$GCC47_PATH" "$CCACHE_PATH")"
		export LD_LIBRARY_PATH="$GCC47_LD_PATH:$(echo "$LD_LIBRARY_PATH" | sed -re "s!(^|:)$GCC47_LD_PATH/?(:|$)!\1!;s/^://;s/::+/:/g;s/:$//")"
	fi
#else
#	export PATH="$(prepend_path "/usr/bin" "$CCACHE_PATH")"
fi
