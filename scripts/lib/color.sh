#!/usr/bin/env bash
#shellcheck disable=SC2034 # These variables are very often unused but that's okay because they are constants for colorizing text

# Color and text escape sequences
readonly RESTORE=$(echo -en '\033[0m')
readonly YELLOW=$(echo -en '\033[00;33m')
readonly BLUE=$(echo -en '\033[00;34m')
readonly CYAN=$(echo -en '\033[00;36m')
readonly LIGHTGRAY=$(echo -en '\033[00;37m')
readonly WHITE=$(echo -en '\033[01;37m')
readonly RED=$(echo -en '\033[00;31m')
readonly ORANGE=$(echo -en '\033[38;5;202m')

readonly BOLD=$(echo -en '\033[1m')
readonly DIM=$(echo -en '\033[2m')

readonly WIZ_COLOR=""
readonly BOX_COLOR=""
readonly USER_ACTION_COLOR="${WHITE}"
readonly INFO_COLOR="${YELLOW}${BOLD}"
readonly WARN_COLOR="${ORANGE}"
readonly ERROR_COLOR="${RED}${BOLD}"
readonly HEADER_COLOR="${WHITE}${BOLD}"
readonly DEBUG_COLOR="${DIM}"

