# shellcheck shell=bash
# Add ~/.local/bin to the path.  It is where pip puts things you install when you run it without sudo.
if [ -e "${HOME}/.local/bin" ]; then
	# shellcheck disable=SC1090
	source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash-common.sh"
	PATH="$(prepend_path "${PATH}" "${HOME}/.local/bin")"
fi
if [ -d "/usr/local/opt/python/libexec/bin" ]; then
	# shellcheck disable=SC1090
	source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash-common.sh"
	PATH="$(prepend_path "${PATH}" "/usr/local/opt/python/libexec/bin")"
fi
# Add ~/opt/py{3,2.7}venv/bin to the path.  It is where I create my "global" python venv for systems that need these sorts of things.
function setpy2()
{
	deactivate 2>/dev/null
	# shellcheck disable=SC1090
	source "${HOME}/opt/py27venv/bin/activate"
}
alias setpy2.7=setpy2
alias setpy27=setpy2
function setpy3()
{
	deactivate 2>/dev/null
	# shellcheck disable=SC1090
	source "${HOME}/opt/py3venv/bin/activate"
}
