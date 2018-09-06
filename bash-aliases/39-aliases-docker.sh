# shellcheck shell=bash
## Run docker-host; a container that dumps the network traffic it receives onto localhost.
alias docker-host='docker run --rm -d --name docker-host --cap-add=NET_ADMIN --cap-add=NET_RAW  qoomon/docker-host'
