# shellcheck shell=bash

if [ -f "${HOME}/.local/venvs/pipsi/bin/aws_bash_completer" ]; then
	source "${HOME}/.local/venvs/pipsi/bin/aws_bash_completer"
elif [ -f "${HOME}/.local/bin/aws_bash_completer" ]; then
	source "${HOME}/.local/bin/aws_bash_completer"
fi
