# c5 uses a docker container to build things under centos 5

source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"
export PATH="$(prepend_path "/optitver/bin")"

alias c5build='c5 ./build.py --output-dir=build/c5'
alias c5build.py=c5build

alias c5inv='INVOKE_BUILD_ROOT="build/c5" c5 inv'
alias c5invoke='INVOKE_BUILD_ROOT="build/c5" c5 inv'

alias virtualenv-2.6=virtualenv

complete -F _root_command c5
