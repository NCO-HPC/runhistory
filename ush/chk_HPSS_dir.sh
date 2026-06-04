#!/bin/sh

# chk_HPSS_dir.sh: check and create list of directories under specified
# HPSS directory

set +x

echo "`date` running $0 for $1 ..."
echo "`date` running $0 for $1 ..."
if [ $# -ne 2 ]; then
  echo "Usage: chk_HPSS_dir.sh DIR2check logfile"
  exit 1
fi

DIR=$1
FILE=$2
FILELOG=${FILE}.log
FILELOG1=${FILE}.temp
user=`whoami`
len=`echo $DIR |wc -c`

rm -rf $FILE $FILELOG $FILELOG1

if [ ${envir} = "prod" ]
then

if [ $user != "ops.prod" ]; then
  echo "Need to run this script as \"ops.prod\". "
  echo "exiting! $user please sudo to ops.prod to run $0"
  exit -1
fi

else

if [ $user != "ops.para" ]; then
  echo "Need to run this script as \"ops.para\". "
  echo "exiting! $user please sudo to ops.para to run $0"
  exit -1
fi

fi

export MAXTIME=${MAXTIME:-300}
let numattempts=3

while [ $numattempts -gt 0 ]; do
  timeout $MAXTIME hsi "ls -d $DIR/*/ " >> $FILELOG 2>&1
  err=$?
  if [ $err -ne 0 ]; then
    echo "hsi failed with err=$err, trying again in 10 seconds ..."
    ((numattempts--))
    sleep 10
  else
    echo "hsi successful!"
    let numattempts=-1  # successful completion
  fi
done

#######################################################
## check any hsi error or timeout
#######################################################
if [ $numattempts -eq 0 ]; then
  if [ $err -eq 64 ]; then
    echo "HPSS dir or file not existed. exit and continue..."
  else
    echo "FATAL ERROR: hsi failed after three attempts, check HPSS connection"
    err_exit
  fi
fi

cat $FILELOG | while read var; do 
  l=${#var}; 
  if [ $l -gt $len ]; then
  first=`echo $var |cut -c 1-1`; 
  last=`echo $var |cut -c $l-$l`; 
  if [ "$first" = "/" -a "$last" = ":" ]; then 
    echo $var"/" >> $FILELOG1;    
  fi; 
  fi;
done

perl -pi -e "s/\:\///g" $FILELOG1
sort $FILELOG1 | uniq > $FILE
