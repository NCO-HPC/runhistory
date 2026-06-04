#!/bin/ksh

# chk_HPSS.sh to check HPSS 1year, 2year and 5year directory and 
# create the list of remove old data for 1year, 2year and 5year

set -x
echo "`date` running $0 ..."

#PDY=`date -u +%Y%M%H`
export PDY=${PDY:-`date -u +%Y%M%H`};

export HPSSROOT=${HPSSROOT:-/NCEPPROD};
user=`whoami`

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

#######################################################
## NCEPHPSS directory structure                      ##
## /NCEPPROD/hpssprod                                ##
## /NCEPPROD/1year                                   ##
## /NCEPPROD/2year                                   ##
## /NCEPPROD/5year                                   ##
##                                                   ##
## /NCEPPROD/hpssprod/runhistory                     ##
## /NCEPPROD/hpssprod/runhistory/rh????              ##
## /NCEPPROD/hpssprod/runhistory/cfs????             ##
## /NCEPPROD/1year/hpssprod/runhistory/rh????        ##
## /NCEPPROD/2year/hpssprod/runhistory/rh????        ##
## /NCEPPROD/2year/hpssprod/runhistory/cfs????       ##
## /NCEPPROD/5year/hpssprod/runhistory/rh????        ##
## /NCEPPROD/5year/hpssprod/runhistory/cfs????       ##
#######################################################

#######################################################
## /NCEPPROD/hpsspara/runhistory/rh????              ##
## /NCEPPROD/hpsspara/runhistory/cfs????             ##
## /NCEPPROD/hpsspara/runhistory/1year/rh????        ##
## /NCEPPROD/hpsspara/runhistory/2year/rh????        ##
## /NCEPPROD/hpsspara/runhistory/2year/cfs????       ##
## /NCEPPROD/hpsstest/runhistory/2year/cfs????       ##
## /NCEPPROD/hpsspara/runhistory/5year/rh????        ##
## /NCEPPROD/hpsspara/runhistory/5year/cfs????       ##
#######################################################

#######################################################
##  EXCEPTIONS                                       ##
##  /NCEPPROD/.Trash                                 ##
##  /NCEPPROD/.TRASH.NCO                             ##
##  /NCEPPROD/?year/.TRASH.NCO                       ##
##  /NCEPPROD/?year/hpssprod/runhistory/save         ##
##  /NCEPPROD/?year/hpssprod/runhistory/WCOSS.STAGE  ##
##  /NCEPPROD/?year/hpssprod/runhistory/.Trash       ##
##  /NCEPPROD/?year/hpssprod/runhistory/.TRASH.NCO   ##
#######################################################
export EXCEPTION=" .Trash .TRASH.NCO save WCOSS.STAGE dbnet_bkup hur hwrf hmon cfs hafs"

## Check /NCEPPROD first level directories        ##
DIR="${HPSSROOT}"
FILE=HPSS1.log.$PDY
HPSS1KEEP="hpssprod 1year 2year 5year hpsspara hpsstest"
${USHrunhistory}/chk_HPSS_dir.sh $DIR $FILE
cp $FILE temp.log
for except in  $HPSS1KEEP $EXCEPTION ; do
  grep $DIR/ temp.log |grep -v $except > temp2.log
  cp temp2.log temp.log
done

if [ -s temp.log ]; then
  echo "The following directories under $DIR should be removed - "
  cat temp.log > HPSS1.REMOVE.list
  cat HPSS1.REMOVE.list
  #sh chk_HPSS_dir_size_by_file.sh HPSS1.REMOVE.list
fi
echo

## Check /NCEPPROD/* 2nd level directories        ##
DIR="${HPSSROOT}/*"
FILE=HPSS2.log.$PDY
HPSS2KEEP="hpssprod 1year 2year 5year hpsspara hpsstest"
${USHrunhistory}/chk_HPSS_dir.sh $DIR $FILE
cp $FILE temp.log
for except in  $HPSS2KEEP $EXCEPTION ; do
  grep $HPSSROOT/ temp.log |grep -v $except > temp2.log
  cp temp2.log temp.log
done

if [ -s temp.log ]; then
  echo "The following directories under $DIR should be removed - "
  cat temp.log > HPSS2.REMOVE.list
  cat HPSS2.REMOVE.list
  #sh chk_HPSS_dir_size_by_file.sh HPSS2.REMOVE.list
fi
echo

## Check /NCEPPROD/hpssprod/runhistory directories    ##
export CHECK_MORE=NO
if [ $CHECK_MORE = "YES" ]; then
DIR="${HPSSROOT}/hpssprod/runhistory"
FILE=HPSS3.log.$PDY
HPSS3KEEP="/runhistory/rh /runhistory/cfs /runhistory/save/ "
${USHrunhistory}/chk_HPSS_dir.sh $DIR HPSS3.log.perm

DIR="${HPSSROOT}/?year/hpss*/runhistory"
FILE=HPSS3.log.$PDY
HPSS3KEEP="/runhistory/rh /runhistory/cfs /runhistory/save/ "
${USHrunhistory}/chk_HPSS_dir.sh $DIR HPSS3.log.year

cat HPSS3.log.perm  HPSS3.log.year > $FILE

cp $FILE temp.log
for except in  $HPSS3KEEP $EXCEPTION ; do
  grep $HPSSROOT/ temp.log |grep -v $except > temp2.log
  cp temp2.log temp.log
done

if [ -s temp.log ]; then
  echo "The following directories under $DIR should be removed - "
  cat temp.log > HPSS3.REMOVE.list
  cat HPSS3.REMOVE.list
  #sh chk_HPSS_dir_size_by_file.sh HPSS3.REMOVE.list
fi
echo

## Check /NCEPPROD/hpssprod/runhistory directories    ##
DIR="${HPSSROOT}/hpssprod/runhistory"
FILE=HPSS4.log.$PDY
HPSS4KEEP="/runhistory/rh /runhistory/cfs /runhistory/save/ "
${USHrunhistory}/chk_HPSS_dir.sh $DIR HPSS4.log.perm

DIR="${HPSSROOT}/?year/hpss*/runhistory"
${USHrunhistory}/chk_HPSS_dir.sh $DIR HPSS4.log.year

cat HPSS4.log.perm  HPSS4.log.year > $FILE

cp $FILE temp.log
for except in  $HPSS4KEEP $EXCEPTION ; do
  grep $HPSSROOT/ temp.log |grep -v $except > temp2.log
  cp temp2.log temp.log
done

if [ -s temp.log ]; then
  echo "The following directories under $DIR should be removed - "
  cat temp.log > HPSS4.REMOVE.list
  cat HPSS4.REMOVE.list
  #sh chk_HPSS_dir_size_by_file.sh HPSS4.REMOVE.list
fi
echo
fi

## Check /NCEPPROD/?year/hpss*/runhistory/* directories ##
DIR="${HPSSROOT}/?year/hpss*/runhistory/*"
FILE=HPSS5.log.$PDY
HPSS5KEEP="/runhistory/rh /runhistory/cfs /runhistory/save/ "
${USHrunhistory}/chk_HPSS_dir.sh $DIR $FILE

for year in 1 2 5; do

  HPSS5KEEP=`sh ${USHrunhistory}/mon2keep.sh $year`
  cp $FILE temp.log

  for except in  $HPSS5KEEP $EXCEPTION ; do
    grep ${HPSSROOT}/${year}year/ temp.log |grep -v $except > temp2.log
    cp temp2.log temp.log
  done

  if [ -s temp.log ]; then
    echo "The following directories under ${HPSSROOT}/${year}year/ should be removed -" 
    cat temp.log > HPSS5.REMOVE.list.${year}year
    cat HPSS5.REMOVE.list.${year}year
    #sh chk_HPSS_dir_size_by_file.sh HPSS5.REMOVE.list.${year}year
  fi
  echo
done

## Check /NCEPPROD/hpss*/runhistory/?year/* directories ##
DIR="${HPSSROOT}/hpss*/runhistory/?year/*"
FILE=HPSS6.log.$PDY
HPSS6KEEP="/runhistory/rh /runhistory/cfs /runhistory/save/ "
${USHrunhistory}/chk_HPSS_dir.sh $DIR $FILE

for year in 1 2 5; do

  HPSS6KEEP=`sh ${USHrunhistory}/mon2keep.sh $year`
  cp $FILE temp.log

  for except in  $HPSS6KEEP $EXCEPTION ; do
    grep /${year}year/ temp.log |grep -v $except > temp2.log
    cp temp2.log temp.log
  done

  if [ -s temp.log ]; then
    echo "The following directories under ${HPSSROOT}/${year}year/ should be removed - "
    cat temp.log > HPSS6.REMOVE.list.${year}year
    cat HPSS6.REMOVE.list.${year}year
    #sh chk_HPSS_dir_size_by_file.sh HPSS6.REMOVE.list.${year}year
  fi
  echo
done
