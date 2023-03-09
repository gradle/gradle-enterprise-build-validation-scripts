#!/usr/bin/env bash

info() {
  echo "${INFO_COLOR}$*${RESTORE}"
}

infof() {
  local format_string="$1"
  shift
  # the format string is constructed from the caller's input. There is no
  # good way to rewrite this that will not trigger SC2059, so outright
  # disable it here.
  # shellcheck disable=SC2059
  printf "${INFO_COLOR}${format_string}${RESTORE}\n" "$@"
}

warn() {
  echo "${WARN_COLOR}WARNING: $*${RESTORE}"
}

debug() {
  if [[ "${debug_mode}" == "on" ]]; then
    echo "${DEBUG_COLOR}$*${RESTORE}"
  fi
}
