#!/usr/bin/env bash

#Source Locations
ADBLOCK_URL='http://pgl.yoyo.org/adservers/serverlist.php?hostformat=bindconfig&showintro=0&mimetype=plaintext'

#Minimum size file, to prevent issues
ADBLOCK_FILE_LIMIT=50

#########################
# fecth_adblock         #
#########################
fecth_adblock () {
  curl $1  | tr '[:upper:]' '[:lower:]' |  sed 's/null.zone.file/\/var\/lib\/bind\/null.zone.file/g' > $2
}

#########################
# Check file limit      #
#########################
check_file_limit () {
  echo "$1 has $(wc -l $1 | cut -d\  -f1) lines" 
  if [ $(wc -l $1 | cut -d\  -f1) -gt $2 ]
  then
    echo "$1 seems to be valid"
  else
    echo "ERROR: $1 seems to be invalid"
    exit 1
fi
}

#########################
# reload bind           #
#########################
reload_bind () {
  if [ $(ps -ewf | grep -v grep | grep -c bind) -eq 1 ]
    then
      echo "reloading bind"
      rndc reload
    else
      echo "bind not running skipping reload"
  fi
}

#########################
# cleanup               #
#########################
cleanup () {
  for file in "$@"
  do
    echo "Cleaning ${file}"
    rm -f ${file}
  done
}

#########################
# MAIN                  #
#########################
# Adblock temp stuff
ADBLOCK_TEMP_FILE=/var/tmp/adblock

#final location
ADBLOCK_FILE=/etc/bind/named.conf.adblock

echo "Pulling adblock_URL from ${ADBLOCK_URL}"
fecth_adblock ${ADBLOCK_URL} ${ADBLOCK_TEMP_FILE}

echo "Checking File limit"
check_file_limit ${ADBLOCK_TEMP_FILE} ${ADBLOCK_FILE_LIMIT}

echo "Moving to final location"
mv ${ADBLOCK_TEMP_FILE} ${ADBLOCK_FILE}

echo "Checking to see if bind is running"
reload_bind

echo "Cleaning up"
cleanup ${ADBLOCK_TEMP_FILE}

echo "done updating"
