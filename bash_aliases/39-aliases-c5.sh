# c5.sh uses a docker container to build things under centos 5
complete -F _root_command c5

alias c5build='c5.sh ./build.py --output-dir=build/c5'
alias c5build.py=c5build

alias c5inv='INVOKE_BUILD_ROOT="build/c5" c5 inv'
alias c5invoke='INVOKE_BUILD_ROOT="build/c5" c5 inv'

