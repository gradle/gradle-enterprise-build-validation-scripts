#!/usr/bin/env bash

SUCCESS=0
INVALID_INPUT=1
UNEXPECTED_ERROR=2
BUILD_FAILED=3

readonly SUCCESS INVALID_INPUT UNEXPECTED_ERROR BUILD_FAILED

# Overrides the die() function loaded from the argbash-generated parsing libs
die() {
  local _ret="${2:-${UNEXPECTED_ERROR}}"
  printf "${ERROR_COLOR}%s${RESTORE}\n" "$1"
  echo
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

exit_with_return_code() {
  if [[ " ${build_outcomes[*]} " =~ " FAILED " ]]; then
    exit "${BUILD_FAILED}"
  fi

  exit "${SUCCESS}"
}
