#!/bin/bash -e

IMAGES="$( (
	docker images | awk 'NR>1 { if ( $1 != "<none>" ) { print $1 } }'
	docker search --no-trunc docker-registry.aus.optiver.com/ | awk 'NR>1 { print $2 }'
) | sort -u)"
DOCKER_RUN_ARGS=()
while ! echo "$IMAGES" | grep -qw "$1" 2>/dev/null >/dev/null; do
	DOCKER_RUN_ARGS[${#DOCKER_RUN_ARGS}]="$1"
	shift
done
IMAGE="$1"
shift
if [ $# == 0 ]; then
	set -- /bin/bash
fi

# user specific container name
NAME=`basename $IMAGE`-`whoami`-`date "+%s"`
echo "Starting $NAME ($IMAGE)"
LABELS="$(docker inspect $IMAGE | jq '.[0].Config.Labels')"
# Use a docker container to do things
TMP="$(mktemp -p "${HOME}" -t ".$(date '+%Y%m%d-%H%M%S').docker.$(basename "$1").XXXXXXXXXX")"
trap 'echo "Leaving $NAME (${IMAGE})" && rm -fv ${TMP}' EXIT
command cat >"$TMP" <<-EOF
	#!/bin/bash -i
	export PROMPT_PREFIX="(docker:$(basename $IMAGE)) "
	source ~/.bashrc
	"\$@"
EOF
chmod u+x "$TMP"

for cmd in echo ""; do
	$cmd dockerme -h `hostname` --cpu-shares=`nproc` --privileged --name=${NAME} \
		-v /etc/sudo.conf:/etc/sudo.conf:ro -v /etc/sudoers:/etc/sudoers:ro -v /etc/sudoers.d:/etc/sudoers.d:ro -v /etc/pam.d:/etc/pam.d:ro -v /etc/localtime:/etc/localtime:ro \
		--env-file=<(/usr/bin/env) -v "$TMP":"$TMP" --entrypoint="$TMP" \
		"${DOCKER_RUN_ARGS[@]}" $IMAGE "$@"
done
