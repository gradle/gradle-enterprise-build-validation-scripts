#!/usr/bin/env bash

# Color and text escape sequences
RESTORE=$(echo -en '\033[0m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
CYAN=$(echo -en '\033[00;36m')
WHITE=$(echo -en '\033[01;37m')

BOLD=$(echo -en '\033[1m')

WIZ_COLOR="${BLUE}${BOLD}"
BOX_COLOR="${CYAN}"
USER_ACTION_COLOR="${WHITE}"
INFO_COLOR="${YELLOW}${BOLD}"

