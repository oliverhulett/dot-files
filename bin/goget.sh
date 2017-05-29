#!/bin/bash
#
# Wrapper for `go get`
#

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

export GOPATH="${GOTOOLS}"

[ -e "${HOME}/.bash_aliases/49-setup-proxy.sh" ] && source "${HOME}/.bash_aliases/49-setup-proxy.sh" 2>/dev/null

echo "Setting GOPATH='${GOPATH}'"
echo "Go-ing and Get-ing packages"
echo "\$ go get $@"
go get "$@" || exit 1
