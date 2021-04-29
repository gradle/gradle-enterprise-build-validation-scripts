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
      echo
      printf "${YELLOW}${BOLD}WARNING: %s${RESTORE}\n" "$l"
    done <"${warnings_file}"
    echo
  fi
}

print_experiment_info() {
 local branch
 branch=$(git_get_branch)

 local fmt="%-26s%s"
 info "Summary"
 info "-------"
 infof "$fmt" "Project:" "${project_name}"
 infof "$fmt" "Git repo:" "${git_repo}"
 infof "$fmt" "Git branch:" "${branch}"
 if [ -z "${project_dir}" ]; then
   infof "$fmt" "Project dir:" "/"
 else
   infof "$fmt" "Project dir:" "${project_dir}"
 fi
 if [[ "${BUILD_TOOL}" == "Maven" ]]; then
   infof "$fmt" "Maven goals:" "${tasks}"
   infof "$fmt" "Maven arguments:" "${extra_args}"
 else
   infof "$fmt" "Gradle tasks:" "${tasks}"
   infof "$fmt" "Gradle arguments:" "${extra_args}"
 fi
 infof "$fmt" "Experiment:" "${EXP_NO}-${EXP_NAME}"
 infof "$fmt" "Experiment id:" "${EXP_SCAN_TAG}"
 infof "$fmt" "Experiment run id:" "${RUN_ID}"
 infof "$fmt" "Experiment artifact dir:" "${EXP_DIR}"
}
