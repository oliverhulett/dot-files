#!/bin/bash -x

source "${HOME}/dot-files/bash_common.sh"
eval "${capture_output}"

sed -nre 's/^[ \t]+"(.+)": \{/\1/p' pins.json | xargs rm -rf

