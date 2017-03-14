#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

function testname()
{
	host="$(command ssh -o ConnectTimeout=2 -o PasswordAuthentication=no "${@}" hostname 2>/dev/null)"
	if [ -n "$host" ]; then
		echo $host
		exit 0
	fi
}

## Firstly, let's just try the string we were given...
testname "$*"

svrloc="sy"
svros="nx"
svrtyp="sr"
svrnum=
if [[ "$*" =~ ^([0-9]{1,4})$ ]]; then
	svrnum="$(printf '%04d' ${BASH_REMATCH[1]})"
elif [[ "$*" =~ ^([a-z]{2})([0-9]{1,4})$ ]]; then
	svrloc="${BASH_REMATCH[1]}"
	svrnum="$(printf '%04d' ${BASH_REMATCH[2]})"
elif [[ "$*" =~ ^([a-z]{2})([a-z]{2})([0-9]{1,4})$ ]]; then
	svrloc="${BASH_REMATCH[1]}"
	svrtyp="${BASH_REMATCH[2]}"
	svrnum="$(printf '%04d' ${BASH_REMATCH[3]})"
elif [[ "$*" =~ ^([a-z]{2})([a-z]{2})([a-z]{2})([0-9]{1,4})$ ]]; then
	svrloc="${BASH_REMATCH[1]}"
	svros="${BASH_REMATCH[2]}"
	svrtyp="${BASH_REMATCH[3]}"
	svrnum="$(printf '%04d' ${BASH_REMATCH[4]})"
fi
if [ -z "${svrnum}" ]; then
	echo >&2 "Bad server name pattern [<location>[[<os>]<type>]]<number>"
	echo >&2 "  That is, <number> is mandatory.  Between 1 and 4 numbers will be left zero padded."
	echo >&2 "  Two preceding letters are interpreted as the location (colo.)"
	echo >&2 "  Four preceding letters are interpreted as the location, then the type (sr, vm, etc.)"
	echo >&2 "  Six preceding letters are interpreted as the location, then os, then the type."
	exit 1
fi

target="op${svrloc}${svros}${svrtyp}${svrnum}"
testname "${target}"

echo >&2 "Target server does not exist or cannot be contacted."
echo >&2 "From your input '$*' I guessed you wanted: ${target}"
exit 1
