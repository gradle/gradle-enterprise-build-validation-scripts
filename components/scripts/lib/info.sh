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
  if [[ "${debug_mode}" == "on" ]]; then
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
  if [[ "${debug_mode}" == "on" ]]; then
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
  detect_warnings_from_build_scans

  info "Summary"
  info "-------"
  print_experiment_info
  print_experiment_specific_summary_info
  print_build_scans

  print_warnings

  print_performance_characteristics

  if [[ "${build_scan_publishing_mode}" == "on" ]]; then
    print_bl
    print_quick_links
  fi
}

print_experiment_info() {
  comparison_summary_row "Project:" "${project_names[@]}"
  comparison_summary_row "Git repo:" "${git_repos[@]}"
  comparison_summary_row "Git branch:" "${git_branches[@]}"
  comparison_summary_row "Git commit id:" "${git_commit_ids[@]}"
  summary_row "Git options:" "${git_options}"
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

# This function is responsible for printing the "Performance Characteristics"
# section of the experiment summary.
#
# Experiments may override this function to include only relevant metrics.
print_performance_characteristics() {
  print_performance_characteristics_header

  print_realized_build_time_savings

  print_potential_build_time_savings

  print_build_caching_leverage_metrics

  print_serialization_factor

  print_executed_cacheable_tasks_warning
}

print_performance_characteristics_header() {
  print_bl
  info "Performance Characteristics"
  info "---------------------------"
}

# The _realized_ build time savings is the difference in the wall-clock build
# time between the first and second build.
print_realized_build_time_savings() {
  local value
  # Only calculate realized build time savings when these values exist
  # These values can be returned as empty when an error occurs processing the Build Scan data
  if [[ -n "${effective_task_execution_duration[0]}" && -n "${effective_task_execution_duration[1]}" ]]; then
    local realized_build_time_savings=$((effective_task_execution_duration[0]-effective_task_execution_duration[1]))
    printf -v value "%s wall-clock time (from %s to %s)" \
      "$(format_duration "${realized_build_time_savings}")" \
      "$(format_duration "${effective_task_execution_duration[0]}")" \
      "$(format_duration "${effective_task_execution_duration[1]}")"
  fi
  summary_row "Realized build time savings:" "${value}"
}

# The _potential_ build time savings is the difference in wall-clock build time
# between the first build and the _potential_ build time of the second build.
#
# The _potential_ build time is an estimation of the build time if no cacheable
# tasks had been executed.
print_potential_build_time_savings() {
  local value
  # Only calculate realized build time savings when these values exist
  # These values can be returned as empty when an error occurs processing the Build Scan data
  if [[ -n "${effective_task_execution_duration[0]}" && \
        -n "${effective_task_execution_duration[1]}" && \
        -n "${executed_cacheable_duration[1]}" && \
        -n "${serialization_factors[1]}" ]]
  then
    local potential_build_time potential_build_time_savings
    potential_build_time=$(echo "${effective_task_execution_duration[1]}-(${executed_cacheable_duration[1]}/${serialization_factors[1]})" | bc)
    potential_build_time_savings=$((effective_task_execution_duration[0]-potential_build_time))
    printf -v value "%s wall-clock time (from %s to %s)" \
      "$(format_duration "${potential_build_time_savings}")" \
      "$(format_duration "${effective_task_execution_duration[0]}")" \
      "$(format_duration "${potential_build_time}")"
  fi
  summary_row "Potential build time savings:" "${value}"
}

print_build_caching_leverage_metrics() {
  local task_count_padding
  task_count_padding=$(max_length "${avoided_from_cache_num_tasks[1]}" "${executed_cacheable_num_tasks[1]}" "${executed_not_cacheable_num_tasks[1]}")

  print_avoided_cacheable_tasks "${task_count_padding}"

  print_executed_cacheable_tasks "${task_count_padding}"

  print_executed_non_cacheable_tasks "${task_count_padding}"
}

print_avoided_cacheable_tasks() {
  local value
  if [[ -n "${avoided_from_cache_num_tasks[1]}" && -n "${avoided_from_cache_avoidance_savings[1]}" ]]; then
    printf -v value "%$1s %ss, %s total saved execution time" \
      "${avoided_from_cache_num_tasks[1]}" \
      "${BUILD_TOOL_TASK}" \
      "$(format_duration avoided_from_cache_avoidance_savings[1])"
  fi
  summary_row "Avoided cacheable ${BUILD_TOOL_TASK}s:" "${value}"
}

print_executed_cacheable_tasks() {
  local value
  if [[ -n "${executed_cacheable_num_tasks[1]}" && -n "${executed_cacheable_duration[1]}" ]]; then
    local summary_color
    if (( executed_cacheable_num_tasks[1] > 0)); then
      summary_color="${WARN_COLOR}"
    fi

    printf -v value "${summary_color}%$1s %ss, %s total execution time${RESTORE}" \
      "${executed_cacheable_num_tasks[1]}" \
      "${BUILD_TOOL_TASK}" \
      "$(format_duration executed_cacheable_duration[1])"
  fi
  summary_row "Executed cacheable ${BUILD_TOOL_TASK}s:" "${value}"
}

print_executed_non_cacheable_tasks() {
  local value
  if [[ -n "${executed_not_cacheable_num_tasks[1]}" && -n "${executed_not_cacheable_duration[1]}" ]]; then
    printf -v value "%$1s %ss, %s total execution time" \
      "${executed_not_cacheable_num_tasks[1]}" \
      "${BUILD_TOOL_TASK}" \
      "$(format_duration executed_not_cacheable_duration[1])"
  fi
  summary_row "Executed non-cacheable ${BUILD_TOOL_TASK}s:" "${value}"
}

print_serialization_factor() {
  local value
  if [[ -n "${serialization_factors[0]}" ]]; then
    value="$(to_two_decimal_places "${serialization_factors[0]}")x"
  fi
  summary_row "Serialization factor:" "${value}"
}

print_executed_cacheable_tasks_warning() {
  if (( executed_cacheable_num_tasks[1] > 0)); then
    print_bl
    warn "Not all cacheable ${BUILD_TOOL_TASK}s' outputs were taken from the build cache in the second build. This reduces the savings in ${BUILD_TOOL_TASK} execution time."
  fi
}

print_quick_links() {
  if [[ "${BUILD_TOOL}" == "Gradle" ]]; then
    print_gradle_quick_links
  else
    print_maven_quick_links
  fi
}

print_gradle_quick_links() {
  info "Investigation Quick Links"
  info "-------------------------"
  summary_row "Task execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
  summary_row "Executed tasks timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=success,failed&sort=longest"
  summary_row "Avoided cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=from-cache&sort=longest"
  summary_row "Executed cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=cacheable,overlapping-outputs,validation-failure&outcome=success,failed&sort=longest"
  summary_row "Executed non-cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=any-non-cacheable,not:overlapping-outputs,not:validation-failure&outcome=success,failed&sort=longest"
  summary_row "Build caching statistics:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
  summary_row "Task inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/task-inputs?cacheability=cacheable"
}

print_maven_quick_links() {
  info "Investigation Quick Links"
  info "-------------------------"
  summary_row "Goal execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
  summary_row "Executed goals timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=success,failed&sort=longest"
  summary_row "Avoided cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=from-cache&sort=longest"
  summary_row "Executed cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=cacheable&outcome=success,failed&sort=longest"
  summary_row "Executed non-cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=any-non-cacheable&outcome=success,failed&sort=longest"
  summary_row "Build caching statistics:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
  summary_row "Goal inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/goal-inputs?cacheability=cacheable"
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
    if [[ "${build_scan_publishing_mode}" == "on" ]]; then
      if [ -z "${build_outcomes[i]}" ]; then
        summary_row "Build scan ${ORDINALS[i]} build:" "${WARN_COLOR}${build_scan_urls[i]:+${build_scan_urls[i]} }BUILD SCAN DATA FETCH FAILED${RESTORE}"
      elif [[ "${build_outcomes[i]}" == "FAILED" ]]; then
        summary_row "Build scan ${ORDINALS[i]} build:" "${WARN_COLOR}${build_scan_urls[i]:+${build_scan_urls[i]} }FAILED${RESTORE}"
      else
        summary_row "Build scan ${ORDINALS[i]} build:" "${build_scan_urls[i]}"
      fi
    else
      summary_row "Build scan ${ORDINALS[i]} build:" "<publication disabled>"
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

format_duration() {
  local duration=$1
  local hours=$((duration/60/60/1000))
  local minutes=$((duration/60/1000%60))
  local seconds=$((duration/1000%60%60))
  local millis=$((duration%1000))

  if [[ "${hours}" != 0 ]]; then
    printf "%dh " "${hours}"
  fi

  if [[ "${minutes}" != 0 ]]; then
    printf "%dm " "${minutes}"
  fi

  printf "%d.%03ds" "${seconds}" "${millis}"
}

# Rounds the argument to two decimal places
# See: https://unix.stackexchange.com/a/167059
to_two_decimal_places() {
  LC_ALL=C printf "%.2f" "$1"
}
