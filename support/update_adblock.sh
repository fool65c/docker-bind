#!/usr/bin/env bash

ADBLOCK_SOURCE='http://pgl.yoyo.org/adservers/serverlist.php?hostformat=bindconfig&showintro=0&mimetype=plaintext'
ADBLOCK_TEMP_FILE=/var/tmp/adblock
ADBLOCK_FILE=/etc/bind/named.conf.adblock
ADCLOCK_FILE_LIMIT=50

echo "Pulling adblock_source from ${ADBLOCK_SOURCE}"
curl -s $ADBLOCK_SOURCE |  sed 's/null.zone.file/\/var\/lib\/bind\/null.zone.file/g' > $ADBLOCK_TEMP_FILE

if [ $(wc -l $ADBLOCK_TEMP_FILE | cut -d\  -f1) -gt $ADCLOCK_FILE_LIMIT ]
	then
    mv $ADBLOCK_TEMP_FILE $ADBLOCK_FILE
  else
    echo "$ADBLOCK_TEMP_FILE only has $(wc -l $ADBLOCK_TEMP_FILE) lines" 
    exit 1
fi

echo "Checking to see if bind is running"
if [ $(ps -ewf | grep -v grep | grep -c bind) -eq 1 ]
  then
    echo "reloading bind"
    rndc reload
  else
    echo "bind not running skipping reload"
fi

echo "done updating"
