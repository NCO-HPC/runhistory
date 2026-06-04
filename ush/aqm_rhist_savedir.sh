#!/bin/sh
################################################################3
# aqm_rhist_savedir.sh
# This script will tar up the directory specified by the first
# argument ($1) and place the tar file on the HPSS server
# under ${HPSSOUT}.  The tar file is put in the directory
# appropriate for data valid for the day specified as the second 
# command line argument ($2).
# The third argument, if present, indicates whether the tar file 
# should be written to the 1-year, 2-year, or permanent archive.
# Valid values for the 3rd argument are "1", "2" or "perm"
#
# Usage: aqm_rhist_savedir.sh Directory Date(YYYYMM format) [1|2|perm]
#
# Where: Directory  = Directory to be tarred.
################################################################3

set -x

if [ $# -ne 2 ] && [ $# -ne 3 ] 
then
  echo "Usage: aqm_rhist_savedir.sh Directory Date(YYYYMM format) [1|2|perm]"
  exit 1
fi 

dir=$1
if [ ! -d $dir ]
then
  echo "aqm_rhist_savedir.sh:  Directory $dir does not exist."
  exit 2
fi 

# cd to directory to be saved
cd $dir

#   Generate the name of the tarfile, which should be the same
#   as the absolute path name of the directory being
#   tarred, except that "/" are replaced with "_".
tarfile=`echo $PWD | cut -c 2- | tr "/" "_"`
tarfile=${tarfile}.tar

year=`echo $2 | cut -c 1-4`
yearmo=`echo $2 | cut -c 1-6`

#   Determine the directory where the tar file will be stored
#   and make sure that it exists on HPSS.
if [ $# -eq 3 ]
then
    if [ $3 = "1" ]
    then
	 hpssdir=${HPSSOUT}/1year/rh${year}/$2
    elif [ $3 = "2" ]
    then
	 hpssdir=${HPSSOUT}/2year/rh${year}/$2
    else
	 hpssdir=${HPSSOUT}/rh${year}/$2
    fi
else
    hpssdir=${HPSSOUT}/rh${year}/$2
fi

# Check to see if tar file index already exists
if [ "$CHECK_HPSS_IDX" == YES ]; then
 hsi "ls -l ${hpssdir}/${tarfile}.idx"
 tar_file_exists=$?
 if [ $tar_file_exists -eq 0 ]
 then
   echo "File  $tarfile already saved."
   exit 0
 fi
fi

# htar is used to create the archive, -P creates
# the directory path if it does not already exist,
# and an index file is also made.

if [ "$DRY_RUN_ONLY" == NO ]; then
 date
 htar -P -cvf ${hpssdir}/$tarfile .
 err=$?

 if [ $err -ne 0 ]
 then
   echo "aqm_rhist_savedir.sh:  File $tarfile was not successfully created."
   exit 3
 else
  ecflow_client --event aqm_emission

    NEWPBS_JOBID=$(echo $PBS_JOBID  | awk -F. '{print $1}')
    ${USHrunhistory}/hpss_transfer_rates.pl $PBS_O_WORKDIR/$PBS_JOBNAME.o$NEWPBS_JOBID | grep "Total for all Jobs" >> $rate_label_log
    echo "outputfilepath=$PBS_O_WORKDIR/$PBS_JOBNAME.o$NEWPBS_JOBID"
    ecflow_client --label info "`cat $rate_label_log | grep -v output `"

 fi
 date
 # Read the tarfile and save a list of files that are in the tar file.
 htar -tvf $hpssdir/$tarfile
 err=$?
 if [ $err -ne 0 ]
 then
   echo "aqm_rhist_savedir.sh:  Tar file $tarfile was not successfully read to"
   echo "             generate a list of the files."
   exit 4
 fi
else
 ecflow_client --event aqm_emission
 echo "Directory $PWD would have been archived to $hpssdir/$tarfile"
fi

