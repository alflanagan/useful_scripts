#!/usr/bin/env dash
if [ -S /tmp/emacs$(id -u)/server ]; then
    # this swallows --help option, oh well
    emacsclient -n "$@" >> ~/log/emacsclient.log 2>&1
else
    emacs "$@" >> ~/log/emacs.log 2>&1 &
fi
