#!/bin/sh
################################################################
#  This script archives recently changed files in the nwprod directory to HPSS.
####################################################### 
#  Usage: rhist_savepackages.sh Date(YYYYMMDD format)
#
#  Where: Date(YYYYMMDD format) = Day that the tar file(s) should be saved 
#                                 under.
################################################################

set -x

if [ $# -ne 1 ]
then
   echo "usage rhish_savepackages.sh YYYYMMDD"
   exit 1
fi
YYYYMMDD=$1

year=`echo $YYYYMMDD | cut -c 1-4`
yearmo=`echo $YYYYMMDD | cut -c 1-6`
yrmoday=$YYYYMMDD

hpssdir=${HPSSOUT}/rh${year}/${yearmo}/$yrmoday 
if [ "$DRY_RUN_ONLY" == NO ]; then hsi mkdir -p -m 755 $hpssdir; fi

let sumerr=0

touch -t ${PDYm1}0000 $DATA/time_check 

find /lfs/h1/ops/$envir/packages -type f -newer $DATA/time_check > ${DATA}/tmplist

#old wcoss
#find /gpfs/hps/nco/ops/nwprod /gpfs/dell1/nco/ops/nwprod -type f -newer $DATA/time_check > ${DATA}/tmplist
if [ "$DRY_RUN_ONLY" == NO ]; then
 if [ -s ${DATA}/tmplist ]
 then
    htar -cVf ${hpssdir}/packages.update.tar -L ${DATA}/tmplist
    hsi "chmod 775 ${hpssdir}/packages.update.tar"
    hsi "chmod 775 ${hpssdir}/packages.update.tar.idx"
    htar -tvf ${hpssdir}/packages.update.tar
    err=$?
    let sumerr=sumerr+err
 fi
else
 echo "The following files would have been archived to ${hpssdir}/packages.update.tar: $(cat ${DATA}/tmplist)"
fi

if [ $sumerr -ne 0 ]; then exit 4; else exit 0; fi
