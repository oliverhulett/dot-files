#!/bin/bash

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
	run ssh ${server} 'sh -c "(
		cd ${HOME} 2>/dev/null && git clone --recursive ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git dot-files 2>/dev/null;
		cd ${HOME}/dot-files 2>/dev/null && git pull && git submodule init && git submodule sync && git submodule update )"
	' || run rsync --delete -zpPXrogthlcm --exclude='.git' "${HOME}/dot-files/" ${server}:"${HOME}/dot-files/"
	run ssh ${server} '${HOME}/dot-files/setup-home.sh'
done
