#!/usr/bin/env bash

info() {
  printf "${INFO_COLOR}%s${RESTORE}\n" "$1"
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

error() {
  printf "${ERROR_COLOR}ERROR: %s${RESTORE}\n" "$1"
}

fail() {
  error "$@"
  exit 1
}

print_experiment_info() {
  local fmt="%-20s%-10s"

  info
  infof "$fmt" "Experiment:" "${EXP_NO}-${EXP_NAME}"
  infof "$fmt" "Experiment id:" "${EXP_SCAN_TAG}"
  infof "$fmt" "Experiment run id:" "${RUN_ID}"
}

print_warnings() {
  local warnings_file="${EXPERIMENT_DIR}/${project_name}/warnings.txt"
  while read l; do
    echo
    printf "${YELLOW}${BOLD}WARNING: %s${RESTORE}\n" "$l"
  done <"$warnings_file"
}
