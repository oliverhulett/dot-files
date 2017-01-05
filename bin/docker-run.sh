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

TTY=
if [ -t 1 ]; then
	TTY="--tty=true --interactive=true"
fi
# Check if ssh agents are being used
[ -z $SSH_AUTH_SOCK ] && SSH_PASS_THROUGH="" || SSH_PASS_THROUGH="-v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
for cmd in echo ""; do
	$cmd docker run -u `id -u` -h `hostname` --cpu-shares=`nproc` --privileged --name=${NAME} \
		-v /etc/passwd:/etc/passwd:ro -v /etc/shadow:/etc/shadow:ro -v /etc/group:/etc/group:ro -v /etc/gshadow:/etc/gshadow:ro \
		-v /etc/sudo.conf:/etc/sudo.conf:ro -v /etc/sudoers:/etc/sudoers:ro -v /etc/sudoers.d:/etc/sudoers.d:ro -v /etc/pam.d:/etc/pam.d:ro \
		-v /etc/localtime:/etc/localtime:ro -v /var/run/docker.sock:/var/run/docker.sock $SSH_PASS_THROUGH \
		-v "${HOME}":"${HOME}" -v "`pwd`":"`pwd`" -w "`pwd`" --env-file=<(/usr/bin/env) \
		-v "$TMP":"$TMP" --entrypoint="$TMP" \
		--rm ${TTY} "${DOCKER_RUN_ARGS[@]}" \
		$IMAGE "$@"
done

