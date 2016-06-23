# Use GCC 4.7.2 from /opt/optiver/gcc and try to manipulate the PATH variable so that it is the
# default but also so that ccache also works if it is available.
source "/home/olihul/etc/dot-files/bash_common.sh"

CCACHE_PATH=/usr/lib64/ccache
GCC_PATH=/opt/optiver/gcc/4.7.2/bin
GCC_LD_PATH=/opt/optiver/gcc/4.7.2/lib64:/opt/optiver/gcc/4.7.2/lib
GCC_LINX="/home/olihul/bin/gcc"
mkdir --parents "$GCC_LINX" 2>/dev/null
pushd "$GCC_LINX" >/dev/null 2>/dev/null
for b in $GCC_PATH/*47; do
	n=$(basename "$b")
	n=${n%47}
	ln -s "$b" ./$n >/dev/null 2>/dev/null
done
unset b
popd >/dev/null 2>/dev/null

# We want a slightly more subtle equivalent of PATH=$CCACHE_PATH:$GCC_PATH:$PATH
# prepend_path() will prepend in reverse order
export PATH="$(prepend_path "$GCC_PATH" "$GCC_LINX" "$CCACHE_PATH")"
LD_LIBRARY_PATH="$GCC_LD_PATH:$(echo "$LD_LIBRARY_PATH" | sed -re "s!(^|:)$GCC_LD_PATH/?(:|$)!\1!")"
export LD_LIBRARY_PATH 

