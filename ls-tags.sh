#!/bin/bash

if [[ "$1" == "-h"  ]]
then
cat << EOF
$0 

will list tags for this environment
EOF
exit 0
fi

PWD=$(pwd)
repo=${PWD##*/}
space=larsvilhuber

## maybe it's local only
echo "============================================================="
echo " Searching for local containers for $space/$repo "
echo ""
docker images | grep $space/$repo | awk ' { print $2 } ' | tee tags.txt
echo ""
echo " -- Stored in tags.txt --"

