export HTTP_PROXY='http://sydproxy.comp.optiver.com:8080'
export HTTPS_PROXY='https://sydproxy.comp.optiver.com:8080'
export http_proxy="${HTTP_PROXY}"
export https_proxy="${HTTPS_PROXY}"

export NO_PROXY='*.comp.optiver.com,*.aus.optiver.com,127.0.0.1,localhost,srcsyd.comp.optiver.com,10.0.2.*,192.168.56.*'
export no_proxy="${NO_PROXY}"

function urlencode()
{
	local string="${1}"
	local strlen=${#string}
	local encoded=""

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9] )
				o="${c}" ;;
			* )
				printf -v o '%%%02x' "'$c"
		esac
		encoded+="${o}"
	done
	echo "${encoded}"
}

function urldecode()
{
	# This is perhaps a risky gambit, but since all escape characters must be
	# encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
	# will decode hex for us

	printf '%b' "${1//%/\\x}"
}

function proxy_setup()
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
	export http_proxy="${http_proxy_orig/\/\////$(urlencode "$USER"):$(urlencode "$PASSWD")@}"
	export HTTP_PROXY="${http_proxy}"
	export https_proxy="${https_proxy_orig/\/\////$(urlencode "$USER"):$(urlencode "$PASSWD")@}"
	export HTTPS_PROXY="${https_proxy}"
	update_config=""
	for f in /etc/sysconfig/docker; do
		if [ -e "$f" ]; then
			if grep -qE "^HTTPS?_PROXY=" "$f"; then
				if ! grep -qF "HTTP_PROXY=$HTTP_PROXY" "$f" || ! grep -qF "HTTPS_PROXY=$HTTPS_PROXY" "$f"; then
					update_config="$update_config $f"
				fi
			fi
		fi
	done
	if [ -n "$update_config" ]; then
		read -n1 -r -p "Found configuration files to update with new proxy.  Update $update_config? [Y/n] "
		echo
		if [ $(echo $REPLY | tr '[a-z]' '[A-Z]') != "N" ]; then
			for f in $update_config; do
				sudo -E sed -re 's!^HTTP_PROXY=.+$!HTTP_PROXY='"$HTTP_PROXY"'!' "$f" -i
				sudo -E sed -re 's!^HTTPS_PROXY=.+$!HTTPS_PROXY='"$HTTPS_PROXY"'!' "$f" -i
			done

			echo "System configuration updated for new proxy, you may want to restart daemons.  Try:"
			echo "$ sudo systemctl reload <services>"
		fi
	fi
	unset PASSWD
}

HISTIGNORE="${HISTIGNORE}:*//*@*proxy*optiver.com*"
export HISTIGNORE

