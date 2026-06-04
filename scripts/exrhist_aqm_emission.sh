#!/bin/sh
####################################################################
# exrhist_aqm_emission.sh.ecf
# "History: MAY 2015 - First implementation of this new script."
#           MAY 2024 - Removed backup of emission/ directory
#####################################################################

#####################################################################
#
# RUNHISTORY JOB
#
# This job uses script aqm_rhist_savedir.sh to tar up and save a specified
# operational directory in the appropriate directory under /hsmprod
# on the HPSS server, ncos70a.
#
#####################################################################

########################################
set -x
echo "JOB $job HAS BEGUN"
##########################################

  prevmon=`date -d "$PDY -1 month" +%Y%m`
##############################################################
# archive monthly bias-correction files
##############################################################

   $USHrunhistory/aqm_rhist_savedir.sh ${COMINaqm}/bcdata.$prevmon $prevmon 5
   export err=$?; $USHrunhistory/rhist_errchk.sh monthly

#####################################################################

# GOOD RUN
set +x
echo "**************JOB RHIST_AQM_EMISSION COMPLETED NORMALLY"
echo "**************JOB RHIST_AQM_EMISSION COMPLETED NORMALLY"
echo "**************JOB RHIST_AQM_EMISSION COMPLETED NORMALLY"
set -x

echo "JOB $job HAS COMPLETED NORMALLY."

############## END OF SCRIPT #######################
