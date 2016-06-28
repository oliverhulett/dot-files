# docker container to build things under c5
function c5()
{
	(
		source "/home/olihul/etc/dot-files/bash_aliases/profile.d-gcc-4.7.2.sh"
		export PATH="$(prepend_path "$GCC_PATH" "$GCC_LINX" "$CCACHE_PATH")"
		LD_LIBRARY_PATH="$GCC_LD_PATH:$(echo "$LD_LIBRARY_PATH" | sed -re "s!(^|:)$GCC_LD_PATH/?(:|$)!\1!")"
		export LD_LIBRARY_PATH
		docker run -u `id -u` -h `hostname` -v /etc:/etc -v ~/:`echo $HOME`/ -v `pwd`:/src -w /src --env-file=<(/usr/bin/env) --tty=true --interactive=true docker-registry.aus.optiver.com/servicedelivery/el5-development "$@"
	)
}

alias c5build.py='c5 ./build.py --output-dir=build_c5'

