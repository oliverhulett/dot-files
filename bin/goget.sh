#!/bin/bash
#
# Wrapper for `go get`
#

export GOPATH="${HOME}/3rd_party_tools/gotools"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "${HOME}/.bash_aliases/http_proxy.sh" 2>/dev/null
	proxy_setup
fi

echo "Setting GOPATH='${GOPATH}'"
echo "Go-ing and Get-ing packages"
echo "\$ go get $@"
go get "$@" || exit 1

echo "Installing packages in path: ${GOPATH}/bin/ -> ${HOME}/bin/"
( cd "${HOME}/bin/" && ln -nsfv "${GOPATH}/bin/"* ./ )
