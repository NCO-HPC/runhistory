#!/bin/sh

#  This script checks if the file with name constructed out of
#  $1 and $2 is contained in the run_history log file $LOGrunhistory
#  exit code of 0 means the file exists.

set -x

if [ $# -ne 2 ]
then
  echo "This scripts requires exactly two arguments"
  exit 1
fi 

[[ $READ_LOG_DIR != "YES" ]] && exit 2

str1=`echo $1|sed s:/:_:g`
str2=$2
file="${str1}__${str2}"

if [ -e $LOGrunhistory/$file ] ; then
    ls -l $LOGrunhistory/$file
    exit 0
else
    exit 3
fi
