# pstack-cross-platform

Allows the generation of pstack movies for Linux or OS X.

TODO - validate steps from clean installations in both cases.

## Setup (Linux [RHEL / CentOS])

Install the sysstat package

```bash
sudo yum -y install sysstat
```

Enable sysstat at startup and start the service

```bash
chkconfig sysstat on && service sysstat start
```

Edit the crontab (sudo crontab -e) or:

```bash
sudo vi /etc/cron.d/sysstat
```

Add the following

```bash
*/10 * * * * root /usr/local/lib/sa/sa1 1 1
53 23 * * * root /usr/local/lib/sa/sa2 -A
```

## Setup (OS X)

Configure SAR:

```bash
sudo crontab -e
```

Add the following lines:

```bash
# run system activity accounting tool every 10 minutes
*/10 * * * * /usr/lib/sa/sa1 1 1
# generate a daily summary of process accounting at 23:53
53 23 * * * /usr/lib/sa/sa2 -A
```

## Running

```bash
sudo ./pstack-movie.sh
```

By default the script will run for 3 minutes (180 seconds) - you can pass in a different duration as the first argument

### Sample output

```bash
﻿╔════════════════════════════════════════════════════════╗
║                                                        ║
║ Usage: ./pstack-movie.sh [running time in seconds]     ║
║                                                        ║
║ Version 1.1 (29th August 2016) for OS X and Linux      ║
║ This script will run for the default 180 seconds       ║
║ Please ensure sar is configured correctly on your host ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
Script started on localhost.localdomain at: Mon 29 Aug 08:37:01 BST 2016 - running for (approximately) 180 seconds. MarkLogic pid is 1572
GNU/Linux Detected (linux-gnu)
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . completed
Mon 29 Aug 08:40:27 BST 2016
  adding: tmp/083701-08-29-2016/ (stored 0%)
  adding: tmp/083701-08-29-2016/pmap.log (deflated 91%)
  adding: tmp/083701-08-29-2016/iostat.log (deflated 94%)
  adding: tmp/083701-08-29-2016/vmstat.log (deflated 77%)
  adding: tmp/083701-08-29-2016/pstack-summary.log (deflated 98%)
  adding: tmp/083701-08-29-2016/pstack.log (deflated 99%)
  adding: tmp/083701-08-29-2016/sar-summary.log (deflated 90%)
/tmp/083701-08-29-2016.zip created
```