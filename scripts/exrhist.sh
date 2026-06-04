#!/bin/bash
################################################################################
# exrhist.sh.ecf
#
# This script wraps rhist.sh, which parses a parmfile for each model and
# initiates transfers to HPSS. Any special procedures in terms of scripting (in
# order to, e.g., shuffle files around before a transfer) should be done through
# those parmfiles, not in this script or rhist.sh.
# This script gets called by JRHIST.
#
# The most important variable that gets passed in is $job, which determines which
# set of parmfiles to process.
#
################################################################################

set -x
echo "$0 has begun"

errsum=0
# create empty errfile to avoid warning from older versions of err_chk.sh
cat /dev/null > errfile

if [ "$DRY_RUN_ONLY" == NO ]; then
 find $LOGrunhistory/_*[0-9] -mtime +${LOG_DAYS_KEEP:?} -exec echo "removing {}" \; -exec rm {} \;
else
 which htar
 which hsi
fi

#remove per Stevens request GM for w2 version
##if [[ $RSYNC_LOG_DIR == "YES" && "$DRY_RUN_ONLY" != YES && "$job" =~ (^.runhistory_daily) ]] ; then
#  sync log directory between both WCOSS systems
## ${USHrunhistory}/rhist_mirror.sh
##fi

# We only do transfers at 00z:
if [ "$cyc" != 00 ]; then
 echo "$0: This isn't 00z! Quitting..."
 exit 0
fi

if [[ "$njob" =~  (^.runhistory_packages) ]]; then
   echo "don't need to make parm files in $DATA"
else 
#populate 2 digit version numbers from ecflow definiton file into parm/model files in runhistory package
   ${USHrunhistory}/get_model_versions.sh
fi 

#changed from job to $njob (njob now from %TASK% in ecflow)
if [[ "$njob" =~  (^.runhistory00|^.runhistory06|^.runhistory12|^.runhistory18|^.runhistory_daily|^.runhistory_nwm|^.runhistory_rtofs) ]]; then
 rhcyc=$(echo $njob | perl -pe 's|.runhistory(\d\d)?(_[a-z]+)?|\1|g') # should be two-digit cycle or empty
 # Read in list of parmfiles for this job:
 if [ "$rhistlist" == "all" ]; then

#changed from job to $njob
 parmfilelist=$(sed "s/[[:space:]]*#.*//g;/^$/d" ${PARMrunhistory}/j${njob:1})
 else
  parmfilelist=$(echo $rhistlist | sed 's|,| |g')
 fi
 parmfilelist=$(echo $parmfilelist | sed 's| \+|\n|g' | grep -wvE "$(echo $excludelist | sed 's|,| |g;s| \+|\||g')")

 # $jobtarlogfile will contain a list of tarfiles that have been transferred for
 # this job by rhist.sh, and will be used to decide whether they get skipped.
 export JOBTARLOGFILE=${LOGrunhistory}/${njob}.tarlog.txt
 if [ -e $JOBTARLOGFILE ]; then
  thismonth_yyyymm=$(date +%Y%m)
  lastmonth_yyyymm=$(date -d "1 month ago" +%Y%m)
  grep -F -e "/$thismonth_yyyymm/" -e "/$lastmonth_yyyymm/" $JOBTARLOGFILE > ${JOBTARLOGFILE}.tmp
  mv ${JOBTARLOGFILE}.tmp $JOBTARLOGFILE
 else
  touch $JOBTARLOGFILE
 fi
 # Process each parmfile and DO THE TRANSFERS:
 for modelname in $parmfilelist; do
  #Added for if RHISTLIST starts with hwrf|hmon|packages --> hafs
  if [[ $modelname =~ ^(hafs|packages)$ ]]; then continue; fi
  # Special treatment for off-cycle hour labels (e.g., 03 instead of 00):
  if [[ " ( sref srefges ) " =~ " $modelname " ]]; then
   if   [ "$rhcyc" == 00 ]; then rhcyctmp=03;
   elif [ "$rhcyc" == 06 ]; then rhcyctmp=09;
   elif [ "$rhcyc" == 12 ]; then rhcyctmp=15;
   elif [ "$rhcyc" == 18 ]; then rhcyctmp=21;
   fi
  else rhcyctmp=$rhcyc
  fi
  ${USHrunhistory}/rhist.sh $modelname
  export err=$?; ((errsum+=$err)); ${USHrunhistory}/rhist_errchk.sh $modelname $rhcyctmp
  echo "errsumcount=$errsum"
 done
fi

# Old case statement goes here so models can be migrated to
# new parmfile approach one by one. The goal is to get rid of this.
### BEGIN OLD SCRIPTS:
case $njob in
 [jpt]runhistory[0-1][0-8])
  if [[ "$rhistlist" == all || $(echo $parmfilelist | grep -c hafs) -gt 0 ]]; then
#put model hwrf in from ecf  -> hafs
#  archive HAFS hfsa.${PDYm1}/${rhcyc} data
   COMINhfsa="`compath.py hafs/$hafs_v2d`/hfsa.${PDYm1}/${rhcyc}"
   $USHrunhistory/rhist_savehafs.sh  ${COMINhfsa} ${PDYm1}${rhcyc} hfsa
   export err=$?
   if [ $err -ne 2 ]; then  # error code 2 means no storms this cycle
     ((errsum+=$err)); $USHrunhistory/rhist_errchk.sh hfsa ${rhcyc}
   fi

#  archive HAFS hfsb.${PDYm1}/${rhcyc} data
   COMINhfsb="`compath.py hafs/$hafs_v2d`/hfsb.${PDYm1}/${rhcyc}"
   $USHrunhistory/rhist_savehafs.sh  ${COMINhfsb} ${PDYm1}${rhcyc} hfsb
   export err=$?
   if [ $err -ne 2 ]; then  # error code 2 means no storms this cycle
     ((errsum+=$err)); $USHrunhistory/rhist_errchk.sh hfsb ${rhcyc}
   fi
  fi
  ;;
 [jpt]runhistory_packages)
   $USHrunhistory/rhist_savepackages.sh $PDY
   export err=$?; ((errsum+=$err));$USHrunhistory/rhist_errchk.sh packages
   ;;
esac
### END OLD SCRIPTS

echo "exrhist.sh.ecf is done; about to run err_chk with err=$errsum"
echo "If job fails after this, no HPSS transfers will have been prevented"

# Check if any transfers failed, and if so, abort the runhistory job in ecFlow
export err=$errsum; err_chk

echo "$0 completed normally"
