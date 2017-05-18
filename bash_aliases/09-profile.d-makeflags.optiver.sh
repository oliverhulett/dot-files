# Set global MAKEFLAGS at startup.  Optiver has a build farm, so we'll use that for starters.

export MAKEFLAGS="-j --load-average=7.5 --no-keep-going"
