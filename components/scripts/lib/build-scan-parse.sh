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
# shellcheck disable=SC2034 # not all scripts use this data
remote_build_cache_urls=()
# shellcheck disable=SC2034 # not all scripts use this data
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

parse_build_scan_csv() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases

  local header_row_read idx
  local build_scan_csv="$1"
  local build_cache_metrics_only="$2"

  debug "Raw build scan data"
  debug "---------------------------"
  debug "${build_scan_csv}"
  debug ""

  header_row_read=false
  idx=0

  # shellcheck disable=SC2034 # not all scripts use all of the fetched data
  while IFS=, read -r field_1 field_2 field_3 field_4 field_5 field_6 field_7 field_8 field_9 field_10 field_11 field_12 field_13 field_14 field_15 field_16 field_17 field_18 field_19; do
     if [[ "$header_row_read" == "false" ]]; then
         header_row_read=true
         continue;
     fi

  if [[ "$build_cache_metrics_only" != "build_cache_metrics_only" ]]; then
       project_names[idx]="$field_1"
       base_urls[idx]="$field_2"
       build_scan_urls[idx]="$field_3"
       build_scan_ids[idx]="$field_4"
       git_repos[idx]="$field_5"
       git_branches[idx]="$field_6"
       git_commit_ids[idx]="$field_7"
       requested_tasks[idx]="$(remove_clean_task "${field_8}")"
       build_outcomes[idx]="$field_9"
       remote_build_cache_urls[idx]="${field_10}"
       remote_build_cache_shards[idx]="${field_11}"
     fi

     # Build caching performance metrics
     avoided_up_to_date_num_tasks[idx]="${field_12}"
     avoided_up_to_date_avoidance_savings[idx]="${field_13}"
     avoided_from_cache_num_tasks[idx]="${field_14}"
     avoided_from_cache_avoidance_savings[idx]="${field_15}"
     executed_cacheable_num_tasks[idx]="${field_16}"
     executed_cacheable_duration[idx]="${field_17}"
     executed_not_cacheable_num_tasks[idx]="${field_18}"
     executed_not_cacheable_duration[idx]="${field_19}"

     ((idx++))
  done <<< "${build_scan_csv}"
}
