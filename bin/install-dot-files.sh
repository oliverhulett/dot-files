#!/bin/bash

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

if [ $# -eq 0 ]; then
	SERVERS=( $(ssh-ping.sh 2>/dev/null | sort -u) )
else
	SERVERS=( "$@" )
fi
FILES=( "${HOME}/.ssh/config" "${HOME}/.ssh/known_hosts" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/olihul_rsa" "${HOME}/.ssh/olihul_rsa.pub" "${HOME}/etc" )

function run()
{
	echo -e "$1\t$2\t${@:3}"
	"$@"
}

run dev-push-all.sh --delete "${SERVERS[@]/%/:}" "${FILES[@]}"

for server in "${SERVERS[@]}"; do
	command ssh ${server} 'git clone ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git ${HOME}/dot-files 2>/dev/null; cd ${HOME}/dot-files && git pull'
	command ssh ${server} 'test -d ${HOME}/dot-files/.git' || run rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${server}:"${HOME}/dot-files/"
	command ssh ${server} '${HOME}/dot-files/setup-home.sh'
	## TODO:  Special case for Vundle, copy if clone fails?  Or make sure vim and edt work without
done
