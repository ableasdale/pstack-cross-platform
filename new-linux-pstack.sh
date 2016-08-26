#!/bin/bash

# root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# default argument check
if [[ -z $1 ]]; then
	echo Usage: ./ml-support-dump.sh \[running time in seconds\]
	echo e.g. ./ml-support-dump.sh 180 \(runs the application for 3 minutes before closing\)
	exit 1
fi

# global vars
TSTAMP=`date +"%H%M%S-%m-%d-%Y"`
INTERVAL=7 TIME=$1

# main
echo pstack script started at: $TSTAMP - running for approximately $TIME seconds
echo `date`
mkdir /tmp/$TSTAMP

while [ $TIME -gt 0 ]; do
	date | tee -a /tmp/$TSTAMP/pstack.log >> /tmp/$TSTAMP/pstack-summary.log >> /tmp/$TSTAMP/pmap.log >> /tmp/$TSTAMP/iostat.log >> /tmp/$TSTAMP/vmstat.log
	iostat 2 5 >> /tmp/$TSTAMP/iostat.log &
    vmstat 2 5 >> /tmp/$TSTAMP/vmstat.log &
	service MarkLogic pstack | tee -a /tmp/$TSTAMP/pstack.log | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
    service MarkLogic pmap >> /tmp/$TSTAMP/pmap.log
	#pause and update stdout to show some progress
    sleep $INTERVAL
    echo -e ". \c"
    let TIME-=$INTERVAL
done
echo "CPU statistics [sar -u ALL]" >> /tmp/$TSTAMP/sar-summary.log
sar -u ALL >> /tmp/$TSTAMP/sar-summary.log
echo "CPU individual core statistics [sar -P ALL]" >> /tmp/$TSTAMP/sar-summary.log
sar -P ALL >> /tmp/$TSTAMP/sar-summary.log
echo "Block device statistics [sar -b]" >> /tmp/$TSTAMP/sar-summary.log
sar -b >> /tmp/$TSTAMP/sar-summary.log
echo "Paging activity [sar -B]" >> /tmp/$TSTAMP/sar-summary.log
sar -B >> /tmp/$TSTAMP/sar-summary.log
echo "Swap statistics [sar -S]" >> /tmp/$TSTAMP/sar-summary.log
sar -S >> /tmp/$TSTAMP/sar-summary.log
echo "Memory use statistics [sar -r]" >> /tmp/$TSTAMP/sar-summary.log
sar -r >> /tmp/$TSTAMP/sar-summary.log
echo "Device statistics [sar -d]" >> /tmp/$TSTAMP/sar-summary.log
sar -d >> /tmp/$TSTAMP/sar-summary.log
echo "Process switching [sar -w]" >> /tmp/$TSTAMP/sar-summary.log
sar -w >> /tmp/$TSTAMP/sar-summary.log
echo "Process queues [sar -q]" >> /tmp/$TSTAMP/sar-summary.log
sar -q >> /tmp/$TSTAMP/sar-summary.log
echo "Network statistics [sar -n ALL]" >> /tmp/$TSTAMP/sar-summary.log
sar -n ALL >> /tmp/$TSTAMP/sar-summary.log
echo completed
echo `date`
# create zip
zip -9 -r /tmp/$TSTAMP.zip /tmp/$TSTAMP
echo /tmp/$TSTAMP.zip created