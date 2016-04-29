#!/bin/bash -x

sed -nre 's/^[ \t]+"(.+)": \{/\1/p' pins.json | xargs rm -rf

