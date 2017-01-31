export HTTP_PROXY='http://sydproxy.comp.optiver.com:8080'
export HTTPS_PROXY='http://sydproxy.comp.optiver.com:8080'

export NO_PROXY='*.comp.optiver.com,*.aus.optiver.com,127.0.0.1,localhost,srcsyd.comp.optiver.com,10.0.2.*,192.168.56.*'

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
	if [ $# == 1 ] && id $1 2>/dev/null; then
		USER="$1"
	fi
	echo "HTTP Proxy Username: $USER"
	if [ -r "${HOME}/etc/passwd" ]; then
		PASSWD="$(sed -ne '1p' "${HOME}/etc/passwd")"
		echo "HTTP Proxy Password: <from file: ${HOME}/etc/passwd>"
	else
		read -rs -p "HTTP Proxy Password: " PASSWD
		echo
	fi
	if [ -z "${http_PROXY_ORIG}" ]; then
		export http_PROXY_ORIG="${HTTP_PROXY}"
	fi
	if [ -z "${https_PROXY_ORIG}" ]; then
		export https_PROXY_ORIG="${HTTPS_PROXY}"
	fi
	export HTTP_PROXY="${HTTP_PROXY}"
	export HTTPS_PROXY="${HTTPS_PROXY}"
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

