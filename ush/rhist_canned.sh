#!/bin/sh
################################################################
#  This script archives recently changed files in the nwprod directory to HPSS.
####################################################### 
#  Usage: rhist_savenwprod.sh Date(YYYYMMDD format)
#
#  Where: Date(YYYYMMDD format) = Day that the tar file(s) should be saved 
#                                 under.
################################################################

set -x

if [ $# -ne 1 ]
then
   echo "usage rhish_savenwprod.sh YYYYMMDD"
   exit 1
fi
YYYYMMDD=$1

year=`echo $YYYYMMDD | cut -c 1-4`
yearmo=`echo $YYYYMMDD | cut -c 1-6`
yrmoday=$YYYYMMDD

hpssdir=${HPSSOUT}/canned_test
tarfile="hpss_canned_test.${SITE}.${YYYYMMDD}.tar"
#COMDIR=`compath.py transfers/${transfers_ver}`/10GB
export COMDIR=${COMDIR:-`compath.py runhistory/${runhistory_ver}`/${CANSIZE:-10GB}}
fileset="*t00z*"

if [ "$DRY_RUN_ONLY" == NO ]; then hsi mkdir -p -m 755 $hpssdir; fi

let sumerr=0

find $COMDIR -name $fileset  > ${DATA}/tmplist

if [ "$DRY_RUN_ONLY" == NO ]; then
 if [ -s ${DATA}/tmplist ]
 then
    htar -cVf ${hpssdir}/${tarfile} -L ${DATA}/tmplist
    hsi "chmod 775 ${hpssdir}/${tarfile}"
    sleep 10
    hsi " rm ${hpssdir}/${tarfile}*"
    err=$?
    let sumerr=sumerr+err
 fi
else
 echo "The following files would have been archived to ${hpssdir}/${tarfile}: $(cat ${DATA}/tmplist)"
fi

if [ $sumerr -ne 0 ]; then exit 4; else exit 0; fi
