export GOROOT="$HOME/repo/3rd_party_tools/go1.2.1"
export GOTOOLS="$HOME/repo/3rd_party_tools/gotools"
export GO_VER=

# We want a slightly more subtle equivalent of PATH=$PATH:$GOROOT/bin:$GOTOOLS/bin
PATH="$(echo "$PATH" | sed -re "s!$GOROOT/bin:?!!;s!$GOTOOLS/bin:?!!"):$GOROOT/bin:$GOTOOLS/bin"
export PATH
