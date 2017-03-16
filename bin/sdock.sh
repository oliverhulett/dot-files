#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "$(dirname $0)/../bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup
fi

function run()
{
	echo "$@"
	"$@" >/dev/tty 2>/dev/tty
	echo
}
run $(dirname $0)/../bootstrap/bootstrap_docker_build.py --bootstrap-docker-image="$(dirname $0)/../images/c7/Dockerfile" --superuser
