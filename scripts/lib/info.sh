#!/usr/bin/env bash

readonly SUMMARY_FMT="%-27s%s"

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

summary_row() {
    infof "${SUMMARY_FMT}" "$1" "$2"
}

print_bl() {
  if [[ "$_arg_debug" == "on" ]]; then
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  else
    echo
  fi
}

# Overrides the die() function loaded from the argbash-generated parsing libs
die() {
  local _ret="${2:-1}"
  printf "${ERROR_COLOR}%s${RESTORE}\n" "$1"
  echo
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

print_warnings() {
  local warnings_file="${EXP_DIR}/warnings.txt"
  if [ -f "${warnings_file}" ]; then
    while read -r l; do
      print_bl
      printf "${YELLOW}${BOLD}WARNING: %s${RESTORE}\n" "$l"
    done <"${warnings_file}"
  fi
}

print_experiment_info() {
 local branch
 branch=$(git_get_branch)

 info "Summary"
 info "-------"
 summary_row "Project:" "${project_name}"
 summary_row "Git repo:" "${git_repo}"
 summary_row "Git branch:" "${branch}"
 if [ -z "${project_dir}" ]; then
   summary_row "Project dir:" "."
 else
   summary_row "Project dir:" "${project_dir}"
 fi
 if [[ "${BUILD_TOOL}" == "Maven" ]]; then
   summary_row "Maven goals:" "${tasks}"
   summary_row "Maven arguments:" "${extra_args}"
 else
   summary_row "Gradle tasks:" "${tasks}"
   summary_row "Gradle arguments:" "${extra_args}"
 fi
 summary_row "Experiment:" "${EXP_NO} ${EXP_NAME}"
 summary_row "Experiment id:" "${EXP_SCAN_TAG}"
 summary_row "Experiment run id:" "${RUN_ID}"
 summary_row "Experiment artifact dir:" "${EXP_DIR}"
}
