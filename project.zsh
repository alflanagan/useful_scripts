#!/usr/bin/env zsh
# -*- coding: utf-8-unix -*-
#above more for documentation, since normally this file must be sourced

#put some useful terminal escapes in shell variables
[ -z "$TERM_BOLD_ON" ] || TERM_BOLD_ON=$(tput -T xterm smso)
[ -z "$TERM_BOLD_OFF" ] || TERM_BOLD_OFF=$(tput -T xterm rmso)
[ -z "$TERM_ITAL_ON" ] || TERM_ITAL_ON=$(tput -T xterm sitm)
[ -z "$TERM_ITAL_OFF" ] || TERM_ITAL_OFF=$(tput -T xterm ritm)
[ -z "$TERM_UL_ON" ] || TERM_UL_ON=$(tput -T xterm smul)
[ -z "$TERM_UL_OFF" ] || TERM_UL_OFF=$(tput -T xterm rmul)

####################### Project functions ##########################
## code to provide a "project" command, that will CD to a development
## project, and optionally set up the environment appropriately for the
## project.

# array of the various project directories I have on different systems
# directories for which each child directory is a project
PROJECT_PARENTS=(
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
	# TODO: figure out how to filter out pipenv environments associated with a
    #       project directory
	for DIR in "${PROJECT_PARENTS[@]}"
	do
		for FNAME in "${DIR}"/*
		do
			if [[ -d "${FNAME}" ]]; then
				WORDS[${#WORDS[*]}]="$(basename "${FNAME}")"
			fi
		done
	done

    for DIR in "${GIT_PARENTS[@]}"
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
	for DIR in "${GIT_PARENTS[@]}"
	do
		proj_dir=$(find_git_project "${DIR}" "${proj_name}")
		if [[ -n "${proj_dir}" ]]; then
			echo "${proj_dir}"
			return
		fi
	done
}

# Writes to stdout one of:
# directory -- matched existing directory
# nothing -- could not find directory
_project_find_dir() {
	# search project parent directories, one at a time
	for DIR in "${PROJECT_PARENTS[@]}"
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

    # basedir=$(basename "$target_dir")
    # pyenv virtualenvs activated automatically by .python-version file
    # pyenv virtualenvs --bare | grep -q "${basedir}" && pyenv virtualenv activate "${basedir}"
    [[ -f "${target_dir}"/.nvmrc ]] && nvm use

}  # project()

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# End:
