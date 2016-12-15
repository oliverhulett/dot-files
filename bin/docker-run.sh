#!/bin/bash -x

IMAGES="$( (
	docker images | awk 'NR>1 { if ( $1 != "<none>" ) { print $1 } }'
	docker search --no-trunc docker-registry.aus.optiver.com/ | awk 'NR>1 { print $2 }'
) | sort -u)"
DOCKER_RUN_ARGS=()
while ! echo "$IMAGES" | grep -qw "$1" 2>/dev/null >/dev/null; do
	DOCKER_RUN_ARGS[${#DOCKER_RUN_ARGS}]="$1"
	shift
done
NAME="$1"
shift
if [ $# == 0 ]; then
	set -- /bin/bash
fi

LABELS="$(docker inspect $NAME | jq '.[0].Config.Labels')"
# Use a docker container to do things
TMP="$(mktemp -t "docker.$(basename "$1").XXXXXXXXXX")"
trap 'echo "Leaving ${NAME}" && rm -fv ${TMP}' EXIT
"$REAL_CAT" >"$TMP" <<-EOF
	#!/bin/bash
	export PROMPT_PREFIX="(docker:$(basename $NAME)) "
	source ~/.bashrc
	"\$@"
EOF
chmod u+x "$TMP"

TTY=
if [ -t 1 ]; then
	TTY="--tty=true --interactive=true"
fi
for cmd in echo ""; do
	$cmd docker run -u `id -u` -h `hostname` --cpu-shares=`nproc` \
		-v /etc/passwd:/etc/passwd -v /etc/shadow:/etc/shadow -v /etc/group:/etc/group -v /etc/gshadow:/etc/gshadow \
		-v /etc/sudo.conf:/etc/sudo.conf -v /etc/sudoers:/etc/sudoers -v /etc/sudoers.d:/etc/sudoers.d -v /etc/pam.d:/etc/pam.d \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v "${HOME}":"${HOME}" -v "`pwd`":"`pwd`" -w "`pwd`" --env-file=<(/usr/bin/env) \
		-v "$TMP":"$TMP" --entrypoint="$TMP" \
		--rm ${TTY} "${DOCKER_RUN_ARGS[@]}" \
		$NAME "$@"
done

