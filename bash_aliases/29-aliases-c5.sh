# docker container to build things under c5
function c5()
{
	(
		TMP="$(mktemp -t "docker.$(basename "$1").XXXXXXXXXX")"
		real_cat >"$TMP" <<-'EOF'
			#!/bin/bash
			## LESSOPEN does not work on c5 :(
			LESSOPEN=
			## el5-development wants a python26 virtualenv
			export PYVENV_HOME="${HOME}/py6venv"
			export PROMPT_PREFIX="(docker) "
			source ~/.bashrc
			"$@"
		EOF
		chmod u+x "$TMP"

		docker run -u `id -u` -h `hostname` \
			-v /etc:/etc -v ~/:`echo $HOME`/ -v `pwd`:/src -w /src --env-file=<(/usr/bin/env) \
			-v "$TMP":"$TMP" --entrypoint="$TMP" \
			--tty=true --interactive=true \
			docker-registry.aus.optiver.com/servicedelivery/el5-development "$@"

		rm -fv "$TMP"
	)
}

alias c5build.py='c5 ./build.py --output-dir=build_c5'

