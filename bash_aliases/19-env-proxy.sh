unset http_proxy_orig
unset https_proxy_orig

export NO_PROXY='comp.optiver.com,aus.optiver.com,127.0.0.1,localhost,git,srcsyd.comp.optiver.com,10.0.2.*,192.168.56.*'
export no_proxy="${NO_PROXY}"

SQUID_URL="sydsquid.aus.optiver.com"
SQUID_PORT=":3128"

PROXY_URL="sydproxy.comp.optiver.com"
PROXY_PORT=":8080"

LOCAL_PROXY_URL="localhost"
LOCAL_PROXY_PORT=":54321"
PROXY_CTRL_SOCK="${HOME}/.proxy-tunnel-ctl-sock"
PROXY_TUNNEL_DEST="${USER}@${USER}.devsrv"

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
	METHOD="squid"
	QUIET="n"
	for a in "$@"; do
		if id $a >/dev/null 2>/dev/null; then
			USER="$a"
			continue
		fi
		a="${a##-}"
		while [ -n "$a" ]; do
			p="$a"
			case $a in
				*h*)
					echo "proxy_setup [-h] [-q] [-s | -t | -p]"
					echo -e "\t-q  Quiet mode.  No questions, minimal output."
					echo -e "\t-s  Use sydsquid."
					echo -e "\t-p  Use sydproxy."
					echo -e "\t-t  Use sydproxy via an SSH tunnel."
					a="${a//h/}"
					return 0
					;;
				*q*)
					QUIET="y"
					a="${a//q/}"
					;;
				*s*)
					METHOD="squid"
					a="${a//s/}"
					;;
				*t*)
					METHOD="tunnel"
					a="${a//t/}"
					;;
				*p*)
					METHOD="proxy"
					a="${a//p/}"
					;;
			esac
			if [ "$p" == "$a" ]; then
				break
			fi
		done
	done
	echo "HTTP Proxy Method  : $METHOD"
	echo "HTTP Proxy Username: $USER"
	unset PASSWD
	if [ -r "${HOME}/etc/passwd" ]; then
		PASSWD="$(sed -ne '1p' "${HOME}/etc/passwd")"
		echo "HTTP Proxy Password: <from file: ${HOME}/etc/passwd>"
	elif [ "$QUIET" == "n" ]; then
		read -rs -p "HTTP Proxy Password: " PASSWD
		echo
	fi
	if [ -z "$PASSWD" -o -z "$USER" ]; then
		echo "Not setting proxy password, could not find from ${HOME}/etc/passwd and you told me not to ask"
		return 1
	fi
	if [ -z "${http_proxy_orig}" ]; then
		export http_proxy_orig="${http_proxy}"
	fi
	if [ -z "${https_proxy_orig}" ]; then
		export https_proxy_orig="${https_proxy}"
	fi
	if [ -e "${PROXY_CTRL_SOCK}" ]; then
		ssh -S "${PROXY_CTRL_SOCK}" -O exit ${PROXY_TUNNEL_DEST} EXIT
	fi
	if [ "$METHOD" == "tunnel" ]; then
		ssh -fNM -S "${PROXY_CTRL_SOCK}" -L ${LOCAL_PROXY_URL}${LOCAL_PROXY_PORT}:${PROXY_URL}${PROXY_PORT} ${PROXY_TUNNEL_DEST}
		HTTP_PROXY="http://${LOCAL_PROXY_URL}${LOCAL_PROXY_PORT}"
		HTTPS_PROXY="https://${LOCAL_PROXY_URL}${LOCAL_PROXY_PORT}"
	elif [ "$METHOD" == "proxy" ]; then
		HTTP_PROXY="http://${PROXY_URL}${PROXY_PORT}"
		HTTPS_PROXY="https://${PROXY_URL}${PROXY_PORT}"
	else # [ "$METHOD" == "squid" ]
		HTTP_PROXY="http://${SQUID_URL}${SQUID_PORT}"
		HTTPS_PROXY="https://${SQUID_URL}${SQUID_PORT}"
	fi
	export http_proxy="${HTTP_PROXY/\/\////$(urlencode "$USER"):$(urlencode "$PASSWD")@}"
	export HTTP_PROXY="${http_proxy}"
	export https_proxy="${HTTPS_PROXY/\/\////$(urlencode "$USER"):$(urlencode "$PASSWD")@}"
	export HTTPS_PROXY="${https_proxy}"
	if [ "$QUIET" == "n" ]; then
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
	fi
	unset PASSWD
	return 0
}

HISTIGNORE="${HISTIGNORE}:*//*@*proxy*optiver.com*"
export HISTIGNORE
