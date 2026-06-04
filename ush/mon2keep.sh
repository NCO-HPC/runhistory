#!/bin/bash

# mon2keep.sh will retrun the months to keep for specifed 1/2/5 years 
# for HPSS clean up for HPSS 1year, 2year and 5year directory

set +ax 

year2keep=$1
if [[ $year2keep = '' ]]; then
  echo "empty input, please use "$0 year2keep" (for year to keep)"
  echo "exiting"
  exit -1
fi

#yyyy=`$NDATE|cut -c 1-4`;
#mon=`$NDATE|cut -c 5-6`;
export PDY=${PDY:-`$NDATE|cut -c 1-8`};
yyyy=`echo $PDY|cut -c 1-4`;
mon=`echo $PDY|cut -c 5-6`;
let yyyym1=yyyy-1

YYYY=`$NDATE|cut -c 1-4`;
MON=`$NDATE|cut -c 5-6`;

msg1=""

if [ $year2keep = 1 ]; then 
  for m in `seq 1 12`; do 
    mm=`printf "%02d" ${m} `; 
    if [ "${mm}" -le "${mon}" ]; then 
      msg1=`echo ${msg1} ${yyyy}/${yyyy}${mm} `;  
    else 
      msg1=`echo ${msg1} ${yyyym1}/${yyyym1}${mm} `; 
    fi; 
  done
  if [ "$YYYY" -ne "$yyyy" ] || [ "$mon" -ne "$MON" ]; then
   for yr in `seq $yyyy $YYYY`; do
     for m in `seq 1 12`; do
       mm=`printf "%02d" ${m} `;
       if [ "${yr}${mm}" -gt "${yyyy}${mon}" ] && [ "${yr}${mm}" -le "${YYYY}${MON}" ]; then
          msg1=`echo ${msg1} ${yr}/${yr}${mm} `;
       fi
     done
   done
  fi
  echo ${msg1}
elif [ $year2keep = 2 ]; then
  let yyyym2=yyyy-2
  msg2=""

  for m in `seq 1 12`; do 
    mm=`printf "%02d" ${m} `; 
    if [ "${mm}" -le "${mon}" ]; then 
      msg2=`echo ${msg2} ${yyyy}/${yyyy}${mm} `;  
    else 
      msg2=`echo ${msg2} ${yyyym2}/${yyyym2}${mm} `; 
    fi; 
  done

  for m in `seq 1 12`; do 
    mm=`printf "%02d" ${m} `; 
    msg2=`echo ${msg2} ${yyyym1}/${yyyym1}${mm} `;  
  done
  if [ "$YYYY" -ne "$yyyy" ] || [ "$mon" -ne "$MON" ]; then
   for yr in `seq $yyyy $YYYY`; do
     for m in `seq 1 12`; do
       mm=`printf "%02d" ${m} `;
       if [ "${yr}${mm}" -gt "${yyyy}${mon}" ] && [ "${yr}${mm}" -le "${YYYY}${MON}" ]; then
          msg2=`echo ${msg2} ${yr}/${yr}${mm} `;
       fi
     done
   done
  fi
  echo ${msg2}
else
  let yyyym2=yyyy-2
  let yyyylast=yyyy-$year2keep
  let yyyyp1=yyyylast+1
  
  msg3=""
  for m in `seq 1 12`; do
    mm=`printf "%02d" ${m} `;
    if [ "${mm}" -le "${mon}" ]; then
      msg3=`echo ${msg3} ${yyyy}/${yyyy}${mm} `;
    else
      msg3=`echo ${msg3} ${yyyylast}/${yyyylast}${mm} `;
    fi;
  done

  for yr in `seq $yyyyp1 $yyyym1`; do
    for m in `seq 1 12`; do
      mm=`printf "%02d" ${m} `;
      msg3=`echo ${msg3} ${yr}/${yr}${mm} `;
    done
  done
  if [ "$YYYY" -ne "$yyyy" ] || [ "$mon" -ne "$MON" ]; then
   for yr in `seq $yyyy $YYYY`; do
     for m in `seq 1 12`; do
       mm=`printf "%02d" ${m} `;
       if [ "${yr}${mm}" -gt "${yyyy}${mon}" ] && [ "${yr}${mm}" -le "${YYYY}${MON}" ]; then
          msg3=`echo ${msg3} ${yr}/${yr}${mm} `;
       fi
     done
   done
  fi
  echo ${msg3}
fi
