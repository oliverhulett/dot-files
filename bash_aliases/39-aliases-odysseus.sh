function touchpad-off()
{
	xinput list
	TPID=$(xinput list | sed -nre 's_.+PS/2 Generic Mouse.+id=([0-9]+).+_\1_p')
	
	if [ -n "$TPID" ]; then
		xinput set-prop $TPID "Device Enabled" 0
	fi
}

function touchpad-on()
{
	xinput list
	TPID=$(xinput list | sed -nre 's_.+PS/2 Generic Mouse.+id=([0-9]+).+_\1_p')
	
	if [ -n "$TPID" ]; then
		xinput set-prop $TPID "Device Enabled" 1
	fi
}

