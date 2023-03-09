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

# Build duration metrics
build_times=()
serialization_factors=()

parse_build_scan_csv() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases

  local header_row_read run_num
  local build_scan_csv="$1"
  local build_cache_metrics_only="$2"

  debug "Raw build scan data"
  debug "---------------------------"
  debug "${build_scan_csv}"
  debug ""

  header_row_read=false

  # shellcheck disable=SC2034 # not all scripts use all of the fetched data
  while IFS=, read -r run_num field_1 field_2 field_3 field_4 field_5 field_6 field_7 field_8 field_9 field_10 field_11 field_12 field_13 field_14 field_15 field_16 field_17 field_18 field_19 field_20 field_21; do
    if [[ "$header_row_read" == "false" ]]; then
      header_row_read=true
      continue;
    fi

    debug "Build Scan $field_4 is for build $run_num"
    project_names[run_num]="$field_1"

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

    # Build time metrics
    build_times[run_num]="${field_20}"
    serialization_factors[run_num]="${field_21}"

    done <<< "${build_scan_csv}"
}

parse_build_scan_url() {
  # From https://stackoverflow.com/a/63993578/106189
  # See also https://stackoverflow.com/a/45977232/106189
  readonly URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?((/|$)([^?#]*))(\?([^#]*))?(#(.*))?$'
  #                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑↑    ↑        ↑  ↑        ↑ ↑
  #                    ||            |  |||            |         | |            ||    |        |  |        | |
  #                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       ||    12 rpath |  14 query | 16 fragment
  #                    1 scheme:     |  |5 userinfo@             8 :...         ||             13 ?...     15 #...
  #                                  |  4 authority                             |11 / or end-of-string
  #                                  3  //...                                   10 path

  local build_scan_url run_num protocol ge_host port build_scan_id
  build_scan_url="$1"
  run_num="$2"

  if [[ "${build_scan_url}" =~ $URI_REGEX ]]; then
    protocol="${BASH_REMATCH[2]}"
    ge_host="${BASH_REMATCH[7]}"
    port="${BASH_REMATCH[8]}"
    build_scan_id="$(basename "${BASH_REMATCH[10]}")"

    base_urls[run_num]="${protocol}://${ge_host}${port}"
    build_scan_ids[run_num]="$build_scan_id"
  else
    die "${build_scan_url} is not a parsable URL." "${INVALID_INPUT}"
  fi
}
