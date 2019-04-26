#!/usr/bin/env bash
# Kodi stuff.
## Make sure you set kodi in /etc/hosts

METHOD="$1"
shift
ARGS=""
DEL=""
for a in "$@"; do
	if [ "${DEL}" == ":" ]; then
		ARGS="${ARGS}${DEL} $a"
		DEL=","
	else
		ARGS="${ARGS}${DEL} '$a'"
		DEL=":"
	fi
done
ARGS="$(echo $ARGS | tr "'" '"')"
DATA='{ "jsonrpc": "2.0", "id": "mybash", "method": "'"${METHOD}"'", "params": { '"${ARGS}"' } }'
echo "$DATA"
curl --data-binary "${DATA}" -H 'content-type: application/json;' http://loki:8080/jsonrpc | python -m json.tool

