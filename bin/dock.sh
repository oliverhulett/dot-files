#!/bin/bash

if [ $# -eq 0 ]; then
	set -- --interactive
fi

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "$(dirname $0)/../bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup
fi

$(dirname $0)/../bootstrap/bootstrap_docker_build.py --bootstrap-docker-image="$(dirname $0)/../Dockerfile" "$@"
