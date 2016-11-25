#!/bin/bash
 
BASE_URL="http://optic.aus.optiver.com/api/v2/applications"
REMOTE_HOST_LIST=`wget -q -O /dev/stdout $BASE_URL/$1`
REMOTE_HOST_COUNT=`echo $REMOTE_HOST_LIST | wc -l`
 
if [ $REMOTE_HOST_COUNT -eq 0 -o "$REMOTE_HOST_LIST" == "" ] ; then
	echo 'Unable to find host for process '\'$1\'
elif [ $REMOTE_HOST_COUNT -eq 1 ] ; then
	COLO=`echo $REMOTE_HOST_LIST | jq .colo.title | tr -d '"'`
	HOST=`echo $REMOTE_HOST_LIST | jq .host.title | tr -d '"'`
	if [ "$COLO" == "bi" ] ; then
		echo 'Unable to jump to host for bi process '\'$1\'
		exit 0
	fi
	#SSH_COLO=central-archive.aus.optiver.com
	#LOG_PATH=/data/dataservices/$COLO/$HOST.aus.optiver.com
	SSH_COLO="${COLO}_logs_today"
	LOG_PATH="/data/logsync/log/$COLO/$HOST.aus.optiver.com"
	#exec ssh -t $SSH_COLO /usr/local/bin/apps/logless.py "$LOG_PATH/$1.log"
	echo "Opening log file: ${SSH_COLO}:${LOG_PATH}/$1.log"
	exec "$(dirname "$0")/ssh.sh" -t $SSH_COLO less "$LOG_PATH/$1.log"
else
	echo 'Multiple hosts found: '
	echo $REMOTE_HOST_LIST
fi

