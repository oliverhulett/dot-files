#!/bin/bash

unalias cat 2>/dev/null
unalias grep 2>/dev/null

for svr in $(cat ${HOME}/.ssh/known_hosts | grep -vE '^git' | cut -d' ' -f1 | cut -d, -f1); do
	ssh -o ConnectTimeout=2 $svr hostname
done

