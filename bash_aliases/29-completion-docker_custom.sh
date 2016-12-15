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
}

complete -F _docker_run_sh docker-run.sh
