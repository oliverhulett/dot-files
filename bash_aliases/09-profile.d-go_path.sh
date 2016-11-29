source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"
export GOTOOLS="${HOME}/3rd-party-tools/gotools"
export GOPATH="${GOTOOLS}"
export PATH="$(prepend_path "${GOTOOLS}/bin" "/usr/local/go/bin")"
