#!/usr/bin/env bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"

vim -c ":let @/='^\(<<<<<<<\||||||||\|=======\|>>>>>>>\)'" -c ":set hls" "$@"
