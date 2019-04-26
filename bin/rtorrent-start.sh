#!/usr/bin/env bash

/usr/bin/dtach -n /var/lib/rtorrent/fifo -e "^Q" /usr/bin/rtorrent
/bin/chmod g+rw /var/lib/rtorrent/fifo

