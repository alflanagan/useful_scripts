#!/usr/bin/env bash

COUNTTRY=0
COUNTHIT=0

PERCENT=50
if [[ ! -z $1 ]]; then
    PERCENT=$1
fi

while ((COUNTTRY < 2000))
do
    . ~/bin/dopercent.bash ${PERCENT} '(( COUNTHIT += 1 ))'
    (( COUNTTRY = COUNTTRY + 1 ))
done

echo $COUNTHIT "/" $COUNTTRY
