#!/usr/bin/env bash
#above more for documentation, since normally this file must be sourced

#put some useful terminal escapes in shell variables
#TERM_BOLD_ON=$(tput -T xterm bold)
#TERM_BOLD_OFF=$(tput -T xterm dim)
TERM_BOLD_ON=$(tput -T xterm smso)
TERM_BOLD_OFF=$(tput -T xterm rmso)
TERM_UL_ON=$(tput -T xterm smul)
TERM_UL_OFF=$(tput -T xterm rmul)

#a lot of useful bash functions
bldpath() {
    #bldpath VARNAME DIR [before|after]
    #VARNAME names an environment variable formatted like PATH (e.g. PATH, 
    #  LD_LIBRARY_PATH, PYTHONPATH)
    #DIR is a directory which will be added to the variable named by VARNAME
    #but only if it's not already present
    #no validation is done on DIR: don't care if it doesn't exist
    #DIR is added to the end of the variable unless third argument is "before"
    local -r VARNAME="$1"
    local -r DIR="$2"
    if [[ -n $3 ]]; then
        #force lowercase
        local -r -l POS=$3
    else
        local -r POS=after
    fi

    if [[ ${POS} != before && ${POS} != after ]]; then
        echo "Optional third argument must be \"before\" or \"after\" (default is \"after\")."
        return 1
    fi

    #local -r SHOW=echo  #uncomment this for debug output
    local -r SHOW=:
    #BRACKETED_PATH makes case statement simpler
    local -r BRACKETED_PATH=":${!VARNAME}:"
    case "${BRACKETED_PATH}" in
        *:${DIR}:*)
            ${SHOW} "${DIR} already in ${VARNAME}, doing nothing."
            ;;
        ::)
            ${SHOW} "${VARNAME} not set, setting it to ${DIR}"
            export ${VARNAME}=${DIR};;
        *)
            ${SHOW} "${DIR} not in ${VARNAME}, adding it ${POS} existing value."
            if [[ ${POS} == after ]]; then
                export ${VARNAME}="${!VARNAME}":"${DIR}"
            else
                export ${VARNAME}="${DIR}":"${!VARNAME}"
            fi;;
    esac
}

function pathmunge {
    if [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} dir_path [before|after]"
        echo "     adds dir_path to PATH variable"
        echo "     adds to end unless 'before' specified."
        return 1
    fi
    if [[ ! -d "$1" ]]; then
        echo "${FUNCNAME} ERROR: path not found [$1]" >&2
	return 2
    fi
    bldpath PATH "$1" "$2"
} 

function is_in_path {
    local DIR="$1"
    #extra colons simplify case
    case :${PATH}: in
        *:${DIR}:*)
            return 1;;
        *)
            return 0;;
    esac
}

#TODO: generalize to take path variable name as param
function pathrm {
    local NEW_PATH=$(echo ${PATH} | tr ':' '\n' | grep -v "^$1$" | grep -v '^$' | tr '\n' ':')
    #above *might* leave a trailing colon, kill it
    export PATH=${NEW_PATH%:}
}

function manmunge {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]"
        echo "    Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to MANPATH environment variable."
        echo "    ${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified."
        return 1
    fi
    bldpath MANPATH "$1" "$2"
} 

function ldlibmunge {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]"
        echo "    Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to LD_LIBRARY_PATH environment variable."
        echo "    ${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified."
        return 1
    fi
    bldpath LD_LIBRARY_PATH "$1" "$2"
}

function myps {
#list processes running under current user's name, except for some system stuff
#cat causes whole line to print, wrapped
    ps -fu $(whoami) | cat
}

function fixldpath {
#eliminates duplicates from LD_LIBRARY_PATH variable
    local newldpath
    for DIR in $(echo ${LD_LIBRARY_PATH} | tr ':' '\n')
    do
        bldpath newldpath ${DIR}
    done
    export LD_LIBRARY_PATH=${newldpath}
}

#TODO: modify this so that functions can have special doc comment as first line
function functions {
#hmm... typeset -f strips comments.
    typeset -f | grep '() $' | sed 's/() //' | sed 's/ //g'
}

function findtextin {
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME} <start-dir> '<file-pattern>' <search-text>"
        echo "       Don't forget the single quotes around <file-pattern>"
        echo '       or the shell will expand it with file names from current directory.'
        echo '       <start-dir>: top-level directory, it & all subs will be searched.'
        echo '       <search-text>: text string to search for in each file that matches'
        echo '                      <file-pattern>'
        return 1
    fi
    find "$1" -name "$2" -exec grep "$3" '{}' /dev/null \;
}

#appears to be no way to turn off unalias error if alias doesn't exist
unalias ll 2>/dev/null
ll() {
    ls -Alh "$@"
}

#one-line functions must have ';' before final }
function lrt { ls -lrt "$@"; }
function lrtail { ls -lrt "$@" | tail; }
function lrtc { ls -lrt "$@" | commall.py; }

function largest {
    #or use ls -S
    ls -l "$@" | sort -r -g -k5
}

function chkswap {
    if [[ $# -eq 0 ]]; then
        echo provide an integer argument to see totals every argument seconds
        echo this is a summary since last boot.
    fi
    vmstat -a -S M "$@"
}

function chkdiskio {
    vmstat -d -S M "$@"
}

function chkpartio {
#TODO: intelligently get list of partitions
    vmstat -p sda1
    vmstat -p sda2
    vmstat -p sda3
}

function lnall {
    if [[ $# -ne 3 ]]; then
        echo "Usage: ${FUNCNAME} path filename linkname"
        echo '       finds all files named {filename} in {path} or subdirectories of {path}'
        echo '       creates a symbolic link with name {linkname} that points to {filename}'
        echo '       link is created in same directory as the file to which it points'
        return 1
    fi
    echo 'finding...'
    for FILE in $(find "$1" -name "$2")
    do
    #this creates extraneous links if FILE is a directory, not sure why
        cd $(dirname "${FILE}")
        echo "$3 --> ${FILE}"
        ln -s $(basename "${FILE}") "$3"
        cd -
    done
}

function find_no_svn {
    local find_path=$1
    shift
    find "${find_path}" ! -iregex '.*\\.svn.*' "$*"
}

function find_no_svn_grep {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}search_term${TERM_UL_OFF} ${TERM_UL_ON}additional_find_options${TERM_UL_OFF}"
        echo "    grep selected files for lines containing ${TERM_UL_ON}search_term${TERM_UL_OFF}."
        echo "    ${TERM_UL_ON}additional_find_options${TERM_UL_OFF} are any valid options for find (1)."
        echo "    Detects when first argument is a directory, and starts from there."
    else
        local DIR="."
        if [[ -d "$1" ]]; then
            DIR="$1"
            shift
        fi

        local search_term="$1"
        shift
        echo find ${DIR} $* ! -iregex \'.*/\\.svn/.*\' -exec grep -IH \"${search_term}\" \'{}\' \\\;
        find ${DIR} $* ! -iregex '.*/\.svn/.*' $* -exec grep -IH "${search_term}" '{}' \;
    fi
}

function find_no_svn_igrep {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}search_term${TERM_UL_OFF} ${TERM_UL_ON}additional_find_options${TERM_UL_OFF}"
        echo "    case-insensitive grep selected files for lines containing ${TERM_UL_ON}search_term${TERM_UL_OFF}."
        echo "    ${TERM_UL_ON}additional_find_options${TERM_UL_OFF} are any valid options for find (1)."
        echo "    Detects when first argument is a directory, and starts from there."
    else
        local DIR="."
        if [[ -d "$1" ]]; then
            DIR="$1"
            shift
        fi

        local search_term="$1"
        shift
        echo find ${DIR} "$*" ! -iregex \'.*/\\.svn/.*\' -exec grep -iIH \"${search_term}\" \'{}\' \\\;
        find ${DIR} "$*" ! -iregex '.*/\.svn/.*' -exec grep -iIH "${search_term}" '{}' \;
    fi
}

function execsql {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}sql_file${TERM_UL_OFF} ${TERM_UL_ON}additional_psql_options${TERM_UL_OFF}"
        echo "    Call psql to execute ${TERM_UL_ON}sql_file${TERM_UL_OFF} in database netinformer as user apache."
    else
	local SQL_FILE=$1
	shift
	psql -f ${SQL_FILE} --db=netinformer --user=apache $*
    fi
}

function domysql {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}db_name${TERM_UL_OFF} ${TERM_UL_ON}sql_statement${TERM_UL_OFF}"
        echo "    Execute ${TERM_UL_ON}sql_statement${TERM_UL_OFF} with mysql using database ${TERM_UL_ON}db_name${TERM_UL_OFF}."
    else
	mysql -u root -p <<HERE
use ${1}
${2}
HERE
    fi
}

function execmysql {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}sql_file${TERM_UL_OFF}"
        echo "    Execute SQL statements in ${TERM_UL_ON}sql_file${TERM_UL_OFF} with mysql."
    else
	mysql -u root -p < ${1}
    fi
}

function lgv {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME} some-pattern [ls-options] -- list all files that don't match some-pattern"
    elif [[ $# -eq 1 ]]; then
        ls | grep -v "$*"
    else
        PATTERN=$1
        shift
        ls "$@" | grep -v "${PATTERN}"
    fi
}

function llgv {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME} some-pattern [ls-options] -- list (long form) all files that don't match some-pattern"
    else
        lgv "$@" -l
    fi
}

function every {
#TODO: detect, handle bad input
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME} _seconds_ do _command_"
        echo "       where _seconds_ is time, and _command_ is a shell command"
        echo "       note: quoting arguments as part of _command_ (to combine multiple words) does not work"
        return 1
    fi
    local secs=$1
    shift
    if [[ $1 == do ]]; then
        shift
    fi
    local cmd="$@"
    #echo cmd is ${cmd}
    while true
    do
        #echo evaluating "${cmd}"
        eval "${cmd}"
        sleep ${secs}
    done
}

function with {
    local ON=${TERM_UL_ON}
    local OFF=${TERM_UL_OFF}
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME} ${ON}dir_name${OFF} do ${ON}commands...${OFF}"
        echo "       executes ${ON}commands${OFF}... with current directory set to ${ON}dir_name${OFF}"
        echo "       Does not change user's current directory."
        return 1
    fi
    local DIR="$1"
    shift
    if [[ "$1" == do ]]; then
        shift
    fi
    local CMDS="$@"
    local OLD_DIR=$(pwd)
    cd ${DIR}
    eval ${CMDS}
    cd ${OLD_DIR}
}

function sum_size {
    #TODO: use getopts to parse args, check only for file name args below
    #i.e. "sum_size -h" should generate usage message
    if [[ $# -lt 1 ]]; then
        #because "du -c | tail -n 1" will sum all files in directory tree, take arbitrarily long time :-(
        echo "Usage: ${FUNCNAME} [args] files.."
        echo "       Prints total space taken by files in file list. Accepts arguments as defined in du(1)."
        return 1
    fi
    local TOTAL=$(du -c "$@" | tail -n 1)
    echo ${TOTAL} | cut -f1 -d" "
}

function h2d {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} hex_number"
        echo "       converts hex_number from hexadecimal to integer, prints result."
        return 1
    fi
    local hexnum
    typeset -u hexnum   # force uppercase
    hexnum=$1
    dc -e "16i${hexnum}p"
}

x2d () {
    #turns out when I try to remember "h2d" my brain comes up with
    #"x2d" instead. Go figure.
    h2d "$@"
}

function curl_get {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} URL [destination_file_name]"
        echo "       Retrieves a URL using curl and saves it to a file. Handles errors intelligently"
        return 1
    fi
    local THE_URL=$1
    if [[ $# -eq 2 ]]; then
        local DEST_FILE=$2
    else
        local DEST_FILE=$(basename ${THE_URL})
    fi
    curl -f "${THE_URL}" > "${DEST_FILE}"
    local ERR=$?
    if [[ ${ERR} -ne 0 ]]; then
        echo "ERROR: curl returned code ${ERR}, file ${DEST_FILE} not retrieved." >&2
        rm -f ${DEST_FILE}
    fi
}

function curl_get_missing {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} URL [destination_file_name]"
        echo "       Retrieves a URL using curl and saves it to a file. Handles errors intelligently."
        echo "       Does not retrieve the file if the destination file already exists."
        return 1
    fi
    if [[ $# -eq 2 ]]; then
        local DEST_FILE="$2"
    else
        local DEST_FILE=$(basename "${THE_URL}")
    fi
    if [[ ! -f ${DEST_FILE} ]]; then
        curl_get "$1" "$2"
    fi
}

function which
{
#TODO: won't find executable file if function or alias exists
    (alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot "$@"
}

function wing5
{
    #verbose causes errors to log, etc.
    /usr/bin/wing5.0 --verbose "$@" > /home/aflanagan/log/wing5.log 2>&1 &
    #/usr/bin/wing5.0 "$@" > /home/aflanagan/log/wing5.log 2>&1 &
}

function wing
{
    wing5
}

#get list of files in a zip, dropping all info except file names
function zip_list
{
    unzip -l "$@" | cut -c 31- | tail -n +4  | head -n -2
}

function endswith
{
    local VALUE=$1
    local ENDING=$2
    [[ ${VALUE%${ENDING}} != ${VALUE} ]]
    return $?
}

function umbrello
{
    /usr/bin/umbrello "$@" > ~/log/umbrello.log 2>&1 &
}

function dtree
{
    tree -d "$@"
}

extra () {
    #switch from home directory to parallel directory on /mnt/extra
    #for when I don't want to work through soft links
    cd $(pwd | sed -e "s|/home/aflanagan/|/mnt/extra/|")
}
