#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

HERE="$(cd "$(dirname "$0")" && pwd -P)"

function error()
{
	echo $*
	exit 1
}

REPO_PATH="$(get-repo-dir.sh "$1" "$2" "$3")"
if [ -d "$REPO_PATH" ]; then
	shift 3
else
	REPO_PATH="$(get-repo-dir.sh "$1" "$2")"
	if [ -d "$REPO_PATH" ]; then
		shift 2
	else
		REPO_PATH="$(get-repo-dir.sh "$1")"
		if [ -d "$REPO_PATH" ]; then
			shift
		else
			error "Could not determine repository with which to work..."
		fi
	fi
fi

BRANCH="$(basename "$REPO_PATH")"
PROJ="$(basename "$(dirname "$REPO_PATH")")"
REPO_NAME="$(basename "$(dirname "$(dirname "$REPO_PATH")")")"

echo "Using repository: $REPO_NAME/$PROJ/$BRANCH"

PLACES=(
	"$REPO_PATH/images/el7-development"
	"$REPO_PATH/images/el7-devel"
	"$REPO_PATH/images/el7-dev"
	"$REPO_PATH/images/el7devel"
	"$REPO_PATH/images/el7dev"
	"$REPO_PATH/images/el7"

	"$REPO_PATH/images/c7-development"
	"$REPO_PATH/images/c7-devel"
	"$REPO_PATH/images/c7-dev"
	"$REPO_PATH/images/c7devel"
	"$REPO_PATH/images/c7dev"
	"$REPO_PATH/images/c7"

	"$REPO_PATH/images/el5-development"
	"$REPO_PATH/images/el5-devel"
	"$REPO_PATH/images/el5-dev"
	"$REPO_PATH/images/el5devel"
	"$REPO_PATH/images/el5dev"
	"$REPO_PATH/images/el5"

	"$REPO_PATH/images/c5-development"
	"$REPO_PATH/images/c5-devel"
	"$REPO_PATH/images/c5-dev"
	"$REPO_PATH/images/c5devel"
	"$REPO_PATH/images/c5dev"
	"$REPO_PATH/images/c5"

	"$REPO_PATH/images/development"
	"$REPO_PATH/images/devel"
	"$REPO_PATH/images/dev"

	"$REPO_PATH"

	"$HOME/dot-files/images/$REPO_NAME/$PROJ/$BRANCH"
	"$HOME/dot-files/images/$REPO_NAME/$PROJ"
)
for f in "${PLACES[@]}"; do
	if [ -f "$f/Dockerfile" -a -f "$f/Makefile" ]; then
		BASE_DOCKER="$(cd "$f" && make name)"
		break
	fi
done
if [ -z "$BASE_DOCKER" ]; then
	BASE_DOCKER="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' /usr/local/bin/cc-env | tail -n1)"
fi

echo "Using base docker image: $BASE_DOCKER"

function run()
{
	echo "$@"
	"$@" >/dev/tty 2>/dev/tty
	echo
}

set -e
set -x

MY_DOCKER="docker-registry.aus.optiver.com/olihul/tempdev/$REPO_NAME/$PROJ/$BRANCH"
if ! grep -qw "$MY_DOCKER" <(docker images) 2>/dev/null; then
	run docker build \
        --build-arg=HTTP_PROXY=$(HTTP_PROXY) \
        --build-arg=HTTPS_PROXY=$(HTTPS_PROXY) \
        --build-arg=NO_PROXY=$(NO_PROXY) \
		-t $MY_DOCKER - <<-EOF
			FROM $BASE_DOCKER

			RUN yum install -y konsole
		EOF
fi

run docker-run.sh -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/null:$HOME/repo/.metadata/.lock -v /optiver:/optiver --name="${REPO_NAME}.${PROJ}.${BRANCH}" $MY_DOCKER $HOME/opt/eclipse/eclipse
#sleep 20
#run docker exec "$REPO_NAME/$PROJ/$BRANCH" konsole -p Directory="$REPO_PATH"
set +x
