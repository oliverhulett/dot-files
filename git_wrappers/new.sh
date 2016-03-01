#!/bin/bash

for f in "$@"; do
	mkdir --parents "$(dirname "$f")" >/dev/null 2>/dev/null || true
done
touch "$@"

TMPFILE="$(mktemp)"
NOTICE="# Create template file.  This line will be removed."
echo "$NOTICE" >"$TMPFILE"
$VISUAL "$TMPFILE"
sed -re "1,1{/^${NOTICE}\$/d}" "$TMPFILE" -i

for f in "$@"; do
	if [ -f "$f" -a ! -s "$f" ]; then
		cp "$TMPFILE" "$f"
		git add -Nvf "$f" || rm -v "$f"
	fi
done

