#!/usr/bin/env bash

set -x
set -e

for c in fingerprint replaygain acousticbrainz mbsync lyrics absubmit fetchart submit update move; do
	beet "$c"
done
