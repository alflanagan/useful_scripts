#!/usr/bin/env bash

# required for workon to use the correct python environment
export VIRTUALENVWRAPPER_PYTHON=/home/aflanagan/opt/bin/python

. /usr/bin/virtualenvwrapper.sh

list_all_virtuals () {
    local CURR_ENV PYVENV
    
    if [[ ! -z ${VIRTUAL_ENV} ]]; then
        CURR_ENV=$(basename ${VIRTUAL_ENV})
    fi
    
    pushd . > /dev/null
    for PYVENV in $(workon)
    do
        workon ${PYVENV}
        echo -n "${PYVENV}: "
        python --version
    done
    popd > /dev/null

    if [[ -z ${CURR_ENV} ]]; then
        deactivate
    else
        workon ${CURR_ENV}
    fi
}

list_all_virtuals
