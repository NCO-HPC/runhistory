#!/bin/sh

# This script is called by exrhist.sh.ecf, and mirrors runhistory tar creation
# logs between cactus and dogwood

set -x

sorf=`hostname | cut -c1`
if   [ "$sorf" == d ]; then host=cxfer;
elif [ "$sorf" == c ]; then host=dxfer;
else echo "rhist_mirror.sh: Where in the world are we?"; exit 1;
fi

source=$LOGrunhistory
dest=$LOGrunhistory

if [[ -z $source || -z $dest || -z $host ]]; then exit 1; fi

# create a superset of files from both systems on the local system
let numattempts=3
while [ $numattempts -gt 0 ]; do
    /usr/bin/rsync  --timeout=${RSYNC_MAXTIME:?} -avv --progress   ${host}:${dest}/ ${source}
    err1=$?
    if [ $err1 -ne 0 ]; then
	((numattempts--))
	sleep 5
    else
	let numattempts=-1  # successful completion
    fi
done
[ $err1 -ne 0 ] && echo "rhist_mirror: WARNING: rsync of $LOGrunhistory from $host failed after $numattempts attempts"

# create an exact copy on the remote system
if [ $err1 -ne 0 ] ; then
    echo "rhist_mirror: WARNING: rsync of $LOGrunhistory back to $host skipped"
else
    let numattempts=3
    while [ $numattempts -gt 0 ]; do
	/usr/bin/rsync  --timeout=${RSYNC_MAXTIME:?} --delete -avv    ${source}/ ${host}:${dest}
	err2=$?
	if [ $err2 -ne 0 ]; then
	    ((numattempts--))
	    sleep 5
	else
	    let numattempts=-1  # successful completion
	fi
    done
    [ $err2 -ne 0 ] && echo "rhist_mirror: WARNING: rsync of $LOGrunhistory back to $host failed after $numattempts attempts"
fi

exit 0
