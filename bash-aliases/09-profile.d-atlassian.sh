# shellcheck shell=bash
# Things for the mac.
# shellcheck disable=SC2155,SC1090

# Alias gnu utils installed on the mac with homebrew to their usual names.
## Do we need to detect mac-ness?
## This should work on linux too (mostly it'll be a no-op, worst case it create some useless links)
## There is some risk that this doesn't happen early enough.  As long as it does eventually happen though, subsequent loads should work.
(
	for f in /usr/local/bin/g*; do
		g="$(basename -- "$f")"
		if [ "$g" != 'g[' ] && [ ! -e "/usr/local/bin/${g:1}" ]; then
			( cd /usr/local/bin/ && ln -s "$g" "${g:1}" 2>/dev/null )
		fi
	done
	# Doesn't work, for some reason.
	rm '/usr/local/bin/[' 2>/dev/null || true
) &

export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
export NVM_DIR="${HOME}/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

export ATLASSIAN_SCRIPTS="${HOME}/src/atlassian/atlassian-scripts/master"
if [ -d "${ATLASSIAN_SCRIPTS}" ]; then
	source "${ATLASSIAN_SCRIPTS}/sourceme.sh"
fi

if [ -e "${HOME}/.sdmake/complete/sdmake.completion.bash" ]; then
	source "${HOME}/.sdmake/complete/sdmake.completion.bash"
fi

if [ -e "${HOME}/.jmake/jmake2_completion" ]; then
	source "${HOME}/.jmake/jmake2_completion"
fi

export PATH="$(append_path "${PATH}" $(echo "${PATH}" | sed -re 's/:/ /g'))"

# Show metrics collected by volt.
export SHOW_DEVMETRICS=false
