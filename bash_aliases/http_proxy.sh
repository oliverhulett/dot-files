export HTTP_PROXY='http://sydproxy.comp.optiver.com:8080'
export HTTPS_PROXY='https://sydproxy.comp.optiver.com:8080'
export http_proxy="${HTTP_PROXY}"
export https_proxy="${HTTPS_PROXY}"

export NO_PROXY='*.comp.optiver.com,*.aus.optiver.com,127.0.0.1,localhost,srcsyd.comp.optiver.com'
export no_proxy="${NO_PROXY}"

proxy_setup ()
{
	echo "Username: $USER";
	read -rs -p "Password: " PASSWD;
	echo;
	if [ -z "${http_proxy_orig}" ]; then
		export http_proxy_orig="${http_proxy}"
	fi
	if [ -z "${https_proxy_orig}" ]; then
		export https_proxy_orig="${https_proxy}"
	fi
	export http_proxy="${http_proxy_orig/\/\////$USER:$PASSWD@}"
	export HTTP_PROXY="${http_proxy}"
	export https_proxy="${https_proxy_orig/\/\////$USER:$PASSWD@}"
	export HTTPS_PROXY="${https_proxy}"
	unset PASSWD
}

HISTIGNORE="${HISTIGNORE}:*//*@*proxy*optiver.com*"
export HISTIGNORE

