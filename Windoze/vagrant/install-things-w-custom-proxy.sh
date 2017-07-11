#!/bin/bash
## Installs things into my VM...

USER="${1:-olihul}"
if [ -n "$2" ]; then
	HOME="$2"
else
	HOME="/home/${USER}"
fi

#source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/dot-files/bash_common.sh"
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

trap "" HUP

set +e

source "${HOME}/.bash_aliases/19-env-proxy.sh"
proxy_setup -qt ${USER}

echo
echo "Drone..."
TMPDIR="$(mktemp -d)"
( cd "${TMPDIR}" && \
	proxy_setup -qt ${USER} && \
	curl -sS http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx && \
	sudo install -t /usr/local/bin drone; \
	rm drone 2>/dev/null || true
)
rm -rf "${TMPDIR}"

echo
echo "ShellCheck..."
TMPDIR="$(mktemp -d)"
( cd "${TMPDIR}" && \
	HASKELL="https://haskell.org/platform/download/7.10.2/haskell-platform-7.10.2-a-unknown-linux-deb7.tar.gz" && \
	proxy_setup -qt ${USER} && echo "Fetching haskell..." && \
	wget --no-verbose --limit-rate=5m "${HASKELL}" && tar -xzvf "$(basename "${HASKELL}")" && \
	sudo ./install-haskell-platform.sh
	proxy_setup -qt ${USER} && echo "Updating cabal..." && \
	cabal update
	proxy_setup -qt ${USER} && echo "Fetching packages..." && \
	cabal fetch ShellCheck
	sudo cabal --config-file="${HOME}/.cabal/config" install --global --prefix=/usr/local ShellCheck
)
rm -rf "${TMPDIR}"

proxy_setup -q ${USER}
