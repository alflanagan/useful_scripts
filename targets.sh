#!/usr/bin/env dash

FNAME=Makefile

if [ ! -z "$1" -a -f $1 ]; then
    FNAME=$1
fi

grep -e '^[^ %]\+:' ${FNAME} | grep -v PHONY
