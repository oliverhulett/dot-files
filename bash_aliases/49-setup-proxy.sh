if [ -e "${HOME}/.bash_aliases/19-env-proxy.sh" ] && ! echo "${HTTP_PROXY}" | grep -q "$(whoami)" 2>/dev/null; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup -qp >/dev/null 2>/dev/null
fi
