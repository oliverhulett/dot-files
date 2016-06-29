source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"
export GOTOOLS="${HOME}/3rd_party_tools/gotools"
export PATH="$(prepend_path "${GOTOOLS}/bin" "/usr/local/go/bin")"
