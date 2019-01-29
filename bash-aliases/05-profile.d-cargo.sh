# shellcheck shell=bash
# Add ~/.cargo/bin to the path.
if [ -e "${HOME}/.cargo/bin" ]; then
	# shellcheck disable=SC1090
	source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash-common.sh"
	PATH="$(prepend_path "${PATH}" "${HOME}/.cargo/bin")"
fi
