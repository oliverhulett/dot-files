#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/dot-files/bash_aliases/39-aliases-opti_dev_aliases.sh"

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

proxy_exe "/optiver/bin/dockerme" "e377e9746adfa1f2d28b394e31e5f6e5"

function run()
{
	echo "$@"
	"$@" >/dev/tty 2>/dev/tty
	echo
}
run dockerme -h `hostname` --cpu-shares=`nproc` --privileged --name=${NAME} \
	-v /etc/sudo.conf:/etc/sudo.conf:ro -v /etc/sudoers:/etc/sudoers:ro -v /etc/sudoers.d:/etc/sudoers.d:ro -v /etc/pam.d:/etc/pam.d:ro -v /etc/localtime:/etc/localtime:ro \
	--env-file=<(/usr/bin/env) -v "$TMP":"$TMP" --entrypoint="$TMP" \
	"${DOCKER_RUN_ARGS[@]}" $IMAGE "$@"

proxy_exe "/optiver/bin/dockerme" "e377e9746adfa1f2d28b394e31e5f6e5"
