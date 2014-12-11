#!/usr/bin/env bash
if [[ -z $1 ]]; then
    FILES=*.xml
else
    FILES=$1/*.xml
fi
for F in ${FILES}
do
   CP=$(mktemp)
   cp ${F} ${CP}
   xmllint --format ${CP} > ${F}
   rm -f ${CP}
done
