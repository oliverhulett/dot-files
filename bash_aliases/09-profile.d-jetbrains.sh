# shellcheck shell=bash
## Add IntelliJ and PyCharm command line tools to PATH
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash_common.sh"
export PATH="$(append_path "${PATH}" "/Applications/IntelliJ IDEA.app/Contents/bin")"
