# Aliases
source "${HOME}/dot-files/bash_common.sh"

alias lssc='lss --color=none'
alias lsc='lss --color=none'
alias lslc='lsl --color=none'
alias lsnc='lsn --color=none'
alias lsnl='lsn -l'
alias lsln='lsn -l'
alias lsnlc='lsnc -l'
alias lsncl='lsnc -l'
function lss
{
	#	List all with indicators, human readable sizes and no backups
	command ls -ABhF --color=always "$@"
}
function lsn
{
	#	No -A, No -B (-B implies -a)
	command ls -hF --color=always "$@"
}
function lsl
{
	#	With -l, No -B
	command ls -AlhF --color=always "$@"
}
alias ls='lss '

if uname -s | command grep -q 'MINGW' >/dev/null 2>&1 ; then
	alias cp='cp --preserve'
else
	alias cp='cp --preserve=all'
fi
alias sudo='sudo -E'
alias mount='mount -l'
alias sdiff='sdiff --strip-trailing-cr -bB'
alias diff='diff -wB'
alias time='/usr/bin/time'
alias chmod='chmod -c'
alias eject='eject -T'
alias file='file -krz'
alias top='top -c'
alias less='less -RFiMx4'
export LESS='-RFiMx4'

if uname -s | command grep -q 'MINGW' >/dev/null 2>&1 ; then
	alias ifconfig='ipconfig'
else
	alias ifconfig='sudo /sbin/ifconfig'
fi

GREP_ARGS=
GREP_ARGS_NC=
if uname -s | command grep -q 'MINGW' >/dev/null 2>&1 ; then
	# MINGW's version of grep doesn't support --exclude or --color.
	# There may be a better test, version for example.
	GREP_ARGS=
	GREP_ARGS_NC=
else
	GREP_ARGS="--exclude='.svn' --exclude='.git' --color=always"
	GREP_ARGS_NC="--exclude='.svn' --exclude='.git' --color=never"
fi
alias grep="command grep ${GREP_ARGS} -n"
alias ngrep="command grep ${GREP_ARGS_NC}"

alias rsync-a='rsync -zvpPAXrogthlm'
alias sursync-a='sudo rsync -zvpPAXrogthlm'
alias rsync-ca='rsync -zvpPAXrogthlcm'
alias sursync-ca='sudo rsync -zvpPAXrogthlcm'

alias iotop='sudo iotop'

alias umount='sudo umount'

alias fuser='sudo fuser -vau'

alias service='sudo service'

alias poweroff='sudo shutdown -hP'
alias powerdown='sudo shutdown -hP'
#alias restart='sudo shutdown -r'
alias reboot='sudo shutdown -r'

# Functions
# #########

unalias cat 2>/dev/null
function cat
{
	FIRST="yes"
	for f in "$@"; do
		if [ "$FIRST" = "no" ]; then
			echo >&2
			echo >&2
		fi
		FIRST="no"
		echo " >>> '$f' <<<" >&2
		echo >&2
		command cat "$f"
	done
}

unalias joinby 2>/dev/null
function joinby()
{
	d="$1"
	if [ ${#1} -eq 1 ]; then
		shift
	else
		d=","
	fi
	echo -n "$1"
	shift
	printf "%s" "${@/#/$d}"
}

unalias find_alias_or_fn 2>/dev/null
function find_alias_or_fn()
{
	(
		command grep -lR -E "^[^#]*\balias[[:space:]]+${arg}=" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
		command grep -lR -E "^[^#]*\bfunction[[:space:]]+${arg}[[:space:]]*(\\(\\))?" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
		command grep -lR -E "^[^#]*(\bfunction)?[[:space:]]+${arg}[[:space:]]*\\(\\)" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
	) | sort -u
}

unalias which 2>/dev/null
function which()
{
	for arg in "$@"; do
		if [ "${arg:0:1}" = "-" ]; then
			continue
		fi
		for suffix in "" ".sh" ".py"; do
			if type "${arg}${suffix}" 2>/dev/null; then
				arg="${arg}${suffix}"
				break
			fi
		done
		cmd="$arg"
		case `type -t "$arg" 2>/dev/null` in
			alias)
				alias "$arg"
				find_alias_or_fn "$arg"
				cmd="$(alias "$arg" | sed -re "s/^[^=]+=(.+)$/\1/;s/^["'"'"']//;s/["'"'"']$//;s/command //g;s/builtin //g;s/sudo //g;s/ +-[^ ]+//g") $cmd"
				;;
			keyword)
				;;
			function)
				find_alias_or_fn "$arg"
				;;
			builtin)
				;;
			*)
				;;
		esac
		echo
		commands=$(command which -a $(echo $cmd | tr ' ' '\n' | sort -u) 2>/dev/null)
		for bin in $commands; do
			while [ -n "$bin" ]; do
				if [ -e "$bin" ]; then
					ls -hl "$bin"
					file "$bin"
				fi
				newbin=$(readlink -n "$bin")
				if [ -z "$newbin" ]; then
					break
				fi
				if [ "${newbin:0:1}" != "/" ]; then
					newbin="$(dirname "$bin")/$newbin"
				fi
				bin="$newbin"
			done
			echo
		done
		if [ -z "$commands" ]; then
			command which "$@"
#			command_not_found_handle "$arg" 2>/dev/null
		fi
#		echo
	done
}
