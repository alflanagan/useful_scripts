#!/usr/bin/env bash
# -*- coding: utf-8-unix -*-
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
	# bldpath VARNAME DIR [before|after]
	# VARNAME names an environment variable formatted like PATH (e.g. PATH,
	#   LD_LIBRARY_PATH, PYTHONPATH)
	# DIR is a directory which will be added to the variable named by VARNAME
	# but only if it's not already present
	# no validation is done on DIR: don't care if it doesn't exist
	# DIR is added to the end of the variable unless third argument is "before"
	local -r VARNAME="$1" DIR="$2"
	local -l POS=after
	[[ -n "$3" ]] && POS="$3"

	[[ ${POS} == before || ${POS} == after ]] || {
		echo 'Optional third argument must be "before" or "after" (default is "after").'
		return 1
	}

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

pathmunge() {
	[[ $# -gt 0 ]] || { cat <<-EOF
	Usage: ${FUNCNAME} dir_path [before|after]
		   adds dir_path to PATH variable
		   adds to end unless 'before' specified.
	EOF
						return 1
						}
	[[ -d "$1" ]] || {
		echo "${FUNCNAME} ERROR: path not found [$1]" >&2
		return 2
	}
	bldpath PATH "$1" "$2"
	# changes to PATH may not be respected for cached command lookups
	hash -r
}

is_in_path() {
  local DIR="$1"
  #extra colons simplify case
  case ":${PATH}:" in
    *:${DIR}:*)
    return 0;;
    *)
    return 1;;
  esac
}

#TODO: generalize to take path variable name as param
pathrm() {
    local paths=() i=0 newpath=""

    #safely split PATH on ':', should handle dirnames with special chars
    while IFS= read -r -d $':' dname; do
        paths[i++]="$dname"
    done < <(echo "$PATH":)

    # build new path with all elements of old path not equal to $1
    for dname in "${paths[@]}"
    do
        if [[ ! -z "${dname}" && "${dname}" != "$1" ]]
        then
            if [[ -z "${newpath}" ]]
            then
                newpath="${dname}"
            else
                newpath="${newpath}:${dname}"
            fi
        fi
    done
    
    export PATH="${newpath}"
    hash -r
}

manmunge() {
	if [[ $# -lt 1 ]]; then
		cat <<-EOF
	Usage: ${FUNCNAME} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]
			Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to MANPATH environment variable.
			${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified.
	EOF
		return 1
	fi
	bldpath MANPATH "$1" "$2"
}

ldlibmunge() {
	[[ $# -gt 0 ]] || { cat <<-EOF
		Usage: ${FUNCNAME} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]
			   Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to LD_LIBRARY_PATH environment variable."
			   ${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified."
		EOF
		return -1
	}
	bldpath LD_LIBRARY_PATH "$1" "$2"
}

myps() {
#list processes running under current user's name, except for some system stuff
#cat causes whole line to print, wrapped
    ps -fu $(whoami) | grep -v -e '/usr/libexec/' -e 'dbus' -e 'gnome-pty-helper' -e 'ibus-daemon' -e 'keyring-daemon' | cat
}

fixldpath() {
#eliminates duplicates from LD_LIBRARY_PATH variable
    local newldpath
    for DIR in $(echo ${LD_LIBRARY_PATH} | tr ':' '\n')
    do
        bldpath newldpath ${DIR}
    done
    export LD_LIBRARY_PATH=${newldpath}
}

#TODO: modify this so that functions can have special doc comment as first line
functions() {
#hmm... typeset -f strips comments.
    typeset -f | grep '() $' | sed 's/() //' | sed 's/ //g'
}

# -----------------------------------------------------------------------------------------------
#  ENHANCED 'find's
# -----------------------------------------------------------------------------------------------

findtextin() {
	[[ $# -lt 3 ]] && { cat <<-EOF
		Usage: ${FUNCNAME} <start-dir> '<file-pattern>' <search-text>
			   <start-dir>: top-level directory, it & all subs will be searched.
			   <search-text>: text string to search for in each file that matches
			                  <file-pattern>
		EOF
		return 1
	}
	find "$1" -name "$2" -exec grep "$3" '{}' +
}

find_no_svn() {
    local find_path="$1"
    shift
    find "${find_path}" -name '.svn' -prune -o \( "$@" \)
}

find_no_svn_grep() {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}[path-spec]${TERM_UL_OFF} ${TERM_UL_ON}search_term${TERM_UL_OFF} ${TERM_UL_ON}additional_find_options${TERM_UL_OFF}"
        echo "    grep selected files for lines containing ${TERM_UL_ON}search_term${TERM_UL_OFF}."
        echo "    ${TERM_UL_ON}additional_find_options${TERM_UL_OFF} are any valid options for find (1)."
        echo "    ${TERM_UL_ON}path_spec${TERM_UL_OFF} defaults to current directory."
    else
        local DIR="."
        [[ -d "$1" ]] && { DIR="$1"; shift; }

        local search_term="$1"
        shift
		local options="-type f"
		# how to do this space-safe? Build an array?
		[[ -z "$*" ]] || options="${options} $*"
		echo find "${DIR}" -name \'.svn\' -prune -o -name \'.git\' -prune -o \( "${options}" \) -exec grep -IH \"${search_term}\" \'{}\' +
		find "${DIR}" -name '.svn' -prune -name '.git' -prune -o \( "${options}" \) -exec grep -IH "${search_term}" '{}' +

    fi
}

find_no_svn_igrep() {
    if  [[ $# -eq 0 ]]; then
        echo "${FUNCNAME} ${TERM_UL_ON}[path-spec]${TERM_UL_OFF} ${TERM_UL_ON}search_term${TERM_UL_OFF} ${TERM_UL_ON}additional_find_options${TERM_UL_OFF}"
        echo "    case-insensitive grep selected files for lines containing ${TERM_UL_ON}search_term${TERM_UL_OFF}."
        echo "    ${TERM_UL_ON}additional_find_options${TERM_UL_OFF} are any valid options for find (1)."
    else
        local DIR="."
        if [[ -d "$1" ]]; then
            DIR="$1"
            shift
        fi

        local search_term="$1"
        shift
        echo find "${DIR}" -name '.svn' -prune -o -name '.git' -prune -o \( "$@" \) -exec grep -iIH \"${search_term}\" \'{}\' \\\;
        find "${DIR}" -name '.svn' -prune -o -name '.git' -prune -o \( "$@" \) -exec grep -iIH "${search_term}" '{}' \;
    fi
}


# -----------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------

#appears to be no way to turn off unalias error if alias doesn't exist
unalias ll 2>/dev/null
ll() {
    ls -Alh "$@"
}

#one-line functions must have ';' before final }
lrt() { ls -lrt "$@"; }
lrtail() { ls -lrt "$@" | tail; }
lrtc() { ls -lrt "$@" | commall.py; }

largest() {
    #or use ls -S
    ls -l "$@" | sort -r -g -k5
}

chkswap() {
    if [[ $# -eq 0 ]]; then
        echo provide an integer argument to see totals every argument seconds
        echo this is a summary since last boot.
    fi
    vmstat -a -S M "$@"
}

chkdiskio() {
    vmstat -d -S M "$@"
}

chkpartio() {
#TODO: intelligently get list of partitions
    vmstat -p sda1
    vmstat -p sda2
    vmstat -p sda3
}

lnall() {
    if [[ $# -ne 3 ]]; then
        echo "Usage: ${FUNCNAME} path filename linkname"
        echo '       finds all files named {filename} in {path} or subdirectories of {path}'
        echo '       creates a symbolic link with name {linkname} that points to {filename}'
        echo '       link is created in same directory as the file to which it points'
        return 1
    fi
    echo 'finding...'
    for FILE in $(find "$1" -name "$2" -a ! -type d)
    do
    #this creates extraneous links if FILE is a directory, not sure why
        cd "${FILE%/*}"  # dirname
        echo "$3 --> ${FILE}"
        ln -s "${FILE##*/}" "$3"  # basename
        cd -
    done
}

execsql() {
  if  [[ $# -eq 0 ]]; then
    echo "${FUNCNAME} ${TERM_UL_ON}sql_file${TERM_UL_OFF} ${TERM_UL_ON}additional_psql_options${TERM_UL_OFF}"
    echo "    Call psql to execute ${TERM_UL_ON}sql_file${TERM_UL_OFF} in database netinformer as user apache."
  else
    local SQL_FILE="$1"
    shift
    psql -f "${SQL_FILE}" --db=netinformer --user=apache "$@"
  fi
}

domysql() {
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

execmysql() {
  if  [[ $# -eq 0 ]]; then
    echo "${FUNCNAME} ${TERM_UL_ON}sql_file${TERM_UL_OFF}"
    echo "    Execute SQL statements in ${TERM_UL_ON}sql_file${TERM_UL_OFF} with mysql."
  else
    mysql -u root -p < "${1}"
  fi
}

lgv() {
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

llgv() {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME} some-pattern [ls-options] -- list (long form) all files that don't match some-pattern"
    else
        lgv "$@" -l
    fi
}

every() {
#TODO: detect, handle bad input
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME} _seconds_ do _command_"
        echo "       where _seconds_ is time, and _command_ is a shell command"
        echo "       note: if _command_ contains multiple commands or redirection, quote it"
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

with() {
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
    pushd "${DIR}" > /dev/null
    eval "${CMDS}"
    popd > /dev/null
}

sum_size() {
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

h2d() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} hex_number"
        echo "       converts hex_number from hexadecimal to integer, prints result."
        return 1
    fi
    local hexnum
    typeset -u hexnum   # force uppercase
    hexnum=$1
    # TODO: check for valid digits
    dc -e "16i${hexnum}p"
}

# tempting to create h2o(), but would it ever get used?

o2d() {
  if [[ $# -lt 1 ]]; then
      echo "Usage: ${FUNCNAME} octal_number"
      echo "       converts octal_number from octal to integer, prints result."
      return 1
  elif [[ $1 == 0 ]]; then
      # some invalid input sets octnum to 0, so we have to special case actual 0
      # if we want to catch invalid input
      echo 0
      return
  fi
  
  declare -i octnum=$1
  # TODO: check for digit > 7
  if (( ${octnum} == 0 )); then
    echo "ERROR: input not a number" >&2
    o2d
  else
    dc -e "8i${octnum}p"
  fi
}

d2h() {
  if [[ $# -lt 1 ]]; then
      echo "Usage: ${FUNCNAME} number"
      echo "       converts decimal number to hexadecimal, prints result."
      return 1
  elif [[ $1 == 0 ]]; then
      # see comment in o2d()
      echo "0"
      return
  fi
  declare -i INPUT="$1"
  
  if [[ ${INPUT} -eq 0 ]]; then
    # bad conversion, show help
    echo "ERROR: input is not a number" >&2
    d2h
  else
    dc -e "16o${INPUT}p"
  fi
}

d2o() {
  if [[ $# -lt 1 ]]; then
      echo "Usage: ${FUNCNAME} number"
      echo "       converts decimal number to octal, prints result."
      return 1
  elif [[ $1 == 0 ]]; then
      # see comment in o2d()
      echo "0"
      return
  fi

  local -i INPUT="${1}"
  if [[ ${INPUT} -eq 0 ]]; then
    echo "ERROR: input is not a number" >&2
    d2o
  else
    dc -e "8o${INPUT}p"
  fi
}

x2d () {
    #turns out when I try to remember "h2d" my brain comes up with
    #"x2d" instead. Go figure.
    h2d "$@"
}

curl_get() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} URL [destination_file_name]"
        echo "       Retrieves a URL using curl and saves it to a file. Handles errors intelligently"
        return 1
    fi
    local THE_URL="$1"
    if [[ $# -eq 2 ]]; then
        local DEST_FILE="$2"
    else
        local DEST_FILE="${THE_URL##*/}"
    fi
    curl -f "${THE_URL}" > "${DEST_FILE}"
    local ERR=$?
    if [[ ${ERR} -ne 0 ]]; then
        echo "ERROR: curl returned code ${ERR}, file '${DEST_FILE}' not retrieved." >&2
        rm -f "${DEST_FILE}"
    fi
}

curl_get_missing() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME} URL [destination_file_name]"
        echo "       Retrieves a URL using curl and saves it to a file. Handles errors intelligently."
        echo "       Does not retrieve the file if the destination file already exists."
        return 1
    fi
    if [[ $# -eq 2 ]]; then
        local DEST_FILE="$2"
    else
        local DEST_FILE= "${THE_URL##*/}"
    fi
    if [[ ! -f "${DEST_FILE}" ]]; then
        curl_get "$1" "$2"
    fi
}

xwhich() {
##TODO: won't find executable file if function or alias exists
    (alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde "$@"
}

wing() {
    #verbose causes errors to log, etc.
    /usr/bin/wing6.0 --verbose "$@" > ${HOME}/log/wing6.log 2>&1 &
}

#get list of files in a zip, dropping all info except file names
zip_list() {
    unzip -l "$@" | cut -c 31- | tail -n +4  | head -n -2
}

endswith() {
    [[ "$1" = "*$2" ]]
}

dtree() {
    tree -d "$@"
}

extra() {
    #switch from home directory to parallel directory on /mnt/extra
    #for when I don't want to work through soft links
    cd ${PWD/\/home\/aflanagan/\/mnt\/extra}
}

view_html() {
    case "$@" in
        /*)
            echo firefox --no-remote --new-window file://localhost"$@" "&"
            firefox --no-remote --new-window file://localhost"$@" &
            ;;
        *)
            echo firefox --no-remote --new-window file://localhost${PWD}/"$@" "&"
            firefox --no-remote --new-window file://localhost${PWD}/"$@" &
            ;;
    esac
}

dbshell() {
  if [[ -f manage.py ]]; then
    python manage.py dbshell
  elif [[ -f ../manage.py ]]; then
    python ../manage.py dbshell
  else
    echo "Can't start dbshell; where is manage.py?" >&2
  fi
}

truepath () {
  # provide a more memorable name
  readlink -f "$@"
}

cs() {
  python manage.py collectstatic --noinput;
}

chrome() {
  google-chrome >~/log/chrome.log 2>&1 &
}

# set up synonym for for firefox if user version present
# prefer firefox-dev if present
if [ -x ~/opt/firefox-dev/firefox ]; then
    firefox() {
        local FFOX=~/opt/firefox-dev/firefox
        local FLOG=~/log/user-firefox-dev.log

        if [[ $1 == --help ]]; then
            "${FFOX}" --help
        else
            "${FFOX}" --no-remote "$@" > "${FLOG}" 2>&1 &
        fi
    }
elif [ -x ~/opt/firefox/firefox ]; then
    firefox() {
        local "FFOX"=~/opt/firefox/firefox
        local "FLOG"=~/log/user-firefox.log

        if [[ $1 == --help ]]; then
            "${FFOX}" --help
        else
            "${FFOX}" --no-remote "$@" > "${FLOG}" 2>&1 &
        fi
    }
fi

ecompile() {
  emacs --batch -f batch-byte-compile "$@"
}

columns() {
  if [[ $# -gt 0 ]]; then
    pr -t -T -$1
  else
    pr -t -T
  fi
}

# generate a list of completion words for a command
# comp git config ''
# ==> add.ignore-errors alias. apply.ignorewhitespace apply.whitespace ...
# from http://unix.stackexchange.com/questions/25935/how-to-output-string-completions-to-stdout
# user yuyichao
comp() {
    # set up variables used by bash completion funcionality
    local COMP_LINE="$*"
    local COMP_WORDS=("$@")
    local COMP_CWORD=${#COMP_WORDS[@]}
    ((COMP_CWORD--))
    local COMP_POINT=${#COMP_LINE}
    local COMP_WORDBREAKS='"'"'><=;|&(:"
    # Don't really think any real autocompletion script will rely on
    # the following 2 vars, but in principle they could ~~~  LOL.
    local COMP_TYPE=9
    local COMP_KEY=9
    _command_offset 0
    echo ${COMPREPLY[@]}
}

npm_packages() {
  # list npm packages without semver
  # should be a better way to do this
  npm $* ls --depth=0 | grep -v npm | cut -d' ' -f2 | grep -v /usr | grep -v '^$' | cut -d'@' -f1
}

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# End:
