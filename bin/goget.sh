#!/bin/bash
#
# Wrapper for `go get`
#

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

export GOPATH="${GOTOOLS}"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup
fi

echo "Setting GOPATH='${GOPATH}'"
echo "Go-ing and Get-ing packages"
echo "\$ go get $@"
go get "$@" || exit 1
