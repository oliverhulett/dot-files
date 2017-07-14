#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
#source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${DOTFILES}/bash_common.sh" && eval "${setup_log_fd}" || true
source "${DOTFILES}/bash_aliases/39-aliases-opti_dev_aliases.sh"

set +e

IMAGES="$(docker-list.sh | sort -u)"
DOCKER_RUN_ARGS=()
while ! echo "$IMAGES" | grep -qE '^'"$1"'$' 2>/dev/null >/dev/null; do
	DOCKER_RUN_ARGS[${#DOCKER_RUN_ARGS[@]}]="$1"
	shift
done
IMAGE="$1"
shift
if [ $# == 0 ]; then
	set -- /bin/bash
fi

# user specific container name
NAME="$(basename -- "$IMAGE")-$(whoami)-$(date "+%s")"
echo "Starting $NAME ($IMAGE)"
docker inspect "$IMAGE" 2>&${log_fd} | jq '.[0].Config.Labels' 2>&${log_fd} || true

# Use a docker container to do things
TMP="$(mktemp -p "${HOME}" -t ".$(date '+%Y%m%d-%H%M%S').docker.$(basename -- "$1").XXXXXXXXXX")"
NODIR="$(mktemp -d)"
trap 'ec=$?; echo && echo "Leaving $NAME (${IMAGE})" && echo "Ran: $@" && echo "Exit code: $ec" && rm -fr "${TMP}" "${NODIR}"' EXIT
command cat >"$TMP" <<-EOF
	#!/bin/bash -i
	source ~/.bashrc
	export PS1="(docker:$(basename -- "$IMAGE")) $PS1"
	"\$@"
EOF
chmod u+x "$TMP"

proxy_exe "/optiver/bin/dockerme" "e377e9746adfa1f2d28b394e31e5f6e5"

function run()
{
	echo "$@"
	echo
	"$@"
	es=$?
	echo
	return $es
}
run dockerme -h "$(hostname)" --cpu-shares="$(nproc)" --privileged --name="${NAME}" \
	-v /etc/sudo.conf:/etc/sudo.conf:ro -v /etc/sudoers:/etc/sudoers:ro -v /etc/sudoers.d:/etc/sudoers.d:ro -v /etc/pam.d:/etc/pam.d:ro -v /etc/localtime:/etc/localtime:ro \
	--env-file=<(/usr/bin/env) -v "${TMP}:${TMP}" --entrypoint="$TMP" -v "${NODIR}:${HOME}/opt" \
	"${DOCKER_RUN_ARGS[@]}" "$IMAGE" "$@"
es=$?

proxy_exe "/optiver/bin/dockerme" "e377e9746adfa1f2d28b394e31e5f6e5"
exit $es
