#!/usr/bin/env bash
cd ~/Devel
for DIR in *
do
    if [[ -d ${DIR} ]]; then
        if [[ -d ${DIR}/.svn ]]; then
            echo "******** ${DIR} ***********"
            pushd ${DIR} > /dev/null
            svn status
            popd > /dev/null
        fi
    fi
done
