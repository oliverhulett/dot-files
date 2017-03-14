#!/bin/bash -i

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

SUBLIME_INSTALL="${HOME}/opt/sublime_text_3"
proxy_setup

PROJ=
if [ $(command ls -1d .*.sublime-project 2>/dev/null | wc -l) -eq 1 -a -f .*.sublime-project ]; then
	PROJ="$(echo .*.sublime-project)"
elif [ $(command ls -1d *.sublime-project 2>/dev/null | wc -l) -eq 1 -a -f *.sublime-project ]; then
	PROJ="$(echo *.sublime-project)"
fi
if [ -n "${PROJ}" ]; then
	echo "Launching sublime_text with project: $(readlink -f "${PROJ}")"
	PROJ="--project ${PROJ%.sublime-project}"
else
	echo "Launching sublime_text with anonymous project"
fi

for cmd in echo exec; do
	$cmd "${SUBLIME_INSTALL}/sublime_text" $PROJ "$@"
done
