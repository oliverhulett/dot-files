# shellcheck shell=bash
# Custom docker completion commands.

# Add remote images to the images output.
function __docker_remote_images()
{
	if [ -z "$(command which docker 2>/dev/null)" ]; then
		return
	fi
	local CACHE_FILE
	CACHE_FILE="/tmp/.docker-remote-images-$(whoami)"
	if [ -z "$(find "$CACHE_FILE" -mmin 60 -print 2>/dev/null)" ]; then
		docker search --no-trunc / | awk 'NR>1 { print $2 }' >"$CACHE_FILE"
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
