#!/bin/bash
####################################################################################################
##	Disc tweaks for VMs with lots of memory.
##
##	Linux to the rescue again!  Heavy users of their VM (that is, users who make heavy use of their
##	VM, I'm not wanting to cast aspersions on anyone's weight.) will probably have a similar set up
##	to me.
##	I have the original root partition on my physical SSD, a larger data partition on my physical
##	spinning disc HDD and a whole lot of RAM allocated to the VM.  The majority of my workload is
##	compiling source code from and writing object files to the spinning HDD partition, because that
##	is the partition with all the space.

function proc_set()
{
	if [ $# -eq 2 ]; then
		echo "Setting $1: $2  (was $(cat "$1"))"
	fi
	echo $2 >"$1"
}

## Factory settings
# proc_set /proc/sys/vm/dirty_writeback_centisecs 500
# proc_set /proc/sys/vm/dirty_expire_centisecs 3000
# proc_set /proc/sys/vm/dirty_ratio 40
# proc_set /proc/sys/vm/dirty_background_ratio 10

##	Do things
proc_set /proc/sys/vm/dirty_writeback_centisecs 60000
proc_set /proc/sys/vm/dirty_expire_centisecs 3000
proc_set /proc/sys/vm/dirty_ratio 90
proc_set /proc/sys/vm/dirty_background_ratio 90
proc_set /proc/sys/vm/swappiness 100
