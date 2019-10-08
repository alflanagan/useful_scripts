#!/usr/bin/env dash

FNAME=Makefile

if [ -n "$1" ] && [ -f "$1" ]; then
    FNAME="$1"
fi

grep -e '^[^ %]\+:' "${FNAME}" | grep -v PHONY
