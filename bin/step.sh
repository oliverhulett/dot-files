#!/usr/bin/env bash
## It should be possible to wrap a bash script in this script and use DEBUG trap to "step" through the given script.
## Say something like "About the run this command, continue y/n"
## In a more advanced version, we can allow the user to take control back, change the environment or run some more commands, then continue.
## In an even more advanced version we might be able to edit the sourced script on the fly, but maybe not.

# REF: https://stackoverflow.com/questions/40944532/bash-preserve-in-a-debug-trap
# REF: https://superuser.com/questions/847797/in-bash-processing-every-command-line-without-using-the-debug-trap

## Can I also use something like this to do dotlogs better?

# Idea; set up a DEBUG trap and assert that caller 0 is the script we expect it to be.
