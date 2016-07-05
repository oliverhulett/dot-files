# Aliases
source "${HOME}/etc/dot-files/bash_common.sh"

get_real_exe ls >/dev/null
get_real_exe grep >/dev/null

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
	$REAL_LS -ABhF --color=always "$@"
}
function lsn
{
	#	No -A, No -B (-B implies -a)
	$REAL_LS -hF --color=always "$@"
}
function lsl
{
	#	With -l, No -B
	$REAL_LS -AlhF --color=always "$@"
}
alias ls='lss '

if uname -s | real_grep -q 'MINGW' >/dev/null 2>&1 ; then
	alias cp='cp --preserve'
else
	alias cp='cp --preserve=all'
fi
alias mount='mount -l'
alias sdiff='sdiff --strip-trailing-cr -bB'
alias diff='diff -w'
alias time='/usr/bin/time'
alias chmod='chmod -c'
alias eject='eject -T'
alias file='file -krz'
alias top='top -c'
alias less='less -RFiMx4'
export LESS='-RFiMx4'

if uname -s | real_grep -q 'MINGW' >/dev/null 2>&1 ; then
	alias ifconfig='ipconfig'
else
	alias ifconfig='sudo /sbin/ifconfig'
fi

GREP_ARGS=
GREP_ARGS_NC=
if uname -s | real_grep -q 'MINGW' >/dev/null 2>&1 ; then
	# MINGW's version of grep doesn't support --exclude or --color.
	# There may be a better test, version for example.
	GREP_ARGS=
	GREP_ARGS_NC=
else
	GREP_ARGS="--exclude='.svn' --exclude='.git' --color=always"
	GREP_ARGS_NC="--exclude='.svn' --exclude='.git' --color=never"
fi
alias grep="$REAL_GREP ${GREP_ARGS} -n"
alias ngrep="$REAL_GREP ${GREP_ARGS_NC}"

alias rsync-a='rsync -zvpPAXrogthlm'
alias sursync-a='sudo rsync -zvpPAXrogthlm'
alias rsync-ca='rsync -zvpPAXrogthlcm'
alias sursync-ca='sudo rsync -zvpPAXrogthlcm'

alias syslog='tail -f /var/log/syslog'

alias iotop='sudo iotop'

alias nfsmnt='sudo mount -t nfs4 -o soft,retry=2,retrans=5,timeo=180'
alias smbmnt='sudo mount -t cifs -o users,rw,noexec,async,guest'
alias umount='sudo umount'

alias fuser='sudo fuser -vau'

alias poweroff='sudo shutdown -hP'
alias powerdown='sudo shutdown -hP'
#alias restart='sudo shutdown -r'
alias reboot='sudo shutdown -r'

# Functions
# #########

unalias table 2>/dev/null
#function table
#{
#	filename="-"
#	for f in "$@"; do
#		if [ -f "$f" ]; then
#			filename="$f"
#			break
#		fi
#	done
#	head -1 "$filename"
#	"$@"
#}

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
		$REAL_CAT "$f"
	done
}

unalias find_alias_or_fn 2>/dev/null
function find_alias_or_fn()
{
	(
		real_grep -lR -E "^[^#]*\balias[[:space:]]+${arg}=" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/etc/dot-files/bash_common.sh
		real_grep -lR -E "^[^#]*\bfunction[[:space:]]+${arg}[[:space:]]*(\\(\\))?" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/etc/dot-files/bash_common.sh
		real_grep -lR -E "^[^#]*(\bfunction)?[[:space:]]+${arg}[[:space:]]*\\(\\)" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/etc/dot-files/bash_common.sh
	) | sort -u
}

unalias which 2>/dev/null
function which()
{
	for arg in "$@"; do
		if [ "${arg:0:1}" = "-" ]; then
			continue
		fi
		echo $arg
		type "$arg" 2>/dev/null
		cmd="$arg"
		case `type -t "$arg" 2>/dev/null` in
			alias)
				alias "$arg"
				find_alias_or_fn "$arg"
				cmd="$cmd $(alias "$arg" | sed -re "s/^[^=]+='(.+)'$/\1/;s/sudo //g;s/ +-[^ ]+//g")"
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
		commands=$($REAL_WHICH -a $cmd 2>/dev/null | uniq)
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
#		if [ -z "$commands" ]; then
#			command_not_found_handle "$arg" 2>/dev/null
#		fi
		echo
	done
}

