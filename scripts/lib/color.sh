#!/usr/bin/env bash
#shellcheck disable=SC2034 # These variables are very often unused but that's okay because they are constants for colorizing text

# Color and text escape sequences
RESTORE=$(echo -en '\033[0m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
CYAN=$(echo -en '\033[00;36m')
LIGHTGRAY=$(echo -en '\033[00;37m')
WHITE=$(echo -en '\033[01;37m')
RED=$(echo -en '\033[00;31m')
ORANGE=$(echo -en '\033[38;5;202m')

BOLD=$(echo -en '\033[1m')
DIM=$(echo -en '\033[2m')

WIZ_COLOR=""
BOX_COLOR=""
USER_ACTION_COLOR="${WHITE}"
INFO_COLOR="${YELLOW}${BOLD}"
WARN_COLOR="${ORANGE}${BOLD}"
ERROR_COLOR="${RED}${BOLD}"
HEADER_COLOR="${WHITE}${BOLD}"
DEBUG_COLOR="${DIM}"

readonly RESTORE YELLOW BLUE CYAN LIGHTGRAY WHITE RED ORANGE BOLD DIM
readonly WIZ_COLOR BOX_COLOR USER_ACTION_COLOR INFO_COLOR WARN_COLOR ERROR_COLOR HEADER_COLOR DEBUG_COLOR
