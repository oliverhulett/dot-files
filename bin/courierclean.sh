#!/bin/bash -x

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

sed -nre 's/^[ \t]+"(.+)": \{/\1/p' pins.json | xargs rm -rf
