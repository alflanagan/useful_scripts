#!/usr/bin/env bash
# bash "strict mode"
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

IFS=$'\n\t'

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
