#!/bin/bash
BASE_DIR=.
if [[ $# -gt 1 ]]; then
    BASE_DIR=$1
fi

#Lord, I hate the syntax for -prune. good explanation:
#http://stackoverflow.com/questions/1489277/how-to-use-prune-option-of-find-in-sh
#not using -prune now, leaving above because it's a good reference anyway :)
for FILE in $(find . -name '*.py' -print)
do
    COUNT=$(svn propget svn:keywords ${FILE} | wc -l)
    if [[ ${COUNT} -eq 0 ]]; then
        echo ${FILE}
    fi
done
