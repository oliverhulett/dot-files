# shellcheck shell=bash
## Useful svn environment setup.  Yes SWD still uses svn :(

function _svn_ps1()
{
	local root here
	here="$(pwd -P)"
	while [ "${here}" != "/" ]; do
		if [ -d "${here}/.svn" ]; then
			root="${here}"
		fi
		here="$(dirname "${here}")"
	done
	if [ -z "${root}" ]; then
		return
	fi
	local unversioned added_deleted changes conflicts locked
	for c in $(svn status -v "${root}" | cut -c1-7 | sort -u | command grep -v Perform); do
		case "${c[0]}" in
			'?' ) unversioned='%' ;;
			A | D ) added_deleted='+' ;;
			M | R ) changes='*' ;;
			C | '!' | '~' ) conflicts='X' ;;
		esac
		case "${c[1]}" in
			M ) changes='*' ;;
			c ) conflicts='X' ;;
		esac
		if [ "${c[2]}" == "L" ]; then
			locked='!'
		fi
		if [ "${c[3]}" == "L" ]; then
			added_deleted='+'
		fi
		if [ "${c[5]}" == "K" ]; then
			locked='!'
		fi
		if [ "${c[6]}" == "C" ]; then
			conflicts='X'
		fi
	done
	local hint
	hint="${unversioned}${added_deleted}${changes}${conflicts}${locked}"
	if [ -z "${hint}" ]; then
		hint='='
	fi
	echo -n " (${hint})"
}

if [ "$TERM" == "cygwin" ]; then
	export PROMPT_FOO="${PROMPT_FOO}"'\[\e[1;34m\]$(_svn_ps1 2>/dev/null)\[\e[0m\]'
else
	export PROMPT_FOO="${PROMPT_FOO}"'\[$(tput bold)\]\[$(tput setaf 4)\]$(_svn_ps1 2>/dev/null)\[$(tput sgr0)\]\[$(tput dim)\]'
fi
