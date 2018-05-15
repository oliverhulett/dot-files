# shellcheck shell=bash
## Add IntelliJ command line tools to PATH
# shellcheck disable=SC1090
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash_common.sh"
export PATH="$(append_path "${PATH}" "/Applications/IntelliJ_IDEA.app/Contents/bin")"
