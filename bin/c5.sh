#!/bin/bash

# Use a docker container to build things under c5
TMP="$(mktemp -t "docker.$(basename "$1").XXXXXXXXXX")"
trap 'rm -fv ${TMP}' EXIT
"$REAL_CAT" >"$TMP" <<-'EOF'
	#!/bin/bash
	## LESSOPEN does not work on c5 :(
	LESSOPEN=
	## el5-development wants a python26 virtualenv
	export PYVENV_HOME="${HOME}/py26venv"
	export PROMPT_PREFIX="(docker) "
	source ~/.bashrc
	"$@"
EOF
chmod u+x "$TMP"

TTY=
if [ -t 1 ]; then
	TTY="--tty=true --interactive=true"
fi
docker run -u `id -u`:`id -g` -h `hostname` --cpu-shares=`nproc` \
	-v /etc/passwd:/etc/passwd -v /etc/shadow:/etc/shadow -v /etc/group:/etc/group -v /etc/gshadow:/etc/gshadow \
	-v /etc/sudo.conf:/etc/sudo.conf -v /etc/sudoers:/etc/sudoers -v /etc/sudoers.d:/etc/sudoers.d -v /etc/pam.d:/etc/pam.d \
	-v /etc/distcc/hosts:/etc/distcc/hosts \
	-v ~/:`echo $HOME`/ -v `pwd`:/src -w /src --env-file=<(/usr/bin/env) \
	-v "$TMP":"$TMP" --entrypoint="$TMP" \
	${TTY} \
	docker-registry.aus.optiver.com/servicedelivery/el5-development "$@"

