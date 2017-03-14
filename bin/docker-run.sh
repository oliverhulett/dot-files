#!/bin/bash -e

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

IMAGES="$( docker-list.sh | sort -u)"
DOCKER_RUN_ARGS=()
while ! echo "$IMAGES" | grep -qw "$1" 2>/dev/null >/dev/null; do
	DOCKER_RUN_ARGS[${#DOCKER_RUN_ARGS[@]}]="$1"
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
docker inspect $IMAGE | jq '.[0].Config.Labels' 2>/dev/null

# Use a docker container to do things
TMP="$(mktemp -p "${HOME}" -t ".$(date '+%Y%m%d-%H%M%S').docker.$(basename "$1").XXXXXXXXXX")"
trap 'ec=$?; echo && echo "Leaving $NAME (${IMAGE})" && echo "Ran: $@" && echo "Exit code: $ec" && rm -fv ${TMP}' EXIT
command cat >"$TMP" <<-EOF
	#!/bin/bash -i
	source ~/.bashrc
	export PS1="(docker:$(basename $IMAGE)) $PS1"
	"\$@"
EOF
chmod u+x "$TMP"

if [ "$(md5sum /optiver/bin/dockerme | cut -d' ' -f1)" != "454f54d2f74f62f9a51894cc8c41ecc0" ]; then
	echo "[WARN] /optiver/bin/dockerme has changed, you might have the wrong docker command.  Last hash was:  454f54d2f74f62f9a51894cc8c41ecc0"
	md5sum /optiver/bin/dockerme
fi

for cmd in echo ""; do
	$cmd dockerme -h `hostname` --cpu-shares=`nproc` --privileged --name=${NAME} \
		-v /etc/sudo.conf:/etc/sudo.conf:ro -v /etc/sudoers:/etc/sudoers:ro -v /etc/sudoers.d:/etc/sudoers.d:ro -v /etc/pam.d:/etc/pam.d:ro -v /etc/localtime:/etc/localtime:ro \
		--env-file=<(/usr/bin/env) -v "$TMP":"$TMP" --entrypoint="$TMP" \
		"${DOCKER_RUN_ARGS[@]}" $IMAGE "$@"
	echo
done

if [ "$(md5sum /optiver/bin/dockerme | cut -d' ' -f1)" != "454f54d2f74f62f9a51894cc8c41ecc0" ]; then
	echo "[WARN] /optiver/bin/dockerme has changed, you might have used the wrong docker command.  Last hash was: 454f54d2f74f62f9a51894cc8c41ecc0"
	md5sum /optiver/bin/dockerme
fi
