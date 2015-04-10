#!/bin/bash

fileDate="/usr/local/bin/owping/outDate.txt"
fileTime="/usr/local/bin/owping/outTime.txt"
fileOpt="/usr/local/bin/owping/outOpt.txt"
date=$(cat "$fileDate")
time=$(cat "$fileTime")
opt=$(cat "$fileOpt")
fileList="/usr/local/bin/owping/pies.txt"
ls "/var/log/owlogs/" > $fileList
while read line           
do
    echo "$(/bin/sh /usr/local/bin/owping/owplot.sh $line -t $time -d $date -x $opt)"
done<$fileList
rm $fileList