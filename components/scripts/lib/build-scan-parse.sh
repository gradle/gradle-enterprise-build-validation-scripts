#!/usr/bin/env bash

# Arrays used by callers to access the fetched build scan data
project_names=()
base_urls=()
build_scan_urls=()
build_scan_ids=()
git_repos=()
git_branches=()
git_commit_ids=()
requested_tasks=()
build_outcomes=()
remote_build_cache_urls=()
remote_build_cache_shards=()

# Build caching performance metrics
avoided_up_to_date_num_tasks=()
avoided_up_to_date_avoidance_savings=()
avoided_from_cache_num_tasks=()
avoided_from_cache_avoidance_savings=()
executed_cacheable_num_tasks=()
executed_cacheable_duration=()
executed_not_cacheable_num_tasks=()
executed_not_cacheable_duration=()

# Build time metrics
initial_build_time=""
instant_savings=""
instant_savings_build_time=""
pending_savings=""
pending_savings_build_time=""

# Other build metrics
serialization_factors=()

parse_single_build_scan() {
  local build_scan_data="$1"

  local build_scan_rows
  IFS=$'\n' read -rd '' -a build_scan_rows <<< "$build_scan_data"

  parse_build_scan_row all_data "${build_scan_rows[1]}"
}

parse_build_scans_and_build_time_metrics() {
  local build_cache_metrics_only="$1"
  local build_scan_data="$2"

  local build_scan_rows
  IFS=$'\n' read -rd '' -a build_scan_rows <<< "$build_scan_data"

  parse_build_scan_row "${build_cache_metrics_only}" "${build_scan_rows[1]}"
  parse_build_scan_row "${build_cache_metrics_only}" "${build_scan_rows[2]}"

  parse_build_time_metrics "${build_scan_rows[4]}"
}

# shellcheck disable=SC2034 # not all scripts use all of the fetched data
parse_build_scan_row() {
  local build_cache_metrics_only="$1"
  local build_scan_row="$2"

  local run_num

  while IFS=, read -r run_num field_1 field_2 field_3 field_4 field_5 field_6 field_7 field_8 field_9 field_10 field_11 field_12 field_13 field_14 field_15 field_16 field_17 field_18 field_19 field_20 field_21; do
    debug "Build Scan $field_4 is for build $run_num"
    project_names[run_num]="$field_1"
    build_scan_ids[run_num]="$field_4"

    if [[ "$build_cache_metrics_only" != "build_cache_metrics_only" ]]; then
      base_urls[run_num]="$field_2"
      build_scan_urls[run_num]="$field_3"
      git_repos[run_num]="$field_5"
      git_branches[run_num]="$field_6"
      git_commit_ids[run_num]="$field_7"
      requested_tasks[run_num]="$(remove_clean_task "${field_8}")"
      build_outcomes[run_num]="$field_9"
      remote_build_cache_urls[run_num]="${field_10}"
      remote_build_cache_shards[run_num]="${field_11}"
    fi

    # Build caching performance metrics
    avoided_up_to_date_num_tasks[run_num]="${field_12}"
    avoided_up_to_date_avoidance_savings[run_num]="${field_13}"
    avoided_from_cache_num_tasks[run_num]="${field_14}"
    avoided_from_cache_avoidance_savings[run_num]="${field_15}"
    executed_cacheable_num_tasks[run_num]="${field_16}"
    executed_cacheable_duration[run_num]="${field_17}"
    executed_not_cacheable_num_tasks[run_num]="${field_18}"
    executed_not_cacheable_duration[run_num]="${field_19}"

    # Other build metrics
    serialization_factors[run_num]="${field_21}"
  done <<< "${build_scan_row}"
}

# shellcheck disable=SC2034 # not all scripts use all of the fetched data
parse_build_time_metrics() {
  local build_time_metrics_row="$1"

  while IFS=, read -r field_1 field_2 field_3 field_4 field_5; do
    initial_build_time="$field_1"
    instant_savings="$field_2"
    instant_savings_build_time="$field_3"
    pending_savings="$field_4"
    pending_savings_build_time="$field_5"
  done <<< "${build_time_metrics_row}"
}
