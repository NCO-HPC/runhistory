#!/bin/sh
#####################################################################
# exhpss_cleanup.sh.ecf to cleanup the HPSS 1year, 2year and 5year old data
#####################################################################

set -x
echo "$0 has begun"

errsum=0
export HSI=${HSI:-"hsi"}

#####################################################################
# 1. check the $PDY, not allowed PDY to be set advanced to current date
# 2. only run this job at the first day of each month
# 3. check the $month is within 1-12
#####################################################################
export year=`echo $PDY | cut -c 1-4`
export mon=`echo $PDY | cut -c 5-6`
export date=`echo $PDY | cut -c 7-8`

#test to force a cleanup run since it needs to be date=01
#export date=01

export current_PDY=`$NDATE | cut -c 1-8`

if [ $PDY -gt ${current_PDY} ]; then
  echo "PDY $PDY is advanced than current date ${current_PDY}, not allowed, dangerous! Exiting..."
  echo
  export err=-1; err_chk;
fi

if [ $date != "01" ]; then
  echo "$job only run at the first day of each month. $date is not 01. Exiting..."
  echo
  exit
fi

if [ $mon -eq "00" -o $mon -gt "12" ]; then
  echo "month $mon in $PDY is not correct. Please check. Exiting ..."
  echo
  export err=-2; err_chk;
fi

#####################################################################
# Clean 1year, 2year, and 5year fileset on HPSS ...
#####################################################################
export yearlist="1 2 5"
#clean_mon=$mon
let tmp=`expr $mon - 1`; 
if [ $tmp -eq 0 ]; then 
  let tmp=12;
  let year=`expr $year - 1 ` 
fi; 
clean_mon=`printf "%02d" $tmp`; 
echo $mon $clean_mon;

if [ $DRY_RUN_ONLY != NO ]; then echo "Dry run only for HPSS cleanup. Nothing to do."; exit 0; fi

rm -rf msg
echo > msg
echo "*************************************************************" >> msg
echo "*** WARNING!! $PDY HPSS file sets will be cleaned up  ***" >> msg
echo "*************************************************************" >> msg
for yr in $yearlist ; do
  let clean_year=$year-$yr;
  clean_yearmon_HPSSDIR=$HPSSOUT/${yr}year/rh${clean_year}/${clean_year}${clean_mon}
  TRASH_NCO_year=$HPSSOUT/${yr}year/.TRASH.NCO
  echo "  ${clean_yearmon_HPSSDIR} " >> msg
  $HSI "rm -R ${clean_yearmon_HPSSDIR} "
  export err=$?

#####################################################################
# if clean YYYYY12, the clean all reset of dir under rhYYYY,
# then clean rhYYYY ...
#####################################################################
  if [ ${clean_mon} -eq "12" ]; then
    clean_year_HPSSDIR=$HPSSOUT/${yr}year/rh${clean_year}

#####################################################################
# find out what are reset of dir under rhYYYY, and clean them up ...
#####################################################################
    FILE=rm.list
    ${USHrunhistory}/chk_HPSS_dir.sh ${clean_year_HPSSDIR} $FILE
    cat $FILE
    for dir in `cat $FILE `; do
      echo " ${dir} " >> msg
      $HSI "rm -R ${dir} "
    done

    echo " ${clean_year_HPSSDIR} " >> msg
    $HSI "rm -R ${clean_year_HPSSDIR} "
    export err=$?;
  fi
  ecflow_client --event cleanup_${yr}year
done
echo >> msg
cat msg

echo "########################################################"
echo "## Additional check HPSS file sets/file families      ##"
echo "########################################################"
echo
$USHrunhistory/chk_HPSS.sh
export err=$?; err_chk;

#old maillist, set in run.ver now
#export maillist=${maillist:-'nco.spa@noaa.gov'}

export subject="$SITE $PDY HPSS Cleanup"
cat msg > HPSS.REMOVE.list
echo "*****************************************************************" >> HPSS.REMOVE.list
echo "*** ATTENTION!! $PDY HPSS file sets need to be cleaned up ***" >> HPSS.REMOVE.list
echo "***           SPA please take carefully proper actions !      ***" >> HPSS.REMOVE.list
echo "*****************************************************************" >> HPSS.REMOVE.list
for file in `ls HPSS*REMOVE.list*`; do
  cat $file >> HPSS.REMOVE.list
done
cat HPSS.REMOVE.list | mail.py -s "$subject" $maillist -v
#####################################################################
echo "$0 completed normally"
