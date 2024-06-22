#!/usr/bin/env zsh

# emacs --batch --eval "(progn (server-start) (print server-socket-dir))"
SOCKET=/run/user/$(id -u)/emacs/server

if [[ "$1" = "--help" ]]; then
    emacs --help
elif [[ -z "${LOG_DIR}"  || ! -d "${LOG_DIR}" ]]; then
    echo "NO LOGGING: env variable $LOG_DIR is not valid!" >&2
elif [[ -S "${SOCKET}" ]]; then
    date >> "${LOG_DIR}/emacsclient.log"
    # don't rely on emacsclient starting a daemon, it only does terminal screen
    emacsclient -s "${SOCKET}" -a emacs -n "$@" >> "${LOG_DIR}/emacsclient.log" 2>&1
else
    date >> "${LOG_DIR}/emacs.log"
    emacs "$@" >> "${LOG_DIR}/emacs.log" 2>&1 &
fi
