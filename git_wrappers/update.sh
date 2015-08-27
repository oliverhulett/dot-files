#!/bin/bash

if [ -x ./git_setup.py ]; then
        ./git_setup.py -kq
fi
if [ -f ./deps.json ]; then
        courier
fi

