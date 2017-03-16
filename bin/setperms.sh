#!/bin/bash

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

for dir in "$@"; do
	echo "$dir"
	find "$dir" -xdev -type d -print0 | xargs -t0 -n4 nice ionice -c3 setfacl -d -m u::rwx,m:rwx
	find "$dir" -xdev -type d -print0 | xargs -t0 -n4 nice ionice -c3 setfacl -d -m g::rwx,m:rwx
	find "$dir" -xdev -type d -print0 | xargs -t0 -n4 nice ionice -c3 chmod g+rwxs,u+rwx
	find "$dir" -xdev -type f -print0 | xargs -t0 -n4 nice ionice -c3 chmod g+rw,u+rw
done
