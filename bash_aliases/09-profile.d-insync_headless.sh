NOT_STARTED_MSG="Insync doesn't seem to be running. Start it first."
STATUS="$(insync get_status 2>/dev/null)"
if [ -z "${STATUS}" -o "${STATUS}" == "${NOT_STARTED_MSG}" ]; then
	insync start --headless
fi

