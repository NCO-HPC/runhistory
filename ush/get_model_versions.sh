#!/bin/bash

set -x

#populate parm/models files from with real time version numbers from ecflow definition file
PARMrunhistory_models=${PARMrunhistory_models:-$DATA/parm/models}
cp -R ${PARMrunhistory_fixed}/* ${PARMrunhistory}

ecflow_client --get  --host=$active_server --port=$active_port | grep "_ver 'v" | grep -v "   " > $DATA/finalfile

cat $DATA/finalfile | grep "_ver 'v" | awk '{print $2}'  > $DATA/variable
cat $DATA/finalfile | grep "_ver 'v" | awk '{print ","$3}' | sed "s/[']//g" | sed 's|\(.*\)\..*|\1|' > $DATA/version
paste -d '' $DATA/variable $DATA/version > $DATA/model_versions.txt

while IFS=',' read -r model_ver ver
do

#substitutes 4 digit version number into static parm/model files with $model_ver placeholder
[ -d "$PARMrunhistory_models" ] && cd $PARMrunhistory_models && files=$(grep -rl $model_ver $PARMrunhistory_models) && echo $files | xargs sed -i "s|/$model_ver|/$ver|g"

done < $DATA/model_versions.txt
