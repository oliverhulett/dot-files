#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
	source "$(dirname $0)/../bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup
fi

$(dirname $0)/../bootstrap/bootstrap_docker_build.py --bootstrap-docker-image="$(dirname $0)/../images/c7/Dockerfile" --superuser
