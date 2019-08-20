# shellcheck shell=bash
## Docker aliases and useful functions for starting and stopping images
function _container_alias()
{
	NAME="$1"
	shift
	if [ -z "$(docker container list -q --filter="Name=${NAME}")" ]; then
		docker run --rm -d --name "${NAME}" "$@"
	fi
	while [ -z "$(docker container ls -q --filter "Name=${NAME}" --filter "status=running" 2>/dev/null)" ]; do
		echo -n '.'
	done
	echo
	docker container list --filter="Name=${NAME}"
}

## Run docker-host; a container that dumps the network traffic it receives onto localhost.
alias docker-host='_container_alias docker-host --cap-add=NET_ADMIN --cap-add=NET_RAW --network=volt_default qoomon/docker-host'
alias docker-postgres-ci='_container_alias docker-psql-ci -p 5433:5432 -p 5432:5432 docker.atl-paas.net/jira-cloud/postgres-ci:9.5'
## Run postgres in a docker container.
function docker-postgres()
{
	TAG="${1:-latest}"
	_container_alias "docker-postgres" -p 5433:5432 -p 5432:5432 "postgres:${TAG}"
}
alias docker-clock='_container_alias docker-clock --privileged alpine hwclock -s'
