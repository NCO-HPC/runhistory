#!/bin/sh
################################################################
#
#  This script archives specific hwrf data to the two-year archive.
#
#  Usage: rhist_savehwrf.sh Directory Date(YYYYMMDDHH format)
#
#  Where: Directory  = Directory to be tarred.
#         Date(YYYYMMDDHH format) = Day that the tar file should be saved under.
#
#  *Returns error code 2 when no data exists.  This is assumed to
#   be because no storms were submitted for the cycle to be archived.*
#
################################################################

set -x

if [ $# -ne 2 ]
then
  echo "Usage: rhist_savehwrf.sh Directory Date(YYYYMMDDHH format) "
  exit 1
fi 

${USHrunhistory}/rhist_check.sh $1 $2
if [ $? -eq 0 ] ; then
  echo "Log entry found in $LOGrunhistory, skipped processing for: $0 $1 $2"
  exit 0
fi

# Get directory to be tarred from the first command line argument,
# and check to make sure that the directory exists and has content.
COMINhwrf=$1
if [ ! -d $COMINhwrf ]; then
  echo "rhist_savehwrf.sh:  Directory $COMINhwrf does not exist."
  exit 2
fi
if [ $(ls $COMINhwrf | wc -l) -eq 0 ]; then
  echo "rhist_savehwrf.sh:  Directory $COMINhwrf is empty."
  exit 2
fi

ymdh=$2
year=$(echo $ymdh | cut -c 1-4)

# Get a listing of all files in the directory to be tarred
# and break the file list up into groups of files.
# Each list of files names the contents of its associated tar file.
cd $COMINhwrf

for stormvars_filename in storm?.holdvars.txt; do
  . ./$stormvars_filename

  # Determine where the file should be archived
  hpssdir=${HPSSOUT}/2year/rh${year}/hwrf/${STORMID,,}
  tarfile=${STORM,,}${STORMID,,}.${ymdh}.tar

  # Check if the tarfile index exists.  If it does, assume that
  # the data for the corresponding directory has already been
  # tarred and saved.
  if [[ "$CHECK_HPSS_IDX" == "YES" ]]; then
    hsi "ls -l ${hpssdir}/${tarfile}.idx"
    tar_file_exists=$?
    if [ $tar_file_exists -eq 0 ]; then
      echo "File $tarfile already saved."
      continue
    fi
  fi

  if [[ "$DRY_RUN_ONLY" == "YES" ]]; then
    echo "DRY RUN, list of files that would be archived:"
    ls -1 $stormvars_filename *${STORMID,,}.*
  else
    # Archive the files
    hsi mkdir -p -m 755 $hpssdir
    #HMU Aug 2020 RFC 7119 HWRF upgrade - Update the htar to exclude several file patterns that do not need to be archived
    htar -cvf ${hpssdir}/$tarfile --exclude="*nexrad*" --exclude="*ww3_oun*" --exclude="*gribber*.log" $stormvars_filename *${STORMID,,}.*
    err=$?
    if [ $err -ne 0 ]; then
      echo "rhist_savehwrf.sh:  File $tarfile was not successfully created."
      exit 3
    fi 

    # Read the tarfile and print a list of files it contains
    htar -tvf ${hpssdir}/$tarfile
    err=$?
    if [ $err -ne 0 ]; then
      echo "rhist_savehwrf.sh: Tar file ${hpssdir}/$tarfile"
      echo "                   as not successfully read to generate a list of the files."
      exit 4
    fi 
  fi
done

[[ "$DRY_RUN_ONLY" != "YES" ]] && ${USHrunhistory}/rhist_log.sh $1 $2
exit 0
