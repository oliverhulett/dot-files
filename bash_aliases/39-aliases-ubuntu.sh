# shellcheck shell=bash
# Ubuntu specific things.

alias service='sudo service'
alias aptitude='sudo aptitude -vPDZW'
alias xapt='sudo xapt --keep-cache'
alias apt-file='sudo apt-file -x'
alias apt-cache='sudo apt-cache'

function apt-get-keys()
{
	TMPFILE=`mktemp`
	echo "$TMPFILE"
	aptitude update >"$TMPFILE" 2>&1
	sed -rne 's/.+NO_PUBKEY ([0-9A-F]+)/\1/p' "$TMPFILE" | xargs sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
	rm -vf -- "$TMPFILE"
	aptitude update
}

function unity-reset()
{
	MACH=`hostname -s`
	USER=`whoami`

	nohup unity --reset 2>&1 >/dev/null &

	echo
	for i in `seq 1 10`; do
		echo -n .
		sleep 10
	done
	echo

	gconftool --load "${HOME}/etc/${MACH}-${USER}.gconf.xml"
}

function unity-save()
{
	MACH=`hostname -s`
	USER=`whoami`

	gconftool --dump / >"${HOME}/etc/${MACH}-${USER}.gconf.xml"
}

