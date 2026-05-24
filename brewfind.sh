#!/bin/bash

function brew_find_pkg {
    file_to_search="$@"

    for package in $(brew list); do
        brew ls $package | grep -E -q "/${file_to_search}$"
        if [ $? -eq 0 ]; then
            echo $package
            break
        fi
    done
}
