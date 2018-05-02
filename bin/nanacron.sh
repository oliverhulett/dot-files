#!/bin/bash
## Not-anacron.  The idea is that instead of having jobs in a person crontab directly, which in my case isn't the master anyway,
## I have a simple crontab that runs this script regularly and this script will manage running cron jobs on my machines, even
## if those machines are laptops that are not always on.
## The basic strategy follows that of anacron(1) where we keep track of when we last ran a job and when we should next run a job
## and do some funky stuff if we find that we've missed a run (either catch up or wait for the next one based on reasons.)
