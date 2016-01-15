export GOROOT="/home/olihul/3rd_party_tools/go1.2.1"
export GOTOOLS="/home/olihul/3rd_party_tools/gotools"
export GO_VER=

# We want a slightly more subtle equivalent of PATH=$PATH:$GOROOT/bin:$GOTOOLS/bin
PATH="$GOROOT/bin:$GOTOOLS/bin:$(echo "$PATH" | sed -re "s!(^|:)$GOROOT/bin/?(:|$)!\1!;s!(^|:)$GOTOOLS/bin/?(:|$)!\1!")"
export PATH
