# Custom docker completion commands.

# Add remote images from docker-registry.aus.optiver.com/ to the images output.
function __docker_remote_images()
{
	local CACHE_FILE="/tmp/.docker-remote-images-$USER"
	if ! find "$CACHE_FILE" -mmin 60 >/dev/null 2>/dev/null; then
		docker search --no-trunc docker-registry.aus.optiver.com/ | awk 'NR>1 { print $2 }' >"$CACHE_FILE"
	fi
	/bin/cat "$CACHE_FILE" 2>/dev/null
}

# Wrap existing __docker_images() completion func in our own version that adds remote images.
eval "__original_$(declare -f __docker_images)"
function __docker_images()
{
	unalias grep 2>/dev/null >/dev/null
	(
		__original___docker_images "$@"
		__docker_remote_images
	) | sort -u
}

function _docker_run_sh()
{
	local cur prev words cword
	_get_comp_words_by_ref -n : cur prev words cword
	_docker_run
	if [ -z "${COMPREPLY[*]}" ]; then
		_root_command
	fi
}

complete -F _docker_run_sh dockerme putmein

# c5 uses a docker container to build things under centos 5

alias c5build='c5 ./build.py --output-dir=build/c5'
alias c5build.py=c5build

alias c5inv='INVOKE_BUILD_ROOT="build/c5" c5 inv'
alias c5invoke='INVOKE_BUILD_ROOT="build/c5" c5 inv'

alias virtualenv-2.6=virtualenv

alias dock=dock.sh
alias sdock=sdock.sh

complete -F _root_command c5 dock.sh dock sdock.sh sdock
