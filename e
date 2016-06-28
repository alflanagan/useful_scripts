#!/usr/bin/env dash
SOCKET=/tmp/emacs$(id -u)/server

if [ "$1" = "--help" ]; then
    emacs --help
elif [ -S ${SOCKET} ]; then
    date >> ~/log/emacsclient.log
    # don't rely on emacsclient starting a daemon, it only does terminal screen
    emacsclient -s ${SOCKET} -a emacs -n "$@" >> ~/log/emacsclient.log 2>&1
else
    date >> ~/log/emacs.log
    emacs "$@" >> ~/log/emacs.log 2>&1 &
fi
