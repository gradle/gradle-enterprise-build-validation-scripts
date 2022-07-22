#!/usr/bin/env bash

readonly SUMMARY_FMT="%-30s%s"
readonly ORDINALS=( first second third fourth fifth sixth seventh eighth ninth tenth )

warnings=()

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
  if [[ "$_arg_debug" == "on" ]]; then
    echo "${DEBUG_COLOR}$*${RESTORE}"
  fi
}

summary_row() {
    infof "${SUMMARY_FMT}" "$1" "${2:-${WARN_COLOR}<unknown>${RESTORE}}"
}

comparison_summary_row() {
  local header value
  header="$1"
  shift;

  if [[ "$1" == "$2" ]]; then
    value="$1"
  else
    value="${WARN_COLOR}${1:-<unknown>} | ${2:-<unknown>}${RESTORE}"
  fi

  summary_row "${header}" "${value}"
}

print_bl() {
  if [[ "$_arg_debug" == "on" ]]; then
    debug "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  else
    echo
  fi
}

# Strips color codes from Standard in. This function is intended to be used as a filter on another command:
# print_summary | strip_color_codes
strip_color_codes() {
  # shellcheck disable=SC2001  # I could only get this to work with sed
  sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g'
}

# Overrides the die() function loaded from the argbash-generated parsing libs
die() {
  local _ret="${2:-1}"
  printf "${ERROR_COLOR}%s${RESTORE}\n" "$1"
  echo
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

read_build_warnings() {
  if [[ "${build_outcomes[0]}" == "FAILED" ]]; then
    warnings+=("The first build failed. This may skew the outcome of the experiment.")
  fi
  if [[ "${build_outcomes[1]}" == "FAILED" ]]; then
    warnings+=("The second build failed. This may skew the outcome of the experiment.")
  fi

  local warnings_file="${EXP_DIR}/warnings.txt"
  if [ -f "${warnings_file}" ]; then
    while read -r l; do
      warnings+=("$l")
    done <"${warnings_file}"
  fi
}

print_warnings() {
  read_build_warnings
  if [[ ${#warnings[@]} -gt 0 ]]; then
    print_bl
    for (( i=0; i<${#warnings[@]}; i++ )); do
      warn "${warnings[i]}"
    done
  fi
}

print_summary() {
  #defined in build_scan.sh
  read_build_scan_metadata
  #defined in build_scan.sh
  detect_warnings_from_build_scans

  info "Summary"
  info "-------"
  print_experiment_info
  print_experiment_specific_summary_info
  print_build_scans
  print_warnings
  print_performance_metrics
  print_bl
  print_quick_links
}

print_experiment_info() {
  comparison_summary_row "Project:" "${project_names[@]}"
  comparison_summary_row "Git repo:" "${git_repos[@]}"
  comparison_summary_row "Git branch:" "${git_branches[@]}"
  comparison_summary_row "Git commit id:" "${git_commit_ids[@]}"
  summary_row "Project dir:" "${project_dir:-<root directory>}"
  comparison_summary_row "${BUILD_TOOL} ${BUILD_TOOL_TASK}s:" "${requested_tasks[@]}"
  summary_row "${BUILD_TOOL} arguments:" "${extra_args:-<none>}"
  summary_row "Experiment:" "${EXP_NO} ${EXP_NAME}"
  summary_row "Experiment id:" "${EXP_SCAN_TAG}"
  if [[ "${SHOW_RUN_ID}" == "true" ]]; then
    summary_row "Experiment run id:" "${RUN_ID}"
  fi
  summary_row "Experiment artifact dir:" "$(relative_path "${SCRIPT_DIR}" "${EXP_DIR}")"
}

print_experiment_specific_summary_info() {
  # this function is intended to be overridden by experiments as-needed
  # have one command to satisfy shellcheck
  true
}

print_performance_metrics() {
  # this function is intended to be overridden by experiments as-needed
  # have one command to satisfy shellcheck
  true
}

print_build_caching_leverage_metrics() {
  print_bl
  info "Build Caching Leverage"
  info "----------------------"

  local task_count_padding
  task_count_padding=$(max_length "${avoided_from_cache_num_tasks[1]}" "${executed_cacheable_num_tasks[1]}" "${executed_not_cacheable_num_tasks[1]}")

  local value
  value=""
  if [[ "${avoided_from_cache_num_tasks[1]}" ]]; then
    local taskCount
    taskCount="$(printf "%${task_count_padding}s" "${avoided_from_cache_num_tasks[1]}" )"
    value="${taskCount} ${BUILD_TOOL_TASK}s, ${avoided_from_cache_avoidance_savings[1]} total saved execution time"
  fi
  summary_row "Avoided cacheable ${BUILD_TOOL_TASK}s:" "${value}"

  value=""
  if [[ "${executed_cacheable_num_tasks[1]}" ]]; then
    local summary_color
    summary_color=""
    if (( executed_cacheable_num_tasks[1] > 0)); then
      summary_color="${WARN_COLOR}"
    fi

    taskCount="$(printf "%${task_count_padding}s" "${executed_cacheable_num_tasks[1]}" )"
    value="${summary_color}${taskCount} ${BUILD_TOOL_TASK}s, ${executed_cacheable_duration[1]} total execution time${RESTORE}"
  fi
  summary_row "Executed cacheable ${BUILD_TOOL_TASK}s:" "${value}"

  value=""
  if [[ "${executed_not_cacheable_num_tasks[1]}" ]]; then
    taskCount="$(printf "%${task_count_padding}s" "${executed_not_cacheable_num_tasks[1]}" )"
    value="${taskCount} ${BUILD_TOOL_TASK}s, ${executed_not_cacheable_duration[1]} total execution time"
  fi
  summary_row "Executed non-cacheable ${BUILD_TOOL_TASK}s:" "${value}"

  if (( executed_cacheable_num_tasks[1] > 0)); then
    print_bl
    warn "Not all cacheable ${BUILD_TOOL_TASK}s' outputs were taken from the build cache in the second build. This reduces the savings in ${BUILD_TOOL_TASK} execution time."
  fi
}

max_length() {
  local max_len

  max_len=${#1}
  shift

  for x in "${@}"; do
    if (( ${#x} > max_len )); then
      max_len=${#x}
    fi
  done

  echo "${max_len}"
}

warn_if_nonzero() {
  local value
  value=$1
  if (( value > 0 )); then
    echo "${WARN_COLOR}${value}${RESTORE}"
  else
    echo "$value"
  fi
}

print_build_scans() {
  for (( i=0; i<2; i++ )); do
    if [ -z "${build_outcomes[i]}" ]; then
      summary_row "Build scan ${ORDINALS[i]} build:" "${WARN_COLOR}${build_scan_urls[i]:+${build_scan_urls[i]} }BUILD SCAN DATA FETCH FAILED${RESTORE}"
    elif [[ "${build_outcomes[i]}" == "FAILED" ]]; then
      summary_row "Build scan ${ORDINALS[i]} build:" "${WARN_COLOR}${build_scan_urls[i]:+${build_scan_urls[i]} }FAILED${RESTORE}"
    else
      summary_row "Build scan ${ORDINALS[i]} build:" "${build_scan_urls[i]}"
    fi
  done
}

create_receipt_file() {
  {
  print_summary | strip_color_codes
  print_bl
  print_command_to_repeat_experiment | strip_color_codes
  print_bl
  echo "Generated by $(print_version)"
  } > "${RECEIPT_FILE}"
}

exit_with_return_code() {
  if [[ " ${build_outcomes[*]} " =~ " FAILED " ]]; then
    exit 3
  fi

  # shellcheck disable=SC2034 # not all of the scripts have the fail if not optimized CLI argument
  if [ -n "${_arg_fail_if_not_optimized+x}" ]; then
    # If the script has the "fail if not optimized CLI argument", then see if the build is optimized
    local executed_avoidable_tasks
    executed_avoidable_tasks=$(( executed_cacheable_num_tasks[1] ))
    if [[ "${_arg_fail_if_not_optimized}" == "on" ]] && (( executed_avoidable_tasks > 0 )); then
      print_bl
      die "ERROR: Build is not optimized" -2
    fi
  fi

  exit 0
}
