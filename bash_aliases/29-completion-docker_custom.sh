# Custom docker completion commands.

# Add remote images from docker-registry.aus.optiver.com/ to the images output.
function __docker_remote_images()
{
	if [ -z "$(command which docker 2>/dev/null)" ]; then
		return
	fi
	local CACHE_FILE="/tmp/.docker-remote-images-$USER"
	if ! find "$CACHE_FILE" -mmin 60 >/dev/null 2>/dev/null; then
		docker search --no-trunc docker-registry.aus.optiver.com/ | awk 'NR>1 { print $2 }' >"$CACHE_FILE"
	fi
	command cat "$CACHE_FILE" 2>/dev/null
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

complete -F _docker_run_sh dockerme putmein docker-run.sh

# cc-env uses a docker container to build things under centos 5

alias cc-env-build='cc-env ./build.py --output-dir=build/c5'
alias cc-env-build.py=cc-env-build

alias cc-env-inv='INVOKE_BUILD_ROOT="build/c5" cc-env inv'
alias cc-env-invoke='INVOKE_BUILD_ROOT="build/c5" cc-env inv'

alias dock=dock.sh
alias sdock=sdock.sh

complete -F _root_command cc-env dock.sh dock sdock.sh sdock
