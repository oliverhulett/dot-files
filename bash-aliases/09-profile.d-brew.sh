# shellcheck shell=bash
## Source things from the brew prefix etc/ dir.
# shellcheck disable=SC1090

source "$(brew --prefix)/etc/bash_completion"
source "$(brew --prefix)/etc/profile.d"/*.sh
