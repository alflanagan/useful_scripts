#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
    echo "Usage: $(basename $0) percentage command"
    echo "       Execute a COMMAND only PERCENTAGE percent of the time."
    exit 1
fi

(( LIMIT = (32762 * $1) / 100 ))

if (( RANDOM < LIMIT )); then
    shift
    eval "$*"
fi
