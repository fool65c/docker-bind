#!/usr/bin/env bash

#Source Locations
ADBLOCK_URL='http://pgl.yoyo.org/adservers/serverlist.php?hostformat=bindconfig&showintro=0&mimetype=plaintext'
HOSTFILE_URL='https://hosts-file.net/download/hosts.zip'

#Minimum size file, to prevent issues
ADBLOCK_FILE_LIMIT=50

#########################
# fecth_adblock         #
#########################
fecth_adblock () {
  curl $1  | tr '[:upper:]' '[:lower:]' |  sed 's/null.zone.file/\/var\/lib\/bind\/null.zone.file/g' > $2
}

#########################
# fetch_hosts           #
#########################
fecth_hosts () {
  #make the temp directory
  HOSTFILE_DIR=/var/tmp/host
  
  mkdir -p $HOSTFILE_DIR
  cd $HOSTFILE_DIR

  curl $1 > ${HOSTFILE_DIR}/temp.zip
  unzip ${HOSTFILE_DIR}/temp.zip

  echo "turning host file into bind file"
  process_hosts ${HOSTFILE_DIR}/hosts.txt ${2}
  
  cd ~
  rm -rf $HOSTFILE_DIR
}

#########################
# process_hosts         #
# converts host file    #
# into bind format      #
#########################
process_hosts () {
  cat /dev/null > $2
  START_LOCATION=$(grep -m1 -n "BAD HOSTS BEGIN HERE" ${1} | cut -d: -f1)
  for domain in $(tail -n+${START_LOCATION} ${1} | grep -v -e \# -e '\.$' | cut -d$'\t' -f2)
  do
      # tdomain=$(echo ${domain//[$'\t\r\n']})
      # tdomain=$(echo ${domain//[$'\t\r\n']} | awk '{print tolower($0)}')
      # printf "zone \"%s\" { type master; notify no; file \"/var/lib/bind/null.zone.file\"; };\n" $tdomain >> $2
      printf "zone \"%s\" { type master; notify no; file \"/var/lib/bind/null.zone.file\"; };\n" ${domain//[$'\t\r\n']} >> $2
  done
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

# Hostfile temp stuff
HOSTFILE_LOCATION=/var/tmp/hosts_adblock

#Temp files and final location
COMBINED_TEMP_FILE=/var/tmp/named.conf.adblock
ADBLOCK_FILE=/etc/bind/named.conf.adblock

echo "Pulling adblock_URL from ${ADBLOCK_URL}"
fecth_adblock ${ADBLOCK_URL} ${ADBLOCK_TEMP_FILE}

echo "Pulling hosts source from ${HOSTFILE_URL}"
fecth_hosts ${HOSTFILE_URL} ${HOSTFILE_LOCATION}

echo "Merging sources for blocked files"
cat ${ADBLOCK_TEMP_FILE} ${HOSTFILE_LOCATION} | sort -f | uniq -i > $COMBINED_TEMP_FILE

echo "Checking File limit"
check_file_limit ${COMBINED_TEMP_FILE} ${ADBLOCK_FILE_LIMIT}

echo "Moving to final location"
mv ${COMBINED_TEMP_FILE} ${ADBLOCK_FILE}

echo "Checking to see if bind is running"
reload_bind

echo "Cleaning up"
cleanup ${HOSTFILE_LOCATION} ${ADBLOCK_TEMP_FILE} ${COMBINED_TEMP_FILE}

echo "done updating"
