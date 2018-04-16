# shellcheck shell=bash
# Add ~/.local/bin to the path.  It is where pip puts things you install when you run it without sudo.
if [ -e "${HOME}/.local/bin" ]; then
	# shellcheck disable=SC1090
	source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash_common.sh"
	PATH="$(prepend_path "${PATH}" "${HOME}/.local/bin")"
fi
# Add ~/opt/pyvenv/bin to the path.  It is where I create my "global" python venv for systems that need these sorts of things.
if [ -e "${HOME}/opt/pyvenv/bin" ]; then
	# shellcheck disable=SC1090
	VIRTUAL_ENV_DISABLE_PROMPT="yes" source "${HOME}/opt/pyvenv/bin/activate"
fi
