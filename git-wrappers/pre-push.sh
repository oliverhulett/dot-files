#!/bin/bash
if [ "$(git this)" == "master" ]; then
	./tests/run.sh tests/validate_dot-files.bats
fi
