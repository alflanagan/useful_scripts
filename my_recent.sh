#!/usr/bin/env dash
FRED=2
if [ $# -gt 0 ]; then
    FRED="$1"
fi

cd "${HOME}" || exit 1

find . \
     -name .cache -prune -o \
     -name .mozilla -prune -o \
     -name elpa -prune -o \
     -name .mozilla -prune -o \
     -name .macromedia -prune -o \
     -name .lastpass -prune -o \
     -ipath '*/.local/share' -prune -o \
     -name .purple -prune -o \
     -name .atom -prune -o \
     -name .config -prune -o \
     -name .git -prune -o \
     -name .npm -prune -o \
     -name '.*cache*' -prune -o \
     -type f -mtime -"${FRED}" -ls | grep -v '~$'
