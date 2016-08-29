 /tmp/$TSTAMP/pstack.log >> /tmp/$TSTAMP/pstack-summary.log
  
 service MarkLogic pstack | tee -a /tmp/$TSTAMP/pstack.log  | awk 'BEGIN { s = ""; } /^Thread/ { print s; s = ""; } /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } END { print s }' | sort | uniq -c | sort -r -n -k 1,1 >> /tmp/$TSTAMP/pstack-summary.log
