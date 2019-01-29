#!/bin/bash

TIMER="time"
if [ -x "/usr/local/bin/time" ]; then
	TIMER="/usr/local/bin/time"
elif [ -x "/usr/bin/time" ]; then
	TIMER="/usr/bin/time"
fi

mkdir -p "${HOME}/.timings"
TIMINGS="${HOME}/.timings/$(date '+%Y%m%d')_$(whoami)_timings.log"

"$TIMER" --quiet --append --output "${TIMINGS}" -f  "

	%C
	CWD: $(pwd -P)
	Exit Code: %x
	Running Time: %E
	CPU: %P
	Mem: Max: %M  Ave: %t
	Disc: Major PF: %F Swaps: %W Waits: %w" "$@"
EXIT_CODE=$?

tail -n8 "${TIMINGS}"

exit ${EXIT_CODE}
