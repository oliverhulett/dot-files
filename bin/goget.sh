#!/bin/bash
#
# Wrapper for `go get`
#

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

export GOPATH="${GOTOOLS}"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup
fi

echo "Setting GOPATH='${GOPATH}'"
echo "Go-ing and Get-ing packages"
echo "\$ go get $@"
go get "$@" || exit 1

