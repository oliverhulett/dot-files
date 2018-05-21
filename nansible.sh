#!/bin/bash
## Not-an-ansible file.  To be run regularly, it will attempt to make the machine state match the decription (in related files)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${HERE}/lib/script-utils.sh"

reentrance_check
