#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`

# pidof MarkLogic returns 2 pids - figure out the correct one...

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

# root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# default argument check
if [[ -z $1 ]]; then
	box_out 'Usage: ./ml-support-dump.sh [running time in seconds]' 'This script will run for the default 180 seconds' 'Please ensure sar is configured correctly'
fi

# global vars
TSTAMP=`date +"%H%M%S-%m-%d-%Y"`
INTERVAL=5
TIME=${1:-180}
PIDS=(`pidof MarkLogic`)
PID=${PIDS[1]}

# main
echo pstack script started at: ${green}`date`${reset} - running for \(approximately\) ${green}$TIME${reset} seconds on ${red}$OSTYPE${reset}. The MarkLogic pid is ${green}$PID${reset}
mkdir /tmp/$TSTAMP
# Debugging code..
#if [[ $OSTYPE == linux-gnu* ]]
#then
#    echo "Linux Detected"
#else
#    echo "Guessing this is a mac?"
#fi

# VM, IOStat and PMAP:
date | tee -a >> /tmp/$TSTAMP/pmap.log >> /tmp/$TSTAMP/iostat.log >> /tmp/$TSTAMP/vmstat.log

if [[ $OSTYPE == linux-gnu* ]]
then
    iostat 2 25 >> /tmp/$TSTAMP/iostat.log &
    vmstat 2 25 >> /tmp/$TSTAMP/vmstat.log &
    service MarkLogic pmap >> /tmp/$TSTAMP/pmap.log
else
    # OS X: vm_stat -c 25 2 iostat -c 25 2
    iostat -c 25 2 >> /tmp/$TSTAMP/iostat.log &
    vm_stat -c 25 2 >> /tmp/$TSTAMP/vmstat.log &
    # TODO - pmap for PSX?
fi

# for s in ${PIDS[@]}; do

# PStacks for MarkLogic process
while [ $TIME -gt 0 ]; do

    date | tee -a /tmp/$TSTAMP/pstack.log >> /tmp/$TSTAMP/pstack-summary.log
    if [[ $OSTYPE == linux-gnu* ]]
    then
        gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $PID | tee -a /tmp/$TSTAMP/pstack.log | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
        # TODO - OR service MarkLogic pstack?  Maybe check for presence of pstack??
    else
        lldb -o "thread backtrace all" --batch -p $PID | tee -a /tmp/$TSTAMP/pstack.log | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
    fi

	#pause and update stdout to show some progress
    sleep $INTERVAL
    echo -e ". \c"
    let TIME-=$INTERVAL
done
# PMAP For MarkLogic process
date | tee -a >> /tmp/$TSTAMP/pmap.log
service MarkLogic pmap >> /tmp/$TSTAMP/pmap.log
# SAR stats for host
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