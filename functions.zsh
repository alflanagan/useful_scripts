#!/usr/bin/env zsh
# -*- coding: utf-8-unix -*-
#above more for documentation, since normally this file must be sourced

#put some useful terminal escapes in shell variables
#TERM_BOLD_ON=$(tput -T xterm bold)
#TERM_BOLD_OFF=$(tput -T xterm dim)
TERM_BOLD_ON=$(tput -T xterm smso)
TERM_BOLD_OFF=$(tput -T xterm rmso)
TERM_ITAL_ON=$(tput -T xterm sitm)
TERM_ITAL_OFF=$(tput -T xterm ritm)
TERM_UL_ON=$(tput -T xterm smul)
TERM_UL_OFF=$(tput -T xterm rmul)

export TERM_BOLD_ON TERM_BOLD_OFF TERM_UL_OFF TERM_UL_ON

#a lot of useful zsh functions
pathmunge() {
	[[ $# -gt 0 ]] || { cat <<-EOF
	Usage: ${FUNCNAME[0]} dir_path [before|after]
		   adds dir_path to PATH variable
		   adds to end unless 'before' specified.
	EOF
						return 1
						}
	[[ -d "$1" ]] || {
		echo "${FUNCNAME[0]} ERROR: path not found [$1]" >&2
		return 2
	}
	if [[ $# -gt 1 && "$2" == 'before' ]]; then
		path=("$1" $path)
	else
		path+="$1"
	fi
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
#TODO: handle paths that match except for trailing '/'
pathrm() {
    local paths=() i=0 newpath=""

    #safely split PATH on ':', should handle dirnames with special chars
    while IFS= read -r -d $':' dname; do
        paths[i++]="$dname"
    done < <(echo "$PATH":)

    # build new path with all elements of old path not equal to $1
    for dname in "${paths[@]}"
    do
        if [[ -n "${dname}" && "${dname}" != "$1" ]]
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
	Usage: ${FUNCNAME[0]} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]
			Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to MANPATH environment variable.
			${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified.
	EOF
		return 1
	fi
	bldpath MANPATH "$1" "$2"
}

ldlibmunge() {
	[[ $# -gt 0 ]] || { cat <<-EOF
		Usage: ${FUNCNAME[0]} ${TERM_UL_ON}directory${TERM_UL_OFF} [before|after]
			   Adds ${TERM_UL_ON}directory${TERM_UL_OFF} to LD_LIBRARY_PATH environment variable."
			   ${TERM_UL_ON}directory${TERM_UL_OFF} is added to end unless 'before' is specified."
		EOF
		return 1
	}
	bldpath LD_LIBRARY_PATH "$1" "$2"
}

myps() {
	#list processes running under current user's name, except for some system stuff
	#very much an ad hoc hack
	#cat causes whole line to print, wrapped
	# shellcheck disable=SC2009
    ps -fu "$(whoami)" | command grep -v -e '/usr/libexec/' -e 'dbus' -e 'gnome-pty-helper' -e 'ibus-daemon' -e 'keyring-daemon' -e keybase -e VBoxClient -e /System -e Dropbox -e com.docker | cat
}

fixldpath() {
#eliminates duplicates from LD_LIBRARY_PATH variable
    local newldpath
    for DIR in $(echo "${LD_LIBRARY_PATH}" | tr ':' '\n')
    do
        bldpath newldpath "${DIR}"
    done
    export LD_LIBRARY_PATH="${newldpath}"
}

#TODO: modify this so that functions can have special doc comment as first line
functions() {
#hmm... typeset -f strips comments.
    typeset -f | command grep '() {$' | command sed 's/ () {//'
}

# -----------------------------------------------------------------------------------------------
#  ENHANCED 'find's
# -----------------------------------------------------------------------------------------------

findtextin() {
	[[ $# -lt 3 ]] && { cat <<-EOF
		Usage: ${FUNCNAME[0]} <start-dir> '<file-pattern>' <search-text>
			   <start-dir>: top-level directory, it & all subs will be searched.
			   <search-text>: text string to search for in each file that matches
			                  <file-pattern>
		EOF
		return 1
	}
	find "$1" -name "$2" -exec grep "$3" '{}' +
}

# -----------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------
unalias ll 2> /dev/null

# shellcheck disable=SC2012
ll() {
    ls -Alh "$@"
}

#one-line functions must have ';' before final }
lrt() { ls -lrt "$@"; }
# shellcheck disable=SC2012
lrtail() { ls -lrt "$@" | tail; }
# shellcheck disable=SC2012
lrtc() { ls -lrt "$@" | commall.py; }

largest() {
    #or use ls -S
		# shellcheck disable=SC2012
    ls -l "$@" | sort -r -g -k5
}

llgv() {
    if [[ $# -lt 1 ]]; then
        echo "${FUNCNAME[0]} some-pattern [ls-options] -- list (long form) all files that don't match some-pattern"
    else
        lgv "$@" -l
    fi
}

every() {
#TODO: detect, handle bad input
#SEE: watch (1)
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME[0]} _seconds_ do _command_"
        echo "       where _seconds_ is time, and _command_ is a shell command"
        echo "       note: if _command_ contains multiple commands or redirection, quote it"
        return 1
    fi
    local secs=$1
    shift
    if [[ $1 == 'do' ]]; then
        shift
    fi
    local cmd="$*"
    #echo cmd is ${cmd}
    while true
    do
        #echo evaluating "${cmd}"
        eval "${cmd}"
        sleep "${secs}"
    done
}

with() {
    local ON=${TERM_UL_ON}
    local OFF=${TERM_UL_OFF}
    if [[ $# -lt 3 ]]; then
        echo "Usage: ${FUNCNAME[0]} ${ON}dir_name${OFF} do ${ON}commands...${OFF}"
        echo "       executes ${ON}commands${OFF}... with current directory set to ${ON}dir_name${OFF}"
        echo "       Does not change user's current directory."
        return 1
    fi
    local DIR="$1"
    shift
    if [[ "$1" == 'do' ]]; then
        shift
    fi
    local CMDS="$*"
    pushd "${DIR}" > /dev/null || return
    eval "${CMDS}"
    popd > /dev/null || return 1
}

sum_size() {
    #TODO: use getopts to parse args, check only for file name args below
    #i.e. "sum_size -h" should generate usage message
    if [[ $# -lt 1 ]]; then
        #because "du -c | tail -n 1" will sum all files in directory tree, take arbitrarily long time :-(
        echo "Usage: ${FUNCNAME[0]} [args] files.."
        echo "       Prints total space taken by files in file list. Accepts arguments as defined in du(1)."
        return 1
    fi
    local TOTAL
    TOTAL=$(du -c -k "$@" | tail -n 1)
    echo "${TOTAL}" | cut -f1 -d" "
}

h2d() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} hex_number"
        echo "       converts hex_number from hexadecimal to integer, prints result."
        return 1
    fi
    local hexnum
    typeset -u hexnum   # force uppercase
    hexnum=$1
    # TODO: check for valid digits
    dc -e "16i${hexnum}p"
}

h2b() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} hex_number"
        echo "       converts hex_number from hexadecimal to binary, prints result."
        return 1
    fi
    local hexnum
    typeset -u hexnum   # force uppercase
    hexnum=$1
    # TODO: check for valid digits
    dc -e "16i${hexnum} 2op"
}

# tempting to create h2o(), but would it ever get used?
# warning shouldn't apply to global functions to be used outside of script.
# but how to tell shellcheck?
# shellcheck disable=SC2120
o2d() {
  [[ $# -ne 1 ]] && {
      echo "Usage: ${FUNCNAME[0]} octal_number"
      echo "       converts octal_number from octal to integer, prints result."
      return 1
  }
  local valid_number
  valid_number='^[0-7]+$'

  [[ "$1" =~ ${valid_number} ]] || {
      echo "ERROR: input not an octal number" >&2
      o2d  # show usage
      return 1
  }

  dc -e "8i${1}p"
}

#shellcheck disable=SC2120
d2h() {
  if [[ $# -lt 1 ]]; then
      echo "Usage: ${FUNCNAME[0]} number"
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

#shellcheck disable=SC2120
d2o() {
  if [[ $# -lt 1 ]]; then
      echo "Usage: ${FUNCNAME[0]} number"
      echo "       converts decimal number to octal, prints result."
      return 1
  fi

  local -i INPUT="${1}"
  if [[ $1 -ne 0 && ${INPUT} -eq 0 ]]; then
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
        echo "Usage: ${FUNCNAME[0]} URL [destination_file_name]"
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
        echo "Usage: ${FUNCNAME[0]} URL [destination_file_name]"
        echo "       Retrieves a URL using curl and saves it to a file. Handles errors intelligently."
        echo "       Does not retrieve the file if the destination file already exists."
        return 1
    fi
    if [[ $# -eq 2 ]]; then
        local DEST_FILE="$2"
    else
        local DEST_FILE="${THE_URL##*/}"
    fi
    if [[ ! -f "${DEST_FILE}" ]]; then
        curl_get "$1" "$2"
    fi
}

# alas, debian doesn't use full-featured which
if [[ ! -f /etc/debian_release ]]; then
	xwhich() {
	    (alias; declare -f) | command -v which --tty-only --read-alias --read-functions --show-tilde "$@"
	}
fi

if [[ "$(uname)" != "darwin" ]]; then
  wing() {
      #verbose causes errors to log, etc.
      /usr/bin/wing --verbose "$@" > "${HOME}/log/wing.log" 2>&1 &
  }
fi

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

view_html() {
	  local args_to_url
	  args_to_url="${*// /%20}"
    case "${args_to_url}" in
        /*)
            echo firefox --no-remote --new-window "file://localhost${args_to_url}" "&"
            firefox --no-remote --new-window "file://localhost${args_to_url}" &
            ;;
        *)
				    pwd_to_url="${PWD// /%20}"
            echo firefox --no-remote --new-window "file://localhost${pwd_to_url}/${args_to_url}" "&"
            firefox --no-remote --new-window "file://localhost${pwd_to_url}/${args_to_url}" &
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

columns() {
  if [[ $# -gt 0 ]]; then
    pr -t -T -"$1"
  else
    pr -t -T
  fi
}

npm_packages() {
  # list npm packages without semver
  # should be a better way to do this
  npm "$@" ls --depth=0 | grep -v npm | cut -d' ' -f2 | grep -v /usr | grep -v '^$' | cut -d'@' -f1
}

####################### Project functions ##########################
## code to provide a "project" command, that will CD to a development
## project, and optionally set up the environment appropriately for the
## project
## need to do this as shell functions as we change state of the shell.

# array of the various project directories I have on different systems
# directories for which each child directory is a project
PROJECT_PARENTS=(
  "${HOME}/Devel/typescript"
)

# directories whose descendants with a .git subdirectory are projects
GIT_PARENTS=(
  "${HOME}/Devel"
  "${HOME}/bin"
)

# TODO: restrict array to only directories that actually exist on THIS system

# Generate a list of all projects on this system, write completion script for
# zsh to stdout.
_project_complete() {
	local -a WORDS
	# "fixed" projects with special handlong
	WORDS=(completion)
	# python virtual environments
	# TODO: figure out how to filter out pipenv environments
	# associated with a project directory
#	for WORD in $(workon)
#	do
#		WORDS[${#WORDS[*]}]="${WORD}"
#	done
	for DIR in ${PROJECT_PARENTS[*]}
	do
		for FNAME in "${DIR}"/*
		do
			if [[ -d "${FNAME}" ]]; then
				WORDS[${#WORDS[*]}]="$(basename "${FNAME}")"
			fi
		done
	done

  for DIR in ${GIT_PARENTS[*]}
  do
    for PROJECT in $(get_project_names_from_git "${DIR}")
    do
			WORDS[${#WORDS[*]}]="${PROJECT}"
    done
  done

	echo "${WORDS[*]}"
}

# given a directory, list all its descendants with a .git subdirectory
get_project_names_from_git() {
  local root_dir="$1"
  if [[ $# != 1 ]]; then
    echo "${FUNCNAME[0]}" requires one argument -- the parent directory
    return 1
  fi
  for REPO in $(find "${root_dir}" -name node_modules -prune -o -type d -name .git -print)
  do
    basename "$(dirname "$REPO")"
  done
}

# given a root directory and a project name, print a directory which is named
# the same as the project and which has a .git subdirectory
# note: it's a problem if two directories in the tree have the same name
find_git_project() {
  if [[ $# -ne 2 ]]; then
    echo "${FUNCNAME[0]} requires 2 arguments" >&2
    return 1
  fi
  local root_dir="$1"
  local proj_name="$2"
  for REPO in $(find "${root_dir}" -name node_modules -prune -o -type d -name .git -print)
  do
    if [[ $(basename "$(dirname "${REPO}")") == "${proj_name}" ]]; then
      dirname "${REPO}"
      return
    fi
  done
}

# given a project name, find the git project of that name, print its directory
find_all_git_project() {
	local proj_name="$1"
	local proj_dir
	for DIR in ${GIT_PARENTS[*]}
	do
		proj_dir=$(find_git_project "${DIR}" "${proj_name}")
		if [[ -n "${proj_dir}" ]]; then
			echo "${proj_dir}"
			return
		fi
	done
}

# Writes to stdout one of:
# workon -- matched a workon (py virtual environemtn) name
# workon replaced by pyenv on this system?
# directory -- matched existing directory
# nothing -- could not find directory
_project_find_dir() {
	# search project parent directories, one at a time
	for DIR in ${PROJECT_PARENTS[*]}
	do
		if [[ -d "${DIR}/$1" ]]; then
			echo "${DIR}/$1"
			return
		fi
	done
}

# project
# master command to switch current directory to project directory
# can be customized per directory with additional setup
# TODO: look for .project file in target directory, use settings
project() {
  local target_dir
  local basedir

  if [[ "$1" == "help" || -z "$1" ]]; then
    cat <<-USAGE
	Usage: ${TERM_BOLD_ON}${FUNCNAME[0]}${TERM_BOLD_OFF} ${TERM_ITAL_ON}project_name${TERM_ITAL_OFF}
	       Quick jump to the project's root directory.
	       ${TERM_BOLD_ON}${FUNCNAME[0]}${TERM_BOLD_OFF} completion
	       Output commands to create zsh completions for ${FUNCNAME[0]} (not [yet] implemented).
USAGE
    return
  fi

  if [[ "$1" == "completion" ]]; then
    # generate zsh completion commands
     _project_complete
    return
  fi

  target_dir=$(_project_find_dir "$@")

  if [[ -z "${target_dir}" ]]; then
    target_dir=$(find_all_git_project "$@")
  fi

  # if we are in virtual environment, deactivate it
  [[ -n ${VIRTUAL_ENV} ]] && pyenv deactivate

  if [[ -z "${target_dir}" ]]; then
    echo "I can't find project $1, sorry!"
    unset PROJECT
    return 1
  else
    # in PHP Composer project dir??
    if [[ -f "${target_dir}/composer.json" && -d "${target_dir}/vendor/bin" ]]; then
      pathmunge "${target_dir}/vendor/bin"
    fi
    # Node project?
    if [[ -d "${target_dir}/node_modules/.bin" ]]; then
      pathmunge "${target_dir}/node_modules/.bin"
    fi
    # Rails project, probably others
    if [[ -d "${target_dir}/bin" ]]; then
      pathmunge "${target_dir}/bin" before
    fi
    export PROJECT=$1
    # Problem with all the above: PATH changes don't go away.
    # Have never had that be an issue in practice
    cd "${target_dir}" || return 1
  fi

  basedir=$(basename "$target_dir")
  pyenv virtualenvs --bare | grep -q "${basedir}" && pyenv activate "${basedir}"
  [[ -f "${target_dir}"/.nvmrc ]] && nvm use

}  # project()

studio() {
  local studio_log=~/log/android_studio.log
  local fix_file=~/AndroidStudioProjects/android-studio.fix
  # override global KOTLIN_HOME so studio uses its own version
  # OK, so far no attempt has fixed incompatibility between Android Studio and command-line
  # kotlin installed by sdk. Sigh.
  # export KOTLIN_HOME="${HOME}/opt/android-studio/plugins/Kotlin/kotlinc"

  if [[ -f "${fix_file}" ]]; then
    STUDIO_VM_OPTIONS="${fix_file}" studio.sh > "${studio_log}" 2>&1 &
  else
    studio.sh > "${studio_log}" 2>&1 &
  fi
}

trash-size() {
  du -sh ~/.local/share/Trash
}

with_commas () {
    if [[ $# -lt 1 ]]; then
        >&2 echo "One argument required: an integer. Prints the integer formatted with locale-dependent thousands separators."
        return 1
    fi
    python3 -c "print('{:,}'.format($1), end='')"
}

avd() {
#    ~/Android/Sdk/emulator/emulator @Nexus_5X_API_27_Play_ > ~/log/avd.log 2>&1 &
#    ~/Android/Sdk/emulator/emulator @Nexus_One_API_26_Intel_ > ~/log/avd.log 2>&1 &
    ~/Android/Sdk/emulator/emulator @testAVD > ~/log/avd.log 2>&1 &
}

kts() {
    exec kotlinc -script "$@"
}

# from the following stack exhange answer, including nice discussion of edge cases this is
# designed to handle
# https://unix.stackexchange.com/a/9124/24158
mkcd () {
  # shellcheck disable=SC2164
  case "$1" in
    */..|*/../) cd -- "$1";; # that doesn't make any sense unless the directory already exists
    /*/../*) (cd "${1%/../*}/.." && mkdir -p "./${1##*/../}") && cd -- "$1";;
    /*) mkdir -p "$1" && cd "$1";;
    */../*) (cd "./${1%/../*}/.." && mkdir -p "./${1##*/../}") && cd "./$1";;
    ../*) (cd .. && mkdir -p "${1#.}") && cd "$1";;
    *) mkdir -p "./$1" && cd "./$1";;
  esac
}

sdl-web () {
    project sdl-web
    pyenv activate livio
    nvm use
    docker-compose up -d
    honcho start
}

maketasks () {
  grep -e '^[a-zA-Z].\+:' Makefile | grep -v ':='
}

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# End:
