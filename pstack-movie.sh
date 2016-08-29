#!/bin/bash

# global vars
TSTAMP=`date +"%H%M%S-%m-%d-%Y"`
INTERVAL=5
TIME=${1:-180}
PIDS=(`pidof MarkLogic`)
PID=${PIDS[1]}

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`

function box_out()
{
    local s=("$@") b w
    for l in "${s[@]}"; do
    ((w<${#l})) && { b="$l"; w="${#l}"; }
    done
    echo -e "${yellow}╔═${b//?/═}═╗\n║ ${b//?/ } ║"
    for l in "${s[@]}"; do
    printf '║ %s%*s%s ║\n' "${blue}" "-$w" "$l" "${yellow}"
    done
    echo -e "║ ${b//?/ } ║\n╚═${b//?/═}═╝"
    tput sgr 0
}

function sar_collect()
{
    if [[ $OSTYPE == linux-gnu* ]]
    then
        # SAR stats for host (Linux)
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
    else
        # OSX Sar
        sar -A -o /tmp/$TSTAMP/sar-summary.log
    fi

}

# root check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# default argument check
if [[ -z $1 ]]; then
    box_out 'Usage: ./pstack-movie.sh [running time in seconds]' 'Version 1.1 (29th August 2016)' 'For OS X and Linux' 'This script will run for the default 180 seconds' 'Please ensure sar is configured correctly'
fi

# main
echo pstack script started at: ${green}`date`${reset} - running for \(approximately\) ${green}$TIME${reset} seconds. MarkLogic pid is ${green}$PID${reset}
mkdir /tmp/$TSTAMP

# VM, IOStat and PMAP:
date | tee -a >> /tmp/$TSTAMP/pmap.log >> /tmp/$TSTAMP/iostat.log >> /tmp/$TSTAMP/vmstat.log

if [[ $OSTYPE == linux-gnu* ]]
then
    echo -e "GNU/Linux Detected (${red}$OSTYPE${reset})"
    iostat 2 25 >> /tmp/$TSTAMP/iostat.log &
    vmstat 2 25 >> /tmp/$TSTAMP/vmstat.log &
    service MarkLogic pmap >> /tmp/$TSTAMP/pmap.log
    while [ $TIME -gt 0 ]; do
        service MarkLogic pstack | tee -a /tmp/$TSTAMP/pstack.log | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
        # OR you can use gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $PID
        sleep $INTERVAL
        echo -e ". \c"
        let TIME-=$INTERVAL
    done
    date | tee -a >> /tmp/$TSTAMP/pmap.log
    service MarkLogic pmap >> /tmp/$TSTAMP/pmap.log
    sar_collect
elif [[ $OSTYPE == darwin* ]]
then
    echo -e "Running on OS X (${red}$OSTYPE${reset})"
    # OS X: vm_stat -c 25 2 iostat -c 25 2
    hostinfo >> /tmp/$TSTAMP/hostinfo.log
    iostat -c 25 2 >> /tmp/$TSTAMP/iostat.log &
    vm_stat -c 25 2 >> /tmp/$TSTAMP/vmstat.log &
    # pmap for OS X:
    vmmap $PID >> /tmp/$TSTAMP/pmap.log
    while [ $TIME -gt 0 ]; do
        lldb -o "thread backtrace all" --batch -p $PID | tee -a /tmp/$TSTAMP/pstack.log | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
        # TODO - OR service MarkLogic pstack?  Maybe check for presence of pstack??
        sleep $INTERVAL
        echo -e ". \c"
        let TIME-=$INTERVAL
    done
    date | tee -a >> /tmp/$TSTAMP/pmap.log
    vmmap $PID >> /tmp/$TSTAMP/pmap.log
    # TODO - sar on OSX - it needs to be set up and tested on my mac...
else
    echo Sorry - not sure what OS you are using
    exit 1
fi

echo completed
echo `date`
# create zip
zip -9 -r /tmp/$TSTAMP.zip /tmp/$TSTAMP
echo /tmp/$TSTAMP.zip created