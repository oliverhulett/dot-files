# Use GCC 4.7.2 from /opt/optiver/gcc and try to manipulate the PATH variable so that it is the
# default but also so that ccache also works if it is available.

CCACHE_PATH=/usr/lib64/ccache
GCC_PATH=/opt/optiver/gcc/4.7.2/bin
GCC_LINX="${HOME}/bin/gcc"
mkdir --parents "$GCC_LINX" 2>/dev/null
pushd "$GCC_LINX" >/dev/null 2>/dev/null
for b in $GCC_PATH/*47; do
	n=$(basename "$b")
	n=${n%47}
	ln -s "$b" ./$n >/dev/null 2>/dev/null
done
popd >/dev/null 2>/dev/null

# We want a slightly more subtle equivalent of PATH=$CCACHE_PATH:$GCC_PATH:$PATH
PATH="$CCACHE_PATH:$GCC_LINX:$GCC_PATH:$(echo "$PATH" | sed -re "s!$CCACHE_PATH:?!!;s!$GCC_LINX:?!!;s!$GCC_PATH:?!!")"

export PATH

